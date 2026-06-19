{ pkgs, ... }:
{
  services.arch-package-sync = {
    enable = true;

    # These packages are installed as system packages via pacman/yay.
    # Run arch-package-sync to install them after activating home-manager.
    packages = [
      # system utils
      { name = "less"; }
      { name = "vim"; }

      # framwork
      { name = "mesa"; }
      { name = "mesa-utils"; }
      { name = "amd-ucode"; }
      { name = "easyeffects"; } # https://wiki.archlinux.org/title/Framework_Laptop_13#Speakers
      { name = "framework-system"; }

      # niri
      { name = "niri"; }
      { name = "gnome-keyring"; }
      { name = "xwayland-satellite"; }
      { name = "xdg-desktop-portal-gnome"; }
      { name = "xdg-desktop-portal-gtk"; }
      { name = "plasma-polkit-agent"; }

      # desktop shell
      { name = "noctalia-shell"; }
      { name = "cliphist"; }

      # applications
      { name = "zed"; }
      { name = "firefox"; }
      { name = "ghostty"; }
      { name = "1password"; }
      { name = "1password-cli"; }
      { name = "claude-code"; }
    ];
  };

  home.packages = with pkgs.unstable; [
    # bootstrap
    pkgs.system-manager
    pkgs.yay
    jq

    gh
    fzf
    just
    yazi
    nil
    nixd
    nixfmt
    go_1_24
    golangci-lint
    rustup
    uv
    kubectl
  ];
}
