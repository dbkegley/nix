{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.arch.packageManager;

  # Generate the package manifest
  packageManifest = pkgs.writeText "arch-packages-manifest.json" (
    builtins.toJSON {
      version = 1;
      packages = cfg.packages;
      enableAUR = cfg.enableAUR;
      enableRemoval = cfg.enableRemoval;
    }
  );

  # State file location - persists across activations
  stateFile = "/var/lib/arch-package-manager/state.json";

  # Lock file to prevent concurrent executions
  lockFile = "/var/lock/arch-package-manager.lock";

  # Pre-activation script that runs as assertion
  preActivationScript = pkgs.writeShellScript "arch-packages-pre-activation" ''
    set -euo pipefail

    # Check for dry-run mode (from config option)
    DRY_RUN="${if cfg.dryRun then "1" else "0"}"

    # Ensure we're running as root (unless in dry-run)
    if [ "$DRY_RUN" = "0" ] && [ "$EUID" -ne 0 ]; then
      echo "ERROR: This script must be run as root"
      exit 1
    fi

    # Logging functions
    log() {
      echo "[arch-package-manager] $*" >&2
      if [ "$DRY_RUN" = "0" ]; then
        logger -t arch-package-manager "$*" 2>/dev/null || true
      fi
    }

    error() {
      echo "[arch-package-manager] ERROR: $*" >&2
      if [ "$DRY_RUN" = "0" ]; then
        logger -t arch-package-manager "ERROR: $*" 2>/dev/null || true
      fi
      exit 1
    }

    warn() {
      echo "[arch-package-manager] WARNING: $*" >&2
      if [ "$DRY_RUN" = "0" ]; then
        logger -t arch-package-manager "WARNING: $*" 2>/dev/null || true
      fi
    }

    # Acquire lock to prevent concurrent runs (skip in dry-run)
    if [ "$DRY_RUN" = "0" ]; then
      exec 200>${lockFile}
      if ! flock -n 200; then
        error "Another instance is already running"
      fi
    fi

    if [ "$DRY_RUN" = "1" ]; then
      log "DRY RUN MODE - No packages will be installed or removed"
    fi

    log "Starting pre-activation package reconciliation..."

    # Check if we're on Arch Linux
    if [ -f /etc/os-release ]; then
      source /etc/os-release
      if [[ "$ID" != "arch" ]] && [[ "$ID_LIKE" != *"arch"* ]]; then
        error "This module requires Arch Linux (found: $ID)"
      fi
    else
      error "Cannot determine distribution"
    fi

    # Check for pacman
    if ! command -v pacman &> /dev/null; then
      error "pacman not found"
    fi

    # Check for yay if AUR is enabled
    if [ "${if cfg.enableAUR then "true" else "false"}" = "true" ]; then
      if ! command -v yay &> /dev/null; then
        error "yay not found but enableAUR is true. Install yay first: https://github.com/Jguer/yay"
      fi
    fi

    # Ensure state directory exists
    STATE_DIR="$(dirname ${stateFile})"
    mkdir -p "$STATE_DIR"

    # Load previous state
    if [ -f "${stateFile}" ]; then
      OLD_STATE=$(cat "${stateFile}")
      log "Loaded previous state from ${stateFile}"
    else
      OLD_STATE='{"version":1,"packages":[]}'
      log "No previous state found, starting fresh"
    fi

    # Load new desired state
    NEW_STATE=$(cat ${packageManifest})

    # Parse package lists
    OLD_PACKAGES=$(echo "$OLD_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    NEW_PACKAGES=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    ABSENT_PACKAGES=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "absent") | .name' | sort -u || true)

    # Calculate changes
    TO_INSTALL=$(comm -13 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES") || true)
    TO_REMOVE=$(comm -23 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES") || true)

    # Add explicitly absent packages to removal list
    if [ -n "$ABSENT_PACKAGES" ]; then
      TO_REMOVE=$(echo -e "$TO_REMOVE\n$ABSENT_PACKAGES" | sort -u)
    fi

    # Check if any changes are needed
    if [ -z "$TO_INSTALL" ] && [ -z "$TO_REMOVE" ]; then
      log "No package changes needed"
      if [ "$DRY_RUN" = "0" ]; then
        echo "$NEW_STATE" > "${stateFile}"
      fi
      exit 0
    fi

    # Report planned changes
    log "Package changes required:"
    if [ -n "$TO_INSTALL" ]; then
      log "Packages to install:"
      echo "$TO_INSTALL" | while read -r pkg; do
        if [ -n "$pkg" ]; then
          SOURCE=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r ".packages[] | select(.name == \"$pkg\") | .source // \"pacman\"")
          log "  + $pkg (via $SOURCE)"
        fi
      done
    fi

    if [ -n "$TO_REMOVE" ]; then
      if [ "${if cfg.enableRemoval then "true" else "false"}" = "true" ]; then
        log "Packages to remove:"
        echo "$TO_REMOVE" | while read -r pkg; do
          [ -n "$pkg" ] && log "  - $pkg"
        done
      else
        log "Packages marked for removal (enableRemoval is false, skipping):"
        echo "$TO_REMOVE" | while read -r pkg; do
          [ -n "$pkg" ] && log "  - $pkg (skipped)"
        done
      fi
    fi

    # Update package database (skip in dry-run)
    if [ "$DRY_RUN" = "0" ]; then
      log "Updating package database..."
      if ! pacman -Sy --noconfirm; then
        warn "Failed to update package database, continuing anyway..."
      fi
    else
      log "Would update package database (skipped in dry-run)"
    fi

    # Install packages
    INSTALL_FAILED=""
    if [ -n "$TO_INSTALL" ]; then
      if [ "$DRY_RUN" = "0" ]; then
        log "Installing packages..."
      else
        log "Would install packages (dry-run):"
      fi

      echo "$TO_INSTALL" | while read -r pkg; do
        [ -n "$pkg" ] || continue

        SOURCE=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r ".packages[] | select(.name == \"$pkg\") | .source // \"pacman\"")

        if [ "$DRY_RUN" = "1" ]; then
          log "  Would install: $pkg (via $SOURCE)"
          continue
        fi

        case "$SOURCE" in
          pacman)
            log "Installing $pkg via pacman..."
            if pacman -S --needed --noconfirm "$pkg" 2>&1 | tee /tmp/pacman-$$.log | sed 's/^/  /'; then
              log "Successfully installed $pkg"
            else
              INSTALL_FAILED="$INSTALL_FAILED $pkg"
              error "Failed to install $pkg via pacman"
            fi
            ;;

          yay)
            if [ "${if cfg.enableAUR then "true" else "false"}" != "true" ]; then
              warn "Skipping AUR package $pkg (enableAUR is false)"
            else
              log "Installing $pkg via yay..."
              # Run yay as nobody user for AUR builds
              if sudo -u nobody yay -S --needed --noconfirm "$pkg" 2>&1 | tee /tmp/yay-$$.log | sed 's/^/  /'; then
                log "Successfully installed $pkg"
              else
                INSTALL_FAILED="$INSTALL_FAILED $pkg"
                error "Failed to install $pkg via yay"
              fi
            fi
            ;;

          *)
            error "Unknown source '$SOURCE' for package $pkg"
            ;;
        esac
      done
    fi

    # Remove packages
    if [ "${if cfg.enableRemoval then "true" else "false"}" = "true" ] && [ -n "$TO_REMOVE" ]; then
      if [ "$DRY_RUN" = "0" ]; then
        log "Removing packages..."
        echo "$TO_REMOVE" | while read -r pkg; do
          [ -n "$pkg" ] || continue
          log "Removing $pkg..."
          if pacman -Rns --noconfirm "$pkg" 2>&1 | sed 's/^/  /'; then
            log "Successfully removed $pkg"
          else
            warn "Failed to remove $pkg (may have dependents)"
          fi
        done
      else
        log "Would remove packages (dry-run):"
        echo "$TO_REMOVE" | while read -r pkg; do
          [ -n "$pkg" ] && log "  Would remove: $pkg"
        done
      fi
    fi

    # Verify critical packages were installed (skip in dry-run)
    if [ "$DRY_RUN" = "0" ] && [ -n "$INSTALL_FAILED" ]; then
      error "Failed to install critical packages:$INSTALL_FAILED"
    fi

    # Save new state (skip in dry-run)
    if [ "$DRY_RUN" = "0" ]; then
      echo "$NEW_STATE" > "${stateFile}"
      log "State saved to ${stateFile}"

      # Create success marker
      touch /run/arch-package-manager-success
    else
      log "Dry-run complete - no changes made"
    fi

    log "Pre-activation package reconciliation completed successfully"
    exit 0
  '';

