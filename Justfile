bootstrap: _install_yay
  #!/usr/bin/env bash
  set -euo pipefail

  nix --extra-experimental-features 'nix-command flakes' \
    run 'github:numtide/system-manager' -- \
    switch --flake $HOME/nix#arch --sudo
  nix run nixpkgs#home-manager -- switch --flake .#arch

  # add nix-managed zsh to /etc/shells
  zsh="$(which zsh)"
  grep -qF "$zsh" /etc/shells || \
    (echo "$zsh" | sudo tee -a /etc/shells)

  # change default shell
  if [ "$SHELL" != "$zsh" ]; then
    chsh -s "$zsh" && echo "Default shell updated. You need to re-login!"
  fi


# full hyprland desktop and system dependency installation
desktop:
  just _setup_sddm
  just _install_system_packages
  just _setup_1password


_install_yay:
  #!/usr/bin/env bash
  set -euo pipefail

  if command -v yay >/dev/null 2>&1; then
    echo "yay is already installed."
  else
    git clone https://aur.archlinux.org/yay.git $HOME/.local/share/yay
    cd $HOME/.local/share/yay && makepkg --noconfirm -si && cd -
  fi


_install_system_packages:
  #!/usr/bin/env bash
  set -euo pipefail

  framework13=(
    mesa             # gpu drivers
    mesa-utils
    amd-ucode        # amd cpu microcode updates
    framework-system # framwork utils

    # https://wiki.archlinux.org/title/Framework_Laptop_13#Speakers
    easyeffects
  )

  applications=(
    firefox
    ghostty
  )

  hyprland=(
    # hyprland
    polkit
    polkit-kde-agent
    uwsm
    libnewt
    hyprland
    hyprpicker
    hyprland-qt-support
    qt5-wayland
    qt6-wayland
    xdg-desktop-portal-hyprland

    # dank material shell
    cava             # audio equalizer
    wl-clipboard     # clipboard persistence
    cliphist         # clipboard history
    bluez            # bluetooth control
    brightnessctl    # screen brightness
    networkmanager   # network control
    ttf-0xproto-nerd # nerd font
  )

  # screenshots
  hyprshot=(
    grim
    slurp
    hyprshot
  )

  pacman_pkgs_cmd=(
    pacman --noconfirm --needed -S
      ${framework13[*]}
      ${applications[*]}
      ${hyprland[*]}
      ${hyprshot[*]}
  )

  yay_pkgs_cmd=(
    yay --noconfirm --needed -S
      aur/quickshell-git
      1password
      1password-cli
  )

  sudo ${pacman_pkgs_cmd[*]}
  ${yay_pkgs_cmd[*]}


_setup_1password: _setup_keyring
  #!/usr/bin/env bash
  set -euo pipefail

  # TODO: unclear if yay -S 1password-cli sets up the requires group
  # groupadd -f onepassword-cli && \
  # chgrp onepassword-cli /usr/local/bin/op && \
  # chmod g+s /usr/local/bin/op

  if command -v op-ssh-sign >/dev/null 2>&1; then
    echo "1password op-ssh-sign is already installed."
  else
    echo "Installing 1password op-ssh-sign..."
    ln -sf /opt/1Password/op-ssh-sign /usr/local/bin/op-ssh-sign
  fi


_setup_sddm:
  #!/usr/bin/env bash
  set -euo pipefail

  if [[ "$EUID" == 0 ]]; then
    echo "do not execute this as root."
    exit 1
  fi

  sudo mkdir -p /etc/sddm.conf.d
  if [ ! -f /etc/sddm.conf.d/autologin.conf ]; then
    sudo tee /etc/sddm.conf.d/autologin.conf << EOF
  [Autologin]
  User=$USER
  Session=hyprland-uwsm
  [Theme]
  Current=breeze
  EOF
  fi

  sudo pacman --noconfirm --needed -S sddm
  sudo systemctl enable getty@tty1.service
  sudo systemctl enable sddm.service
  sudo systemctl daemon-reload


_setup_keyring:
  #!/usr/bin/env bash
  set -euo pipefail

  sudo pacman --noconfirm --needed -S \
    libsecret \
    gnome-keyring

  KEYRING_DIR="$HOME/.local/share/keyrings"
  KEYRING_FILE="Default_keyring.keyring"
  DEFAULT_FILE="default"

  mkdir -p "$KEYRING_DIR"
  cat << EOF > "$KEYRING_DIR/$KEYRING_FILE"
  [keyring]
  display-name=Default keyring
  ctime=$(date +%s)
  mtime=0
  lock-on-idle=false
  lock-after=false
  EOF

  cat << EOF > "$KEYRING_DIR/$DEFAULT_FILE"
  Default_keyring
  EOF

  chmod 700 "$KEYRING_DIR"
  chmod 600 "$KEYRING_DIR/$KEYRING_FILE"
  chmod 644 "$KEYRING_DIR/$DEFAULT_FILE"
