{
  inputs,
  pkgs,
  lib,
  isDarwin,
  ...
}:
lib.mkMerge [
  {
    home.packages = [
      # jj from the pinned upstream commit (see the `jj` input in flake.nix).
      inputs.jj.packages.${pkgs.stdenv.hostPlatform.system}.jujutsu

      # rig, the R installation manager (pkgs/r-rig).
      #
      # Run the following to avoid system-wide R installations:
      #   $ rig system user-mode
      #   $ rig add
      #   $ R
      #   R> install.packages('renv')
      #   R> install.packages('languageserver')
      pkgs.r-rig
    ]
    ++ (with pkgs.unstable; [
      # developer tools
      jq
      gh
      git
      fzf
      cmake
      ripgrep
      just

      # cloud
      awscli2
      kubectl

      # nix
      nil
      nixd
      nixfmt

      # go
      gopls
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
