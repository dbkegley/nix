{
  outputs,
  config,
  ...
}:
{
  imports = [
    ./user/packages.nix
    ./user/ghostty.nix
    ./user/git.nix
    ./user/helix.nix
    ./user/niri.nix
    ./user/noctalia.nix
    ./user/opencode.nix
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
        outputs.overlays.yay-fix
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

    # reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "25.05";
  };
}
