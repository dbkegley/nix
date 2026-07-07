# One-command bootstrap for a fresh Arch installation post-archinstall
# Prerequisite: Secure Boot: *Setup Mode* (keys cleared in BIOS); Secure Boot: *ON*
bootstrap: _label_root_partition _harden_boot_fstab
  #!/usr/bin/env bash
  set -euo pipefail
  log() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

  cd "$HOME/nix"

  # installs home-manager, system-manager and arch-package-sync into the nix profile
  log "Applying home-manager configuration"
  nix --extra-experimental-features 'nix-command flakes' run \
    nixpkgs#home-manager -- switch --flake .#arch

  log "Syncing system packages managed outside nix (pacman + yay)"
  arch-package-sync --remove-orphans --update

  log "Applying system-manager configuration (secure boot, greetd, PAM, ...)"
  system-manager switch --flake "$HOME/nix#arch" --sudo

  log "Setting up Secure Boot (sbctl)"

  # generate signing keys once (stored in /var/lib/sbctl) -- never
  # regenerate, or we invalidate keys already enrolled in firmware
  if sudo test -d /var/lib/sbctl/keys; then
    echo "Signing keys already exist; keeping them."
  else
    echo "Generating Secure Boot signing keys..."
    sudo sbctl create-keys
  fi

  # enroll our keys plus the Microsoft certificates (-m keeps MS-signed
  # option ROMs bootable and allows dbx revocation updates). Enrollment is
  # only possible while the firmware is in Setup Mode.
  if sudo sbctl status --json | grep -q '"setup_mode": *true'; then
    echo "Firmware is in Setup Mode; enrolling keys (+ Microsoft certificates)..."
    sudo sbctl enroll-keys --microsoft
    echo "Keys enrolled; Secure Boot will enforce from the next boot."
  elif sudo sbctl status --json | grep -q '"secure_boot": *true'; then
    echo "Secure Boot is already enabled; keys are enrolled."
  else
    echo "WARNING: firmware is not in Setup Mode; keys were NOT enrolled." >&2
    echo "Clear the Secure Boot keys in the BIOS, boot, and re-run bootstrap." >&2
  fi

  # sign systemd-boot at its source: bootctl install/update prefer a .signed
  # loader, and systemd-boot-update.service refreshes the ESP copy on boot
  # after systemd upgrades (sbctl's pacman hook re-signs the source first)
  echo "Signing systemd-boot and installing it to the ESP..."
  src=/usr/lib/systemd/boot/efi/systemd-bootx64.efi
  sudo sbctl sign -s -o "$src.signed" "$src"
  sudo bootctl install
  sudo systemctl enable systemd-boot-update.service

  # build the UKI defined by the mkinitcpio preset (the post hook signs it)
  # and track it in sbctl's database (-s) so `sbctl verify` covers it
  echo "Building and signing the Unified Kernel Image..."
  sudo install -d /boot/EFI/Linux
  sudo mkinitcpio -P
  sudo sbctl sign -s /boot/EFI/Linux/arch-linux-lts.efi

  # sign fwupd's EFI binary (Arch ships it unsigned); fwupd prefers the
  # .signed variant, so firmware updates keep working under Secure Boot
  echo "Signing fwupd's EFI binary..."
  sudo sbctl sign -s -o /usr/lib/fwupd/efi/fwupdx64.efi.signed \
    /usr/lib/fwupd/efi/fwupdx64.efi

  # boot the signed UKI by default; archinstall's unsigned entry remains a
  # fallback for when Secure Boot is disabled
  echo "Setting the signed UKI as the default boot entry..."
  sudo bootctl set-default arch-linux-lts.efi

  # verify everything sbctl tracks -- fail loudly now rather than at the
  # next Secure Boot boot
  echo "Verifying signatures of all tracked files..."
  sudo sbctl verify

  log "Setting login shell to zsh"
  zsh="$(command -v zsh)"
  grep -qxF "$zsh" /etc/shells || echo "$zsh" | sudo tee -a /etc/shells >/dev/null
  if [ "$SHELL" = "$zsh" ]; then
    echo "Login shell is already $zsh."
  else
    chsh -s "$zsh"
    echo "Login shell changed to $zsh (takes effect at next login)."
  fi

  log "Bootstrap complete. Reboot to boot the signed UKI with Secure Boot enforcing."


# Harden the ESP mount: archinstall mounts /boot with fmask/dmask=0022
# (world-readable); tighten to 0077 so secrets on the ESP aren't world-readable.
_harden_boot_fstab:
  #!/usr/bin/env bash
  set -euo pipefail
  log() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

  log "Hardening the /boot (ESP) mount options in /etc/fstab"

  boot_line="$(grep -E '[[:space:]]/boot[[:space:]]' /etc/fstab || true)"
  if [ -z "$boot_line" ]; then
    echo "No /boot entry in fstab; skipping."
    exit 0
  fi
  if echo "$boot_line" | grep -q 'fmask=0077' && echo "$boot_line" | grep -q 'dmask=0077'; then
    echo "/boot is already mounted with fmask=0077,dmask=0077."
    exit 0
  fi

  echo "Setting fmask=0077,dmask=0077 on the /boot entry..."
  sudo sed -i -E '/[[:space:]]\/boot[[:space:]]/ { s/fmask=[0-7]+/fmask=0077/; s/dmask=[0-7]+/dmask=0077/ }' /etc/fstab
  sudo systemctl daemon-reload

  # vfat ignores mask changes on remount, so a full umount/mount is required
  if sudo umount /boot 2>/dev/null; then
    sudo mount /boot
    echo "/boot remounted with fmask=0077,dmask=0077."
  else
    echo "Could not remount /boot now (in use); new options apply on next boot."
  fi


# Assign the LUKS-backing partition a stable GPT name ('cryptroot') so the
# declarative UKI cmdline (cryptdevice=PARTLABEL=cryptroot) is portable.
_label_root_partition:
  #!/usr/bin/env bash
  set -euo pipefail
  log() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

  mapping=root
  label=cryptroot

  log "Labeling the LUKS partition '$label' for the UKI kernel cmdline"

  backing="$(sudo cryptsetup status "$mapping" | awk '/device:/ {print $2}')"
  disk="/dev/$(lsblk -dno pkname "$backing")"
  partnum="$(cat "/sys/class/block/$(basename "$backing")/partition")"

  if [ "$(lsblk -dno PARTLABEL "$backing")" = "$label" ]; then
    echo "Partition $backing is already labeled '$label'."
  else
    echo "Labeling $backing (disk $disk, partition $partnum) as '$label'..."
    sudo sfdisk --part-label "$disk" "$partnum" "$label"
    echo "Partition labeled."
  fi
