## Usage

The `#arch` flake installs 

```bash
...
```

## Installation

### BIOS

1. Enter BIOS and change Secure Boot to `Setup` mode by clearing the current keys
  - Clear current keys in Secure Boot settings
  - Enable Secure Boot
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

6. Edit `/etc/fstab` to [fix the `/boot` partition](https://bbs.archlinux.org/viewtopic.php?id=287790) by setting `fmask=0077` and `dmask=0077`. Then re-mount:

  ```bash
  sudo systemctl daemon-reload
  sudo umount /boot
  sudo mount -a
  ```


### Bootstrap desktop installation

```bash
# bootstrap home-manager configuration, home setup (installs home-manager and system-manager in user profile)
nix run --experimental-features 'nix-command flakes' \
  nixpkgs#home-manager -- switch --flake .#arch

# install system packages with pacman/yay which are managed outside of nix
aps --update

# set up system level configurations managed by nix system-manager
sm-update

# change shell to zsh
chsh -s $(which zsh) 
```

### [Configure Secure Boot](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Assisted_process_with_systemd)

```bash
# generate signing keys and sign
sudo ukify genkey --config /etc/kernel/uki.conf

sudo /usr/lib/systemd/systemd-sbsign sign \
--private-key /etc/kernel/secure-boot-private-key.pem \
--certificate /etc/kernel/secure-boot-certificate.pem \
--output /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed \
/usr/lib/systemd/boot/efi/systemd-bootx64.efi

sudo bootctl install --secure-boot-auto-enroll yes \
  --certificate /etc/kernel/secure-boot-certificate.pem \
  --private-key /etc/kernel/secure-boot-private-key.pem

# Set secure-boot-enroll force in /boot/loader/loader.conf
# and reboot to enroll the keys in the firmware
```

### Keyring

Make sure that the default keyring password matches your login user password. This allows the keyring to unlock automatically on login.
