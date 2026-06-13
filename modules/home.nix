{
  outputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./user/dms.nix
    ./user/easyeffects.nix
    ./user/ghostty.nix
    ./user/git.nix
    ./user/helix.nix
    ./user/hyprland.nix
    ./user/ssh.nix
    ./user/starship.nix
    ./user/zsh.nix
    ./user/zed.nix
  ];

  config = {
    nixpkgs = {
      # NOTE: these overlays are only applied to the nixpkgs instance; they are _not_ applied to nixpkgs-unstable
      overlays = [
        outputs.overlays.unstable-packages
        outputs.overlays.additions
        outputs.overlays.modifications
      ];
      config = {
        allowUnfree = true;
      };
    };

    home = {
      username = config.kegs.username;
      homeDirectory = "/home/${config.kegs.username}";
      sessionPath = [
        "$HOME/.nix-profile/bin"
        "$HOME/.local/bin"
      ];
    };

    programs.home-manager.enable = true;

    home.packages = with pkgs.unstable; [
      claude-code
      gh
      fzf
      jq
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

    # reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "25.05";
  };
}
