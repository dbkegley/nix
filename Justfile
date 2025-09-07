bootstrap: _install_yay
  #!/usr/bin/env bash
  set -euo pipefail

  grep -qF "experimental-features" /etc/nix/nix.conf || \
    (echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf)

  nix run nixpkgs#home-manager -- switch --flake .#home

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
  just _install_1password
  just _install_system_packages


_install_yay:
  #!/usr/bin/env bash
  set -euo pipefail

  if command -v yay >/dev/null 2>&1; then
    echo "yay is already installed."
  else
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg --noconfirm -si && cd -
    rm -r /tmp/yay
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
    # discord
    firefox
    ghostty
    # obs-studio
    obsidian
    spotify-launcher
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
      quickshell
      1password
  )

  sudo ${pacman_pkgs_cmd[*]}
  ${yay_pkgs_cmd[*]}


_install_1password: _setup_keyring
  #!/usr/bin/env bash
  set -euo pipefail

  if command -v 1password >/dev/null 2>&1; then
    echo "1password is already installed."
  else
    echo "Installing 1password..."
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --import
    git clone https://aur.archlinux.org/1password.git /tmp/1password
    cd /tmp/1password && makepkg --noconfirm -si && cd -
    rm -r /tmp/1password
  fi

  # TODO: I have not been able to get this working... putting it down for now.
  # https://developer.1password.com/docs/cli/get-started
  # install the 1password-cli if it isn't already installed
  # and create the required group
  # if command -v op >/dev/null 2>&1; then
  #   echo "1password-cli is already installed."
  # else
  #   echo "Installing 1password-cli..."
  #   gpg --keyserver keyserver.ubuntu.com --receive-keys 3FEF9748469ADBE15DA7CA80AC2D62742012EA22
  #   curl -SsL "https://cache.agilebits.com/dist/1P/op2/pkg/v2.32.0/op_linux_amd64_v2.32.0.zip" -o /tmp/op.zip && \
  #     unzip -d /tmp/op /tmp/op.zip && \
  #     mv /tmp/op/op /usr/local/bin/ && \
  #     gpg --verify /tmp/op/op.sig /tmp/op/op && \
  #     rm -r /tmp/op.zip /tmp/op && \
  #     groupadd -f onepassword-cli && \
  #     chgrp onepassword-cli /usr/local/bin/op && \
  #     chmod g+s /usr/local/bin/op
  # fi

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
