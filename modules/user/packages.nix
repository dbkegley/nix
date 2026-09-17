{
  pkgs,
  lib,
  isDarwin,
  ...
}:
lib.mkMerge [
  {
    home.packages =
      (with pkgs.unstable; [
        # developer tools
        jq
        gh
        git
        fzf
        cmake
        ripgrep
        jujutsu
        just

        # cloud
        awscli2
        kubectl

        # nix
        nil
        nixd
        nixfmt

        # go
        go_1_27
        golangci-lint
        golangci-lint-langserver

        # rust
        rustup

        # python
        uv
      ])

      # Linux system bootstrap
      ++ lib.optionals (!isDarwin) [
        pkgs.system-manager
        pkgs.yay
      ];
  }

  # These packages are installed as system packages via pacman/yay.
  # Run arch-package-sync to install them after activating home-manager.
  (lib.optionalAttrs (!isDarwin) {
    services.arch-package-sync = {
      enable = true;

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
        { name = "opencode"; }

        # temp antgame dev
        # TODO: project-specific flake for this
        { name = "odin"; }
        { name = "ols"; }
        { name = "raylib"; }
      ];
    };
  })
]
