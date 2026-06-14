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

  # TODO: Build each aur package in a separate derivation
  # Currently any aur package change must re-build _all_ aur packages

  # Build all AUR packages in Nix derivation (unprivileged)
  aurPackagesBuilt =
    let
      # TODO: allow other source types, https://, git@?, etc.
      aurPkgs = lib.filter (p: p.source == "aur") cfg.packages;
    in
    if cfg.enableAUR && (lib.length aurPkgs) > 0 then
      pkgs.stdenv.mkDerivation {
        name = "aur-packages-built";

        # Dependencies for building AUR packages
        nativeBuildInputs = with pkgs; [
          git
          pacman
          fakeroot
          binutils
          gcc
          gnumake
          pkg-config
          curl
          gzip
        ];

        # TODO: pre-fetch aur packages so we can disallow network?

        # Make it an impure derivation to allow network access for git clone
        __noChroot = true;

        buildPhase = ''
          mkdir -p $out

          # Build each AUR package in order (respects dependency ordering)
          ${lib.concatMapStrings (pkg: ''
            echo "Building AUR package: ${pkg.name}"

            # Clone AUR repository
            if ! git clone --depth=1 https://aur.archlinux.org/${pkg.name}.git ${pkg.name}; then
              echo "Failed to clone ${pkg.name} from AUR"
              exit 1
            fi

            cd ${pkg.name}

            # Build package with makepkg
            # --nodeps: dependencies handled separately by pacman
            if ! makepkg --nodeps --noconfirm --noprogressbar; then
              echo "Failed to build ${pkg.name}"
              exit 1
            fi

            # Copy built package to output
            cp *.pkg.tar.* $out/ || cp *.pkg.tar $out/ || true
            cd ..
          '') aurPkgs}

          echo "Successfully built ${toString (lib.length aurPkgs)} AUR packages"
        '';

        installPhase = "true"; # buildPhase handles output
      }
    else
      # No AUR packages to build
      pkgs.runCommand "aur-packages-empty" { } "mkdir -p $out";

  # Pre-activation script that runs as assertion
  preActivationScript = pkgs.writeShellScript "arch-packages-pre-activation" ''
    set -euo pipefail

    # Check for dry-run mode (from config option)
    DRY_RUN="${if cfg.dryRun then "1" else "0"}"

    # Ensure we're running as root
    if [ "$EUID" -ne 0 ]; then
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

    # Acquire lock to prevent concurrent runs
    exec 200>${lockFile};
    if ! flock -n 200; then
      error "Another instance is already running"
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

    # Parse package lists - track ALL packages (including AUR) for removal support
    OLD_PACKAGES=$(echo "$OLD_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    NEW_PACKAGES=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    ABSENT_PACKAGES=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select(.state == "absent") | .name' | sort -u || true)

    # Separate lists by source type for targeted operations
    OLD_PACMAN=$(echo "$OLD_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select((.state == "present" or .state == null) and (.source == "pacman" or .source == null)) | .name' | sort -u || true)
    NEW_PACMAN=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select((.state == "present" or .state == null) and (.source == "pacman" or .source == null)) | .name' | sort -u || true)
    OLD_AUR=$(echo "$OLD_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select((.state == "present" or .state == null) and .source == "aur") | .name' | sort -u || true)
    NEW_AUR=$(echo "$NEW_STATE" | ${pkgs.jq}/bin/jq -r '.packages[] | select((.state == "present" or .state == null) and .source == "aur") | .name' | sort -u || true)

    # Calculate changes - only install NEW packages (not in old state)
    TO_INSTALL_PACMAN=$(comm -13 <(echo "$OLD_PACMAN") <(echo "$NEW_PACMAN") || true)
    TO_INSTALL_AUR=$(comm -13 <(echo "$OLD_AUR") <(echo "$NEW_AUR") || true)
    TO_REMOVE=$(comm -23 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES") || true)

    # Add explicitly absent packages to removal list
    if [ -n "$ABSENT_PACKAGES" ]; then
      TO_REMOVE=$(echo -e "$TO_REMOVE\n$ABSENT_PACKAGES" | sort -u)
    fi

    # Check if any changes are needed
    if [ -z "$TO_INSTALL_PACMAN" ] && [ -z "$TO_INSTALL_AUR" ] && [ -z "$TO_REMOVE" ]; then
      log "No package changes needed"
      if [ "$DRY_RUN" = "0" ]; then
        echo "$NEW_STATE" > "${stateFile}"
      fi
      exit 0
    fi

    # Report planned changes
    log "Package changes required:"
    if [ -n "$TO_INSTALL_PACMAN" ]; then
      log "Official packages to install:"
      echo "$TO_INSTALL_PACMAN" | while read -r pkg; do
        [ -n "$pkg" ] && log "  + $pkg (via pacman)"
      done
    fi

    # Report AUR packages to install
    if [ -n "$TO_INSTALL_AUR" ]; then
      log "AUR packages to install (pre-built):"
      echo "$TO_INSTALL_AUR" | while read -r pkg; do
        [ -n "$pkg" ] && log "  + $pkg (via AUR)"
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

    # Install NEW AUR packages (pre-built in Nix store)
    if [ -n "$TO_INSTALL_AUR" ]; then
      AUR_BUILT_DIR="${aurPackagesBuilt}"
      if [ -d "$AUR_BUILT_DIR" ] && [ "$(ls -A $AUR_BUILT_DIR 2>/dev/null)" ]; then
        if [ "$DRY_RUN" = "0" ]; then
          log "Installing NEW AUR packages from Nix store..."
          # Note: We still use --needed as a safety measure
          if ! pacman -U --needed --noconfirm "$AUR_BUILT_DIR"/*.pkg.tar.* 2>&1 | sed 's/^/  /'; then
            error "Failed to install AUR packages"
          fi
          log "Successfully installed AUR packages: $TO_INSTALL_AUR"
        else
          log "Would install AUR packages: $TO_INSTALL_AUR (dry-run)"
        fi
      else
        error "AUR packages to install but build directory is empty: $AUR_BUILT_DIR"
      fi
    fi

    # Install official packages
    if [ -n "$TO_INSTALL_PACMAN" ]; then
      if [ "$DRY_RUN" = "0" ]; then
        log "Installing official packages..."
        echo "$TO_INSTALL_PACMAN" | while read -r pkg; do
          [ -n "$pkg" ] || continue
          log "Installing $pkg via pacman..."
          if ! pacman -S --needed --noconfirm "$pkg" 2>&1 | tee /tmp/pacman-$$.log | sed 's/^/  /'; then
            error "Failed to install $pkg via pacman"
          fi
          log "Successfully installed $pkg"
        done
      else
        log "Would install official packages (dry-run):"
        echo "$TO_INSTALL_PACMAN" | while read -r pkg; do
          [ -n "$pkg" ] && log "  Would install: $pkg"
        done
      fi
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
    enable = lib.mkEnableOption "Arch Linux package management via pacman/makepkg";

    # todo: Add a remove orphans option for cleaning up unused dependencies
    # https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Removing_unused_packages_(orphans)
    #
    # todo: Add an option that re-installs all packages tracked in the state file

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
                "aur"
              ];
              default = "pacman";
              description = "Package source ('pacman' for official repos, or 'aur' for AUR)";
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
          source = "aur";
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
        assertion = cfg.enableAUR || !(lib.any (p: p.source == "aur") cfg.packages);
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
  };
}
