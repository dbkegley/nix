{
  config,
  ...
}:
{

  imports = [
    ../modules/easyeffects.nix
    ../modules/git.nix
    ../modules/helix.nix
    ../modules/hyprland.nix
    ../modules/ssh.nix
    ../modules/starship.nix
    ../modules/zsh.nix
    ../modules/zed.nix
  ];

  config = {
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