in
{
  options.arch.packageManager = {
    enable = lib.mkEnableOption "Arch Linux package management via pacman/yay";

    enableAUR = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable AUR package installation via yay";
    };

    enableRemoval = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable automatic removal of packages no longer declared";
    };

    dryRun = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run in dry-run mode - show what would be installed/removed without making changes";
    };

    continueOnError = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Continue activation even if package installation fails (not recommended)";
    };

    packages = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Package name as known to pacman/yay";
            };

            source = lib.mkOption {
              type = lib.types.enum [
                "pacman"
                "yay"
              ];
              default = "pacman";
              description = "Package source (pacman for official repos, yay for AUR)";
            };

            state = lib.mkOption {
              type = lib.types.enum [
                "present"
                "absent"
              ];
              default = "present";
              description = "Desired package state";
            };
          };
        }
      );
      default = [ ];
      example = [
        { name = "htop"; }
        { name = "docker"; }
        {
          name = "visual-studio-code-bin";
          source = "yay";
        }
      ];
      description = "List of packages to manage";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add pre-activation assertion
    system-manager.preActivationAssertions.archPackageManager = {
      enable = true;
      name = "arch-package-manager";
      script =
        if cfg.continueOnError then
          ''
            # Run package management but don't fail activation
            ${preActivationScript} || {
              echo "WARNING: Package management failed but continuing (continueOnError = true)"
              exit 0
            }
          ''
        else
          ''
            # Run package management and fail activation on error
            ${preActivationScript}
          '';
    };

    # Validation assertions
    assertions = [
      {
        assertion = cfg.enableAUR || !(lib.any (p: p.source == "yay") cfg.packages);
        message = "AUR packages specified but arch.packageManager.enableAUR is false";
      }
      {
        assertion = !(lib.elem "pacman" (map (p: p.name) cfg.packages));
        message = "Cannot manage pacman itself through this module";
      }
      {
        assertion =
          let
            names = map (p: p.name) cfg.packages;
            uniqueNames = lib.unique names;
          in
          (lib.length names) == (lib.length uniqueNames);
        message = "Duplicate package declarations found in arch.packageManager.packages";
      }
    ];

    # Provide helper commands
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "arch-packages-status" ''
        echo "=== Arch Package Manager Status ==="
        echo ""

        if [ -f "${stateFile}" ]; then
          echo "Currently managed packages:"
          ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | "  • \(.name) (\(.source // "pacman"))"' "${stateFile}" | sort

          ABSENT=$(${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "absent") | .name' "${stateFile}" 2>/dev/null)
          if [ -n "$ABSENT" ]; then
            echo ""
            echo "Explicitly removed packages:"
            echo "$ABSENT" | sed 's/^/  • /'
          fi
        else
          echo "No packages currently managed (no state file found)"
        fi

        echo ""
        echo "Configuration:"
        echo "  • AUR enabled: ${if cfg.enableAUR then "yes" else "no"}"
        echo "  • Auto-removal: ${if cfg.enableRemoval then "yes" else "no"}"
        echo "  • Continue on error: ${if cfg.continueOnError then "yes" else "no"}"

        if [ -f /run/arch-package-manager-success ]; then
          echo ""
          echo "Last run: ✓ Success (this boot)"
        fi
      '')

      (pkgs.writeShellScriptBin "arch-packages-check" ''
        echo "=== Checking Arch Package Status ==="
        echo ""

        # Load desired state
        DESIRED=$(cat ${packageManifest})

        # Check each package
        echo "$DESIRED" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | while read -r pkg; do
          if pacman -Q "$pkg" &>/dev/null; then
            echo "  ✓ $pkg is installed"
          else
            echo "  ✗ $pkg is NOT installed"
          fi
        done

        # Check absent packages
        ABSENT=$(echo "$DESIRED" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "absent") | .name')
        if [ -n "$ABSENT" ]; then
          echo ""
          echo "Packages that should be absent:"
          echo "$ABSENT" | while read -r pkg; do
            if pacman -Q "$pkg" &>/dev/null; then
              echo "  ✗ $pkg is still installed"
            else
              echo "  ✓ $pkg is not installed"
            fi
          done
        fi
      '')
    ];
  };
}
