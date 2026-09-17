{
  outputs,
  config,
  lib,
  pkgs,
  isDarwin,
  ...
}:
{
  imports = [
    ./user/packages.nix
    ./user/ghostty.nix
    ./user/git.nix
    ./user/jj.nix
    ./user/helix.nix
    ./user/ssh.nix
    ./user/starship.nix
    ./user/zed.nix
    ./user/zsh.nix
  ]
  # Linux-only modules
  ++ lib.optionals (!isDarwin) [
    ./user/niri.nix
    ./user/noctalia.nix
    ./user/opencode.nix
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
      homeDirectory = config.kegs.homeDir;
      sessionPath = [
        "$HOME/.nix-profile/bin"
        "$HOME/.local/bin"
      ];
    };

    programs.home-manager.enable = true;

    nix = {
      package = pkgs.nix;
      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # auto-optimise-store is a restricted (daemon-side) setting and is
        # ignored when set from a non-trusted user's nix.conf. Migrate this to
        # the system nix.conf via nix-darwin (darwin) / system-manager (arch)
        # once that's set up, so the daemon actually honours it.
        # auto-optimise-store = true;
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };

    # reload system units when changing configs
    systemd.user.startServices = lib.mkIf (!isDarwin) "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "25.05";
  };
}
