# Arch Package Manager for Nix

A standalone Nix flake that provides declarative package management for Arch Linux using yay, designed to work with system-manager.

## Overview

This module allows you to:
- Declare Arch packages in your Nix configuration
- Generate a sync script that uses yay to install/remove packages
- Track managed packages for safe removal
- Automatically manage both official and AUR packages
- Optionally remove orphan packages

## How It Works

The module generates a user script that syncs your system packages with your declared configuration:

1. **Configuration Phase**: Declare packages in your Nix configuration
2. **Generation Phase**: system-manager generates sync script
3. **Sync Phase**: User runs the sync script which reads config from flake and installs/removes packages

### Workflow
```
1. Edit packages.nix → Define desired packages
         ↓
2. system-manager switch → Install sync script to ~/.local/bin
         ↓  
3. arch-package-sync → Reads flake config & syncs packages via yay
         ↓
4. State saved → Track installed packages for next sync
```

The sync script uses `nix eval` to read the current package list directly from your flake, ensuring it always uses the latest configuration.

## Installation

### As a Flake Input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    system-manager.url = "github:numtide/system-manager";
    
    arch-package-sync = {
      url = "github:yourusername/arch-package-sync";
      # Or for local development:
      # url = "path:/path/to/arch-package-sync";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.system-manager.follows = "system-manager";
    };
  };
  
  outputs = { self, nixpkgs, system-manager, arch-package-sync, ... }:
  {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        arch-package-sync.nixosModules.default
        {
          arch.packageManager = {
            enable = true;
            packages = [
              { name = "postgresql"; }
              { name = "nginx"; }
            ];
          };
        }
      ];
    };
  };
}
```

## Configuration Options

### `arch.packageManager.enable`
- Type: boolean
- Default: false
- Description: Enable Arch package management via yay

### `arch.packageManager.removeOrphans`
- Type: boolean  
- Default: false
- Description: Automatically remove orphan packages after sync

### `arch.packageManager.enableRemoval`
- Type: boolean
- Default: false
- Description: Automatically remove packages no longer in configuration

### `arch.packageManager.packages`
- Type: list of package specifications
- Default: []
- Description: List of packages to manage

Each package specification has:
- `name` (string, required): Package name as known to pacman/aur
- `state` (enum ["present" "absent"], default: "present"): Desired state

## Usage

### Prerequisites

Install yay (AUR helper):
```bash
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### Basic Configuration

```nix
arch.packageManager = {
  enable = true;
  packages = [
    { name = "htop"; }
    { name = "neovim"; }
    { name = "ripgrep"; }
  ];
};
```

### With AUR Packages

```nix
arch.packageManager = {
  enable = true;
  packages = [
    { name = "htop"; }
    { name = "visual-studio-code-bin"; }  # AUR package
    { name = "zen-browser"; }  # AUR package
  ];
};
```

**Note**: yay automatically handles both official and AUR packages. There's no need to specify the source.

### With Package Removal

```nix
arch.packageManager = {
  enable = true;
  enableRemoval = true;  # Remove packages no longer in list
  removeOrphans = true;  # Also remove orphan dependencies
  packages = [
    { name = "htop"; }
    { name = "nano"; state = "absent"; }  # Explicitly remove
  ];
};
```

## Running the Sync Script

After updating your configuration and running `system-manager switch`, the script will be installed to `~/.local/bin/arch-package-sync`:

```bash
# Sync packages (install/remove as needed)
arch-package-sync

# Preview changes without making them
arch-package-sync --dry-run

# Show detailed output
arch-package-sync --verbose

# Enable removal of packages not in config (overrides flake setting)
arch-package-sync --enable-removal

# Remove orphan packages after sync (overrides flake setting)
arch-package-sync --remove-orphans

# See all options
arch-package-sync --help
```

Note: Make sure `~/.local/bin` is in your PATH.

## State Management

The module tracks managed packages in `/var/lib/arch-package-sync/state.json`. This ensures:
- Only previously managed packages are removed
- Manual installations are preserved
- State persists across activations

## Integration with system-manager

This module is designed to work alongside system-manager:

```nix
{
  # system-manager handles /etc, services, tmpfiles
  environment.etc."someconfig.conf".text = "...";
  systemd.services.myservice = { ... };
  
  # arch-package-sync handles native packages
  arch.packageManager.packages = [
    { name = "nginx"; }  # Install via yay
    { name = "docker"; }
  ];
}
```

The sync script is generated during system-manager activation but must be run manually.

## Limitations

1. **No version pinning**: Uses latest available package versions
2. **No reproducibility**: Package versions may differ between installations
3. **Manual sync required**: Script must be run manually after configuration changes
4. **Arch Linux only**: Specifically designed for Arch-based distributions
5. **Requires yay**: Must have yay installed for AUR support

## What Happens During Sync

### Success Case
```
$ /etc/arch-package-sync/sync
[arch-package-sync] Package sync required:
[arch-package-sync] Packages to install:
  + nginx
  + docker
[arch-package-sync] Installing packages...
[arch-package-sync] Successfully installed packages
[arch-package-sync] Package sync completed successfully
```

### Dry Run
```
$ /etc/arch-package-sync/sync --dry-run
[arch-package-sync] DRY RUN MODE - No changes will be made
[arch-package-sync] Package sync required:
[arch-package-sync] Packages to install:
  + nginx
[arch-package-sync] Would run: yay -S --needed --noconfirm nginx
```

## State Management

The module tracks managed packages in `/var/lib/arch-package-sync/state.json` to:
- Avoid reinstalling existing packages
- Enable safe package removal
- Support rollback to previous generations

## Safety Features

- **User execution**: Script runs as regular user, not root
- **Lock file**: Prevents concurrent executions
- **State tracking**: Only manages explicitly declared packages
- **Dry run mode**: Preview changes before applying
- **No auto-removal**: Package removal disabled by default
- **Orphan control**: Optional automatic orphan removal
