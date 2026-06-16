{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.services.arch-package-sync;

  # State file location - persists across runs in user's cache directory
  stateFile = "\${HOME}/.cache/arch-package-sync/state.json";

  # Lock file to prevent concurrent executions
  lockFile = "\${HOME}/.cache/arch-package-sync/sync.lock";

  # Create the installer script
  installerScriptFile = pkgs.writeShellScript "arch-package-sync" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Configuration
    STATE_FILE="${stateFile}"
    FLAKE_PATH="$HOME/nix"
    LOCK_FILE="${lockFile}"

    # Colors for output
    RED='\033[0;31m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Parse arguments
    DRY_RUN=0
    VERBOSE=0
    UPDATE=0
    NO_REMOVE=0
    REMOVE_ORPHANS=0

    while [[ $# -gt 0 ]]; do
      case "$1" in
        --dry-run)
          DRY_RUN=1
          shift
          ;;
        --verbose|-v)
          VERBOSE=1
          shift
          ;;
        --no-remove)
          NO_REMOVE=1
          shift
          ;;
        --remove-orphans)
          REMOVE_ORPHANS=1
          shift
          ;;
        --update)
          UPDATE=1
          shift
          ;;
        --help|-h)
          echo "Usage: $0 [OPTIONS]"
          echo ""
          echo "Options:"
          echo "  --dry-run         Show what would be done without making changes"
          echo "  --verbose, -v     Show detailed output"
          echo "  --no-remove       Don't remove packages (only add/update, keep removed in state)"
          echo "  --remove-orphans  Remove orphan packages after sync"
          echo "  --update          Run system update (yay -Syu) before syncing packages"
          echo "  --help, -h        Show this help message"
          exit 0
          ;;
        *)
          echo "Unknown option: $1"
          echo "Run '$0 --help' for usage information"
          exit 1
          ;;
      esac
    done

    # Logging functions
    log() {
      echo -e "''${BLUE}[arch-package-sync]''${NC} $*"
    }

    dryrun() {
      echo -e "''${BLUE}[arch-package-sync] [dry-run]''${NC} $*"
    }

    error() {
      echo -e "''${RED}[arch-package-sync] ERROR:''${NC} $*" >&2
      exit 1
    }

    warn() {
      echo -e "''${YELLOW}[arch-package-sync] WARNING:''${NC} $*" >&2
    }

    if [ "$EUID" -eq 0 ]; then
      error "This script should not be run as root."
    fi

    if ! command -v yay &> /dev/null; then
      error "yay is not installed."
    fi

    if ! command -v jq &> /dev/null; then
      error "jq is not installed."
    fi

    # Ensure cache directory exists first (needed for lock file)
    CACHE_DIR="$HOME/.cache/arch-package-sync"
    if [ ! -d "$CACHE_DIR" ]; then
      log "Creating cache directory: $CACHE_DIR"
      mkdir -p "$CACHE_DIR"  # Always create, even in dry-run
    fi

    # Acquire lock to prevent concurrent runs
    exec 200>"$LOCK_FILE"
    if ! flock -n 200; then
      error "Another instance is already running"
    fi


    # Check if flake exists
    if [ ! -f "$FLAKE_PATH/flake.nix" ]; then
      error "Flake not found at: $FLAKE_PATH"
    fi

    # Run system update if requested
    if [ "$UPDATE" = "1" ]; then
      log "Running system update..."
      if [ "$DRY_RUN" = "1" ]; then
        dryrun "yay -Syu"
      else
        if yay -Syu; then
          log "System update complete"
        else
          error "System update failed"
        fi
      fi
    fi

    # Load previous state
    if [ -f "$STATE_FILE" ]; then
      OLD_STATE=$(cat "$STATE_FILE")
      [ "$VERBOSE" = "1" ] && log "Loaded previous state from $STATE_FILE"
    else
      OLD_STATE='{"version":1,"packages":[]}'
      [ "$VERBOSE" = "1" ] && log "No previous state found, starting fresh"
    fi

    # Load new desired state from flake
    log "Loading package configuration from flake..."

    # Get packages list - try home-manager config
    PACKAGES_JSON=$(nix eval "$FLAKE_PATH/#homeConfigurations.arch.config.services.arch-package-sync.packages" --json 2>/dev/null) || {
      error "Failed to evaluate packages from flake (home-manager config)"
    }

    # Build the new state JSON
    NEW_STATE=$(jq -n \
      --argjson packages "$PACKAGES_JSON" \
      '{version: 1, packages: $packages}')

    # Parse package lists
    OLD_PACKAGES=$(echo "$OLD_STATE" | jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    NEW_PACKAGES=$(echo "$NEW_STATE" | jq -r '.packages[] | select(.state == "present" or .state == null) | .name' | sort -u || true)
    ABSENT_PACKAGES=$(echo "$NEW_STATE" | jq -r '.packages[] | select(.state == "absent") | .name' | sort -u || true)

    # Calculate changes
    TO_INSTALL=$(comm -13 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES") || true)
    TO_REMOVE=$(comm -23 <(echo "$OLD_PACKAGES") <(echo "$NEW_PACKAGES") || true)

    # Add explicitly absent packages to removal list
    if [ -n "$ABSENT_PACKAGES" ]; then
      TO_REMOVE=$(echo -e "$TO_REMOVE\n$ABSENT_PACKAGES" | grep -v '^$' | sort -u || true)
    fi

    # Filter removals based on --no-remove flag (but always remove absent packages)
    if [ "$NO_REMOVE" = "1" ] && [ -n "$TO_REMOVE" ]; then
      # Show what would be skipped
      SKIPPED_PACKAGES=$(comm -23 <(echo "$TO_REMOVE" | sort) <(echo "$ABSENT_PACKAGES" | sort) || true)
      if [ -n "$SKIPPED_PACKAGES" ]; then
        log "Packages that would be removed (--no-remove specified, skipping):"
        echo "$SKIPPED_PACKAGES" | while read -r pkg; do
          [ -n "$pkg" ] && echo "  - $pkg (skipped)"
        done
      fi
      # Keep only packages marked as absent
      TO_REMOVE="$ABSENT_PACKAGES"
    fi

    # Check if any changes are needed
    if [ -z "$TO_INSTALL" ] && [ -z "$TO_REMOVE" ]; then
      log "System is already in sync with the tracked packages list"

      # Still check for orphans if enabled
      if [ "$REMOVE_ORPHANS" = "1" ]; then
        log "Checking for orphan packages..."
        ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
        if [ -n "$ORPHANS" ]; then
          log "Found orphan packages to remove:"
          echo "$ORPHANS" | sed 's/^/  - /'
          if [ "$DRY_RUN" = "1" ]; then
            dryrun "sudo pacman -Rns $(echo $ORPHANS | tr '\n' ' ')"
          else
            echo "$ORPHANS" | sudo pacman -Rns -
            log "Removed orphan packages"
          fi
        else
          log "No orphan packages found"
        fi
      fi

      exit 0
    fi

    if [ -n "$TO_INSTALL" ]; then
      log "Packages to install:"
      echo "$TO_INSTALL" | while read -r pkg; do
        [ -n "$pkg" ] && echo "  + $pkg"
      done
    fi

    if [ -n "$TO_REMOVE" ]; then
      log "Packages to remove:"
      echo "$TO_REMOVE" | while read -r pkg; do
        [ -n "$pkg" ] && echo "  - $pkg"
      done
    fi

    # Install packages
    if [ -n "$TO_INSTALL" ]; then
      log "Installing packages..."
      # Convert newline-separated list to space-separated for yay
      INSTALL_LIST=$(echo "$TO_INSTALL" | tr '\n' ' ')
      if [ "$DRY_RUN" = "1" ]; then
        dryrun "yay -S --needed $INSTALL_LIST"
      else
        if yay -S --needed $INSTALL_LIST; then
          log "Successfully installed packages"
        else
          error "Failed to install some packages"
        fi
      fi
    fi

    # Remove packages
    if [ -n "$TO_REMOVE" ]; then
      log "Removing packages..."
      REMOVE_LIST=$(echo "$TO_REMOVE" | tr '\n' ' ')
      if [ "$DRY_RUN" = "1" ]; then
        dryrun "sudo pacman -Rns $REMOVE_LIST"
      else
        if sudo pacman -Rns $REMOVE_LIST 2>/dev/null; then
          log "Successfully removed packages"
        else
          warn "Some packages could not be removed (may have dependents)"
        fi
      fi
    fi

    # Remove orphans if enabled
    if [ "$REMOVE_ORPHANS" = "1" ]; then
      ORPHANS=$(pacman -Qdtq 2>/dev/null || true)
      if [ -n "$ORPHANS" ]; then
        log "Removing orphan packages:"
        echo "$ORPHANS" | sed 's/^/  - /'
        if [ "$DRY_RUN" = "1" ]; then
          dryrun "sudo pacman -Rns $(echo $ORPHANS | tr '\n' ' ')"
        else
          echo "$ORPHANS" | sudo pacman -Rns -
          log "Removed orphan packages"
        fi
      fi
    fi

    # Save new state
    FINAL_STATE="$NEW_STATE"

    log "Saving state to $STATE_FILE"
    if [ "$DRY_RUN" = "0" ]; then
      echo "$FINAL_STATE" > "$STATE_FILE"
      log "State saved to $STATE_FILE"
    fi

    log "Package sync complete"
  '';

  # Wrap the script in a proper derivation with bin directory
  installerScript = pkgs.runCommand "arch-package-sync" { } ''
    mkdir -p $out/bin
    cp ${installerScriptFile} $out/bin/arch-package-sync
    chmod u+x $out/bin/arch-package-sync
  '';

in
{
  options.services.arch-package-sync = {
    enable = lib.mkEnableOption "Arch Linux package management";

    packages = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Package name as known to pacman/aur";
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
        { name = "visual-studio-code-bin"; }
      ];
      description = "List of packages to manage";
    };
  };

  config = lib.mkIf cfg.enable {
    # Install the script via home.packages
    home.packages = [ installerScript ];

    # Validation assertions
    assertions = [
      {
        assertion = !(lib.elem "pacman" (map (p: p.name) cfg.packages));
        message = "Cannot manage pacman itself through this module";
      }
      {
        assertion = !(lib.elem "yay" (map (p: p.name) cfg.packages));
        message = "Cannot manage yay itself through this module";
      }
      {
        assertion =
          let
            names = map (p: p.name) cfg.packages;
            uniqueNames = lib.unique names;
          in
          (lib.length names) == (lib.length uniqueNames);
        message = "Duplicate package declarations found in services.arch-package-sync.packages";
      }
    ];
  };
}
