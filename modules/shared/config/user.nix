{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.kegs-dev.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "david";
      description = "Primary user name";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "David Kegley";
      description = "User full name";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "david@kegley.me";
      description = "User email address";
    };

    workEmail = lib.mkOption {
      type = lib.types.str;
      default = "david.kegley@posit.co";
      description = "Work email address";
    };

    gpgKey = lib.mkOption {
      type = lib.types.str;
      default = "TODO";
      description = "User GPG key";
    };

    homeDirectory = lib.mkOption {
      type = lib.types.str;
      description = "User home directory";
    };

    shell = lib.mkOption {
      type = lib.types.str;
      default = "zsh";
      description = "Default shell";
    };

    editor = lib.mkOption {
      type = lib.types.str;
      default = "hx";
      description = "Default editor";
    };
  };

  config = {
    kegs-dev.user.homeDirectory = lib.mkDefault (
      if config.kegs-dev.isDarwin then
        "/Users/${config.kegs-dev.user.name}"
      else
        "/home/${config.kegs-dev.user.name}"
    );

    users =
      # Add mutableUsers only on NixOS; nix-darwin does not have this option.
      (lib.optionalAttrs config.kegs-dev.isLinux {
        mutableUsers = config.kegs-dev.persistence.enable;
      })
      // {
        users.${config.kegs-dev.user.name} = lib.mkMerge [
          # Base user configuration
          {
            home = config.kegs-dev.user.homeDirectory;
          }
          # Linux-specific user configuration
          (lib.mkIf config.kegs-dev.isLinux {
            isNormalUser = true;
            group = config.kegs-dev.user.name;
            hashedPasswordFile = config.sops.secrets."users/${config.kegs-dev.user.name}".path;
            extraGroups = lib.mkIf config.kegs-dev.isLinux [ "systemd-journal" ];
          })
          # Darwin-specific user configuration (no extra fields needed)
        ];
        groups.${config.kegs-dev.user.name} = { };
      };
  };
}
