## Usage

The `#arch` flake installs 

```bash
...
```

## Installation

### BIOS

1. Enter BIOS and change Secure Boot to `Setup` mode
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
# backup current variables
for var in PK KEK db dbx ; do efi-readvar -v $var -o old_${var}.esl ; done

# generate signing keys and sign
sudo ukify genkey --config /etc/kernel/uki.conf

systemd-sbsign sign \
  --private-key /etc/kernel/secure-boot-private-key.pem \
  --certificate /etc/kernel/secure-boot-certificate.pem \
  --output /usr/lib/systemd/boot/efi/systemd-bootx64.efi.signed \
  /usr/lib/systemd/boot/efi/systemd-bootx64.efi

bootctl install --secure-boot-auto-enroll yes \
  --certificate /etc/kernel/secure-boot-certificate.pem \
  --private-key /etc/kernel/secure-boot-private-key.pem
```

### Keyring

Make sure that the default keyring password matches your login user password. This allows the keyring to unlock automatically on login.
