# Nix Configuration for Arch Linux

This project manages system and user configuration for Arch Linux using Nix flakes with system-manager and home-manager.

## Architecture

- **OS**: Arch Linux (not NixOS)
- **System Management**: system-manager (standalone)
- **User Management**: home-manager (standalone installation)
- **Flake**: Nix 26.05

## Key Commands

```bash
# Update system configuration
sm-update  # Alias: system-manager switch --flake $HOME/nix#arch --sudo

# Update home configuration  
hm-update  # Alias: home-manager switch --flake $HOME/nix/#arch
```

## Project Structure

```
/home/david/nix/
├── flake.nix              # Main flake configuration
├── modules/
│   ├── kegs.nix          # User configuration options
│   ├── system.nix        # System-manager configuration
│   ├── home.nix          # Home-manager configuration
│   ├── system/           # System-specific modules
│   └── user/             # User-specific modules
├── arch-package-manager/  # Arch package management integration
├── config/               # Configuration files
└── Justfile             # Task runner (bootstrap, desktop setup)
```

## Flake Outputs

- `systemConfigs.arch`: System-manager configuration
- `homeConfigurations.arch`: Home-manager configuration

## External Resources

- **system-manager source**: `/home/david/code/system-manager`
- **system-manager docs**: https://github.com/numtide/system-manager
- **home-manager docs**: https://nix-community.github.io/home-manager

## Testing Commands

When making changes, verify configurations with:

```bash
# Check flake evaluation
nix flake check

# Build without switching
nix build .#systemConfigs.arch
nix build .#homeConfigurations.arch
```