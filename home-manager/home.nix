{ inputs, outputs, lib, config, pkgs, ... }:
let cfg = config.kegs;
in {
  options.kegs = {
    isDesktop = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    isWork = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "david";
      description = "unix username";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "David Kegley";
      description = "full name";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "david@kegley.me";
      description = "personal email";
    };
    workEmail = lib.mkOption {
      type = lib.types.str;
      default = "david.kegley@posit.co";
      description = "work email";
    };
  };

  imports = [
    ../modules/dank-material-shell.nix
    ../modules/desktop.nix
    ../modules/ghostty.nix
    ../modules/git.nix
    ../modules/helix.nix
    ../modules/hyprland.nix
    ../modules/ssh.nix
    ../modules/starship.nix
    ../modules/zsh.nix
  ];

  config = {
    nixpkgs = {
      # NOTE: these overlays are only applied to the nixpkgs instance; they are _not_ applied to nixpkgs-unstable
      overlays = [
        outputs.overlays.unstable-packages
        outputs.overlays.additions
        outputs.overlays.modifications
      ];
      config = { allowUnfree = true; };
    };

    home = {
      username = cfg.username;
      homeDirectory = "/home/${cfg.username}";
      sessionPath = [ "$HOME/.nix-profile/bin" ];
    };

    programs.home-manager.enable = true;

    home.packages = with pkgs.unstable; [
      btop
      yazi
      fzf
      jq
      just
      kubectl
      go_1_24
      golangci-lint
      rustup
      uv
    ];

    # reload system units when changing configs
    systemd.user.startServices = "sd-switch";

    # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
    home.stateVersion = "25.05";
  };
}
