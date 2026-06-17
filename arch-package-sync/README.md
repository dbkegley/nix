# Arch Package Sync

A Nix module for declarative Arch Linux package management, designed to work with home-manager or system-manager.

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
2. **Generation Phase**: home-manager/system-manager installs sync script
3. **Sync Phase**: Run `arch-package-sync` which reads config from flake and installs/removes packages

### Workflow
```
1. Edit flake → Define desired packages
         ↓
2. home-manager switch → Install sync script
         ↓  
3. arch-package-sync → Reads flake config & syncs packages
         ↓
4. State saved → Track installed packages for next sync
```

The sync script uses `nix eval` to read the current package list directly from your flake, ensuring it always uses the latest configuration.

## Installation

### With Home Manager

```nix
# In your home-manager configuration
{
  services.arch-package-sync = {
    enable = true;
    packages = [
      { name = "htop"; }
      { name = "neovim"; }
      { name = "visual-studio-code-bin"; }  # AUR package
    ];
  };
}
```

## Configuration Options

### `services.arch-package-sync.enable`
- Type: boolean
- Default: false
- Description: Enable Arch package management

### `services.arch-package-sync.packages`
- Type: list of package specifications
- Default: []
- Description: List of packages to manage

Each package specification has:
- `name` (string, required): Package name as known to pacman/AUR
- `state` (enum ["present" "absent"], default: "present"): Desired state

## Command Line Options

```
arch-package-sync [OPTIONS]

Options:
  --dry-run         Show what would be done without making changes
  --debug           Show debug output
  --no-remove       Don't remove packages (only add/update)
  --remove-orphans  Remove orphan packages after sync
  --update          Run system update (yay -Syu) before syncing
  --help, -h        Show help message
```

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
services.arch-package-sync = {
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
services.arch-package-sync = {
  enable = true;
  packages = [
    { name = "htop"; }
    { name = "visual-studio-code-bin"; }  # AUR package
    { name = "zen-browser"; }  # AUR package
  ];
};
```

### Removing Packages

```nix
services.arch-package-sync = {
  enable = true;
  packages = [
    { name = "htop"; }
    { name = "nano"; state = "absent"; }  # Explicitly remove
  ];
};
```

Packages marked as `absent` are always removed. Packages no longer in the list are removed by default (use `--no-remove` to keep them).

## Running the Sync Script

After updating your configuration and running `home-manager switch`, run:

```bash
# Sync packages (install/remove as needed)
arch-package-sync

# Preview changes without making them
arch-package-sync --dry-run

# Update system first, then sync
arch-package-sync --update

# Only add/update packages, don't remove
arch-package-sync --no-remove

# Remove orphan packages after sync
arch-package-sync --remove-orphans

# Show debug output
arch-package-sync --debug
```

## State Management

The module tracks managed packages in `~/.cache/arch-package-sync/state.json`. This ensures:
- Efficient syncing (only changes what's needed)
- State persists across runs

## Integration with Nix

This module complements Nix package management:

```nix
{
  # Nix packages (reproducible, declarative)
  home.packages = with pkgs; [
    git
    jq
  ];
  
  # Arch packages (latest versions, AUR access)
  services.arch-package-sync.packages = [
    { name = "yay"; }  # AUR helper
    { name = "visual-studio-code-bin"; }  # AUR package
  ];
}
```

## Limitations

1. **No version pinning**: Uses latest available package versions
2. **No reproducibility**: Package versions may differ between installations
3. **Manual sync required**: Script must be run manually after configuration changes
4. **Arch Linux only**: Specifically designed for Arch-based distributions
5. **Requires yay**: Must have yay installed for AUR support

## What Happens During Sync

### Installing Packages
```
$ arch-package-sync
[arch-package-sync] Loading package configuration from flake...
[arch-package-sync] Packages to install:
  + htop
  + neovim
[arch-package-sync] Installing packages...
[arch-package-sync] Successfully installed packages
[arch-package-sync] Package sync complete
```

### Dry Run Mode
```
$ arch-package-sync --dry-run
[arch-package-sync] Loading package configuration from flake...
[arch-package-sync] Packages to install:
  + htop
[arch-package-sync] Installing packages...
[arch-package-sync] [DRY-RUN] yay -S --needed htop
```

### With System Update
```
$ arch-package-sync --update
[arch-package-sync] Running system update...
:: Synchronizing package databases...
:: Starting full system upgrade...
[arch-package-sync] System update complete
[arch-package-sync] Loading package configuration from flake...
[arch-package-sync] System is already in sync with the tracked packages list
```

## Safety Features

- **User execution**: Script runs as regular user (uses sudo only for package operations)
- **Lock file**: Prevents concurrent executions
- **State tracking**: Tracks managed packages to enable safe removal
- **Dry run mode**: Preview all changes before applying
- **Explicit absent**: Packages must be marked `absent` or use default removal
- **Debug mode**: Detailed logging with `--debug` flag
