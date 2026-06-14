# Arch Package Manager for Nix

A standalone Nix flake that provides declarative package management for Arch Linux using native package managers (pacman/yay), designed to work with system-manager.

## Overview

This module allows you to:
- Declare Arch packages in your Nix configuration
- Install/remove packages via pacman/yay before system activation
- Fail fast if packages cannot be installed
- Track managed packages for safe removal
- Optionally manage AUR packages

## How It Works

The module uses system-manager's pre-activation assertions to install packages **before** any system configuration changes are applied. If package installation fails, the entire activation is aborted, ensuring your system never ends up in an inconsistent state.

```
system-manager switch
         ↓
Install/remove Arch packages
         ↓
If failed → Abort (no changes)
         ↓  
If success → Apply config & start services
```

## Installation

### As a Flake Input

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    system-manager.url = "github:numtide/system-manager";
    
    arch-package-manager = {
      url = "github:yourusername/arch-package-manager";
      # Or for local development:
      # url = "path:/path/to/arch-package-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.system-manager.follows = "system-manager";
    };
  };
  
  outputs = { self, nixpkgs, system-manager, arch-package-manager, ... }:
  {
    systemConfigs.default = system-manager.lib.makeSystemConfig {
      modules = [
        arch-package-manager.nixosModules.default
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
- Description: Enable Arch package management

### `arch.packageManager.dryRun`
- Type: boolean
- Default: false
- Description: Run in dry-run mode - show what would change without installing

### `arch.packageManager.enableAUR`
- Type: boolean  
- Default: false
- Description: Allow installation of AUR packages via yay

### `arch.packageManager.enableRemoval`
- Type: boolean
- Default: false
- Description: Automatically remove packages no longer in configuration

### `arch.packageManager.packages`
- Type: list of package specifications
- Default: []
- Description: List of packages to manage

Each package specification has:
- `name` (string, required): Package name as known to pacman/yay
- `source` (enum ["pacman" "yay"], default: "pacman"): Package source
- `state` (enum ["present" "absent"], default: "present"): Desired state

## Usage

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

### With AUR Support

```nix
arch.packageManager = {
  enable = true;
  enableAUR = true;
  packages = [
    { name = "htop"; source = "pacman"; }
    { name = "visual-studio-code-bin"; source = "yay"; }
  ];
};
```

### With Package Removal

```nix
arch.packageManager = {
  enable = true;
  enableRemoval = true;  # Removes packages not in list
  packages = [
    { name = "htop"; }
    { name = "nano"; state = "absent"; }  # Explicitly remove
  ];
};
```

## Testing with Dry Run

Set `dryRun = true` in your configuration:

```nix
arch.packageManager = {
  enable = true;
  dryRun = true;  # Enable dry-run mode
  packages = [ ... ];
};
```

Then run system-manager normally:
```bash
sudo system-manager switch
```

This will show what would be installed/removed without making any changes.

## Commands

```bash
# Check current package status
arch-packages-status

# Verify packages are installed
arch-packages-check

# View state file
cat /var/lib/arch-package-manager/state.json | jq
```

## State Management

The module tracks managed packages in `/var/lib/arch-package-manager/state.json`. This ensures:
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
  
  # arch-package-manager handles native packages
  arch.packageManager.packages = [
    { name = "nginx"; }  # Install via pacman
  ];
}
```

## Limitations

1. **No version pinning**: Uses latest available package versions
2. **No reproducibility**: Package versions may differ between installations
3. **Requires privileges**: Needs sudo access for pacman/yay
4. **Arch Linux only**: Specifically designed for Arch-based distributions

## What Happens During Activation

### Success Case
```
$ sudo system-manager switch
[arch-package-manager] Installing nginx via pacman...
[arch-package-manager] Successfully installed nginx
=== Activating system configuration ===
✓ Configuration applied
```

### Failure Case  
```
$ sudo system-manager switch
[arch-package-manager] ERROR: Failed to install bad-package
Pre-activation assertion failed.
Activation aborted. No changes made.
```

## State Management

The module tracks managed packages in `/var/lib/arch-package-manager/state.json` to:
- Avoid reinstalling existing packages
- Enable safe package removal
- Support rollback to previous generations

## Safety Features

- **Fail-fast**: Package failures abort activation
- **Lock file**: Prevents concurrent executions
- **State tracking**: Only manages explicitly declared packages
- **AUR opt-in**: Requires explicit enablement
- **No auto-removal**: Package removal disabled by default
