# ADR-001: Privilege Separation for AUR Package Building

## Status
Proposed

## Context and Problem Statement

The arch-package-sync module needs to install both official Arch packages (via pacman) and AUR packages (via makepkg). This creates a fundamental security conflict:

- **pacman** must run as root to install packages system-wide
- **makepkg** must NOT run as root and must NOT have access to sudo (security requirement for untrusted build scripts)
- **system-manager** pre-activation scripts run as root when invoked with `--sudo`

The challenge: How do we securely build AUR packages without root access while still integrating with system-manager's root-level activation process?

Additional constraints:
- Minimize password prompts for good UX
- Maintain security boundaries between build and install operations
- Integrate cleanly with existing Nix/system-manager workflows
- Allow modules to declare both system-manager configs and Arch packages in the same file

## Considered Solutions

### 1. Fork-exec with privilege dropping in pre-activation
**Approach**: Use `su -` within the pre-activation script to drop privileges for yay/makepkg
**Rejected because**: 
- Multiple password prompts (one per AUR package)
- Complex privilege management within a single script
- Poor UX

### 2. Standalone wrapper with cached sudo
**Approach**: Create wrapper script that runs before system-manager, using `sudo -v` to cache credentials
**Rejected because**:
- Cached sudo credentials are inherited by child processes
- makepkg/nix builds could escalate to root (critical security flaw)
- Violates the principle that builds must be unprivileged

### 3. Using yay for all packages
**Approach**: Let yay handle both official and AUR packages with its own sudo management
**Rejected because**:
- Still has the cached credential problem
- Less control over the build/install separation
- Requires yay as additional dependency

### 4. Batch build with makepkg, batch install with pacman
**Approach**: Build all AUR packages first (unprivileged), then install everything at once
**Rejected because**:
- Still requires managing privilege transitions
- Build environment not well-isolated
- Temporary storage management is complex

## Chosen Solution: Two-Phase Nix Build + Pre-activation Install

Completely separate the unprivileged build phase from the privileged install phase using Nix's build sandbox for perfect isolation.

### Phase 1: Build AUR packages in Nix derivation (unprivileged)

```nix
# In arch-package-sync/default.nix
let
  # Build all AUR packages as a Nix derivation
  aurPackagesBuilt = pkgs.stdenv.mkDerivation {
    name = "aur-packages-built";
    
    # Dependencies for building AUR packages
    nativeBuildInputs = with pkgs; [
      git
      pacman
      fakeroot
      binutils
      gcc
      make
      pkg-config
    ];
    
    # AUR package definitions from config
    aurPackages = lib.filter (p: p.source == "yay" || p.source == "aur") cfg.packages;
    
    buildPhase = ''
      mkdir -p $out
      
      # Build each AUR package in Nix sandbox
      ${lib.concatMapStrings (pkg: ''
        echo "Building AUR package: ${pkg.name}"
        
        # Clone AUR repository
        git clone --depth=1 https://aur.archlinux.org/${pkg.name}.git
        cd ${pkg.name}
        
        # Build package with makepkg (runs unprivileged in sandbox)
        # --nodeps because dependencies handled separately
        # --noconfirm for non-interactive
        makepkg --nodeps --noconfirm --noprogressbar
        
        # Store built package
        cp *.pkg.tar.zst $out/
        cd ..
      '') config.aurPackages}
    '';
    
    # Output is a directory containing all built .pkg.tar.zst files
    installPhase = "true";  # buildPhase handles output
  };
in
```

### Phase 2: Install packages in pre-activation (privileged)

```bash
# In preActivationScript - runs as root with system-manager --sudo
set -euo pipefail

# Official packages list
PACMAN_PACKAGES="${toString (filter (p: p.source == "pacman") cfg.packages)}"

# Pre-built AUR packages from Nix store
AUR_BUILT_DIR="${aurPackagesBuilt}"

# Single pacman invocation installs everything
# First install any built AUR packages
if [ -d "$AUR_BUILT_DIR" ] && [ "$(ls -A $AUR_BUILT_DIR)" ]; then
  pacman -U --needed --noconfirm "$AUR_BUILT_DIR"/*.pkg.tar.zst
fi

# Then install official packages
if [ -n "$PACMAN_PACKAGES" ]; then
  pacman -S --needed --noconfirm $PACMAN_PACKAGES
fi
```

### Module Integration Example

Users can define both system-manager and arch packages in the same module:

```nix
# modules/system/docker.nix
{ config, lib, pkgs, ... }:
{
  # System-manager configuration
  services.docker = {
    enable = true;
    enableOnBoot = true;
  };
  
  systemd.services.my-app = {
    enable = true;
    after = [ "docker.service" ];
    # ...
  };

  # Arch packages needed by this module
  arch.packageManager.packages = [
    { name = "docker"; }                    # Official repo
    { name = "docker-compose"; }            # Official repo
    { name = "lazydocker"; source = "aur"; }  # AUR package
  ];
}
```

### System Configuration

```nix
# flake.nix
{
  system-manager.lib.makeSystemConfig {
    modules = [
      arch-package-sync.nixosModules.default  # The module
      ./modules/system/docker.nix                # User modules
      {
        arch.packageManager = {
          enable = true;
          enableAUR = true;
        };
      }
    ];
  };
}
```

## Benefits

1. **Perfect security isolation**: Build phase has zero access to root/sudo (Nix sandbox)
2. **Single password prompt**: Only when running `system-manager --sudo`
3. **Reproducible builds**: AUR packages become Nix derivations
4. **Cacheable**: Nix won't rebuild unchanged AUR packages
5. **Clean integration**: Modules can define packages alongside services
6. **No additional tools**: Uses makepkg directly, no yay dependency

## Drawbacks

1. **Larger Nix closure**: Requires build tools in Nix store
2. **Build-time complexity**: Need to handle makepkg dependencies
3. **AUR packages not verified**: Still trusting AUR PKGBUILDs

## Limitations

### Transitive AUR Dependencies
AUR packages that depend on other AUR packages must have all dependencies explicitly declared. This is because makepkg runs with `--nodeps` in the isolated Nix sandbox.

**Example**: If `visual-studio-code-bin` (AUR) depends on `electron25-bin` (AUR):
```nix
arch.packageManager.packages = [
  { name = "electron25-bin"; source = "aur"; }      # Dependency first
  { name = "visual-studio-code-bin"; source = "aur"; }  # Then dependent
];
```

Official repo dependencies are handled automatically by pacman during installation.

## Implementation Notes

- makepkg dependencies can be provided via Nix or assumed present on host
- Consider adding integrity checking for AUR packages
- Built packages stored in Nix store, cleaned up with garbage collection
- Network access during build phase needs consideration (fixed-output derivation or impure)
- Future enhancement: Parse .SRCINFO files to detect missing AUR dependencies and warn users
