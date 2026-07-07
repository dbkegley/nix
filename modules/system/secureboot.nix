{ ... }:
{
  config = {
    # Kernel command line embedded in the UKI; mkinitcpio reads this file by
    # default when building the preset's default_uki.
    environment.etc."kernel/cmdline" = {
      replaceExisting = true;
      text = "cryptdevice=PARTLABEL=cryptroot:root root=/dev/mapper/root zswap.enabled=0 rootflags=subvol=@ rw rootfstype=btrfs";
    };

    # Build a UKI alongside the plain initramfs. The stock mkinitcpio pacman
    # hook rebuilds both whenever a package changes their inputs (kernel,
    # firmware, systemd, cryptsetup, ...). The plain image stays around for
    # archinstall's unsigned boot entry, a fallback that boots only with
    # Secure Boot disabled.
    environment.etc."mkinitcpio.d/linux-lts.preset" = {
      replaceExisting = true;
      text = ''
        ALL_kver="/boot/vmlinuz-linux-lts"

        PRESETS=('default')

        default_image="/boot/initramfs-linux-lts.img"
        default_uki="/boot/EFI/Linux/arch-linux-lts.efi"
      '';
    };

    # Sign freshly built UKIs as part of the build itself. sbctl's own pacman
    # hook (zz-sbctl.hook) does not fire on everything that makes mkinitcpio
    # rebuild the UKI (e.g. linux-firmware or cryptsetup updates), so relying
    # on it alone can leave an unsigned UKI on the ESP.
    environment.etc."initcpio/post/sbctl-sign-uki" = {
      replaceExisting = true;
      mode = "0755";
      text = ''
        #!/usr/bin/env bash
        # mkinitcpio post hook: $1 = kernel image, $2.. = generated artifacts
        set -euo pipefail

        # pre-bootstrap (no sbctl keys yet) there is nothing to sign with
        [ -d /var/lib/sbctl/keys ] || exit 0

        shift
        for image in "$@"; do
          case "$image" in
            *.efi) sbctl sign "$image" ;;
          esac
        done
      '';
    };
  };
}
