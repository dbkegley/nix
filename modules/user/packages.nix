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

      # secure boot
      { name = "sbctl"; }

      # framework
      { name = "mesa"; }
      { name = "mesa-utils"; }
      { name = "amd-ucode"; }
      { name = "vulkan-radeon"; }
      { name = "framework-system"; }

      # niri
      { name = "niri"; }
      { name = "gnome-keyring"; }
      { name = "xwayland-satellite"; }
      { name = "xdg-desktop-portal-gnome"; }
      { name = "xdg-desktop-portal-gtk"; }
      { name = "plasma-polkit-agent"; }
      { name = "gpu-screen-recorder"; }

      # desktop shell
      { name = "greetd"; }
      { name = "noctalia-greeter-git"; }
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
    # system bootstrap
    pkgs.system-manager
    pkgs.yay
    jq

    # developer tools
    fzf
    gh
    git
    jujutsu
    just
    cmake

    # nix
    nil
    nixd
    nixfmt

    # go
    go
    golangci-lint

    # rust
    rustup

    # python
    uv

    # odin
    odin
    ols
  ];
}
