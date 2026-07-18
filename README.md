# Arch + Nix System/Home Manager

A mostly declarative configuration for Arch Linux, managed with Nix flakes.

The goal is a reproducible system where both the OS and my user environment are
defined in one repo and applied with a single command — without giving up Arch
and pacman for NixOS.

- **OS-level config** (Secure Boot, greetd, PAM, users) via
  [system-manager](https://github.com/numtide/system-manager).
- **User-level config** (dotfiles, shell, editors, desktop) via
  [home-manager](https://nix-community.github.io/home-manager).
- **Native Arch packages** (things that want to be system packages, e.g. niri,
  Framework tooling, 1Password) via `arch-package-sync`, which reconciles
  pacman/yay against a declared list defined in the nix configuration.

## Usage

Apply changes after editing the config:

```bash
hm-update   # home-manager switch --flake ~/nix#arch
sm-update   # system-manager switch --flake ~/nix#arch --sudo

# periodic package updates
aps --update # system packages

nix flake update nixpkgs # update stable
nix flake update nixpkgs-unstable # update unstable 
```

Reconcile native Arch packages with the declared list in `modules/user/packages.nix`:

```bash
arch-package-sync --remove-orphans --update
```

## Important software

Core tooling this repo configures and/or installs:

**Nix management**
- [system-manager](https://github.com/numtide/system-manager) — declarative OS config on non-NixOS distros
- [home-manager](https://nix-community.github.io/home-manager) — declarative user environment
- `arch-package-sync` — reconciles pacman/yay against a declared package list ([`./arch-package-sync`](./arch-package-sync))

**Desktop**
- [niri](https://github.com/YaLTeR/niri) — scrollable-tiling Wayland compositor
- [noctalia-shell](https://github.com/noctalia-dev/noctalia-shell) — desktop shell (bar, launcher, greeter)
- [greetd](https://sr.ht/~kennylevinsen/greetd/) — minimal login/display manager
- [gnome-keyring](https://wiki.archlinux.org/title/GNOME/Keyring) — secret storage, auto-unlocked on login

**Terminal & editors**
- [Ghostty](https://ghostty.org) — terminal emulator
- [Zed](https://zed.dev) — primary editor
- [Helix](https://helix-editor.com) — modal terminal editor
- [zsh](https://www.zsh.org/) + [Starship](https://starship.rs) — shell and prompt

## Bootstrapping a new Arch installation

### BIOS

1. Enter BIOS and put Secure Boot into `Setup` mode by clearing/erasing the current
   keys. Leave Secure Boot enforcement *enabled* (on Framework: "Enforce Secure Boot"):
   in Setup Mode it is inactive, and it activates automatically once bootstrap enrolls
   the new keys. Setup Mode persists across reboots until a new Platform Key is
   enrolled, so the ISO and the fresh install boot normally in the meantime.
2. Add a BIOS password so that Secure Boot cannot be disabled
3. Boot from installation medium

### Boot from Arch iso

1. Use [iwctl](https://wiki.archlinux.org/title/Iwd) to connect to wifi.
2. Run [archinstall](https://wiki.archlinux.org/title/Archinstall)

  ```bash
  archinstall --config-url https://raw.githubusercontent.com/dbkegley/nix/refs/heads/main/archinstall/user_configuration.json
  #  Make sure to configure the following options:
  #  - default partitioning with btrfs
  #  - luks disk encryption + password
  #  - set root password
  #  - set log in user
  ```

3. Reboot.
4. Use `nmcli` to connect to wifi.
5. [Upgrade firmware](https://wiki.archlinux.org/title/Fwupd).

  ```bash
  # make sure the battery is less than 100% and the laptop is plugged in to power
  fwupdmgr refresh --force
  fwupdmgr get-updates
  fwupdmgr update
  ```

### Bootstrap

Clone this repo to `$HOME/nix`, then run the `bootstrap` target. It is idempotent
and does everything else in one command:

```bash
git clone https://github.com/dbkegley/nix "$HOME/nix" && cd "$HOME/nix"
nix --extra-experimental-features 'nix-command flakes' run nixpkgs#just -- bootstrap
```

`just bootstrap` performs, in order:

1. **Labels the LUKS partition `cryptroot`** so the UKI kernel cmdline is portable
   (`cryptdevice=PARTLABEL=cryptroot`). Only the GPT partition *name* changes; the
   PARTUUID is untouched, so the archinstall-generated fallback entry keeps working.
2. **Hardens the `/boot` (ESP) mount** to `fmask=0077,dmask=0077`.
3. **Applies the home-manager and system-manager configuration** and syncs
   pacman/yay packages.
4. **Configures [Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Assisted_process_with_sbctl)
   with sbctl:** creates signing keys (once) and enrolls them — together with the
   Microsoft certificates — directly into the firmware while it is in Setup Mode,
   signs systemd-boot and fwupd's EFI binary, builds + signs a Unified Kernel Image
   via the mkinitcpio preset, and makes the UKI the default boot entry.
5. **Sets the login shell to zsh.**

Reboot when it finishes. Keys are enrolled during bootstrap, so the first reboot
already boots the signed UKI with Secure Boot enforcing. The unsigned bare-kernel
entry created by archinstall remains as a fallback that boots only with Secure
Boot disabled.

After bootstrap everything re-signs itself: the stock mkinitcpio pacman hook
rebuilds the UKI whenever a package changes its inputs, a mkinitcpio post hook
(see `modules/system/secureboot.nix`) signs every rebuilt UKI, sbctl's own pacman
hook re-signs the bootloader and fwupd binaries, and `systemd-boot-update.service`
copies the freshly signed loader onto the ESP at the next boot. Firmware updates
via `fwupdmgr` keep working under Secure Boot because fwupd's EFI binary is signed
with our key. Run `sudo sbctl verify` to check signing status at any time.

### Keyring

Make sure that the default keyring password matches your login user password. This allows the keyring to unlock automatically on login.
