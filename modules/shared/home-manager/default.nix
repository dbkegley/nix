{
  config,
  options,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  user = config.kegs-dev.user.name;
  flavor = config.kegs-dev.colorScheme.flavor;
  accent = config.kegs-dev.colorScheme.accent;
in
{
  config = lib.mkMerge [
    # (lib.mkIf config.kegs-dev.isLinux {
    #   kegs-dev.core.zfs = lib.mkMerge [
    #     (lib.mkIf config.kegs-dev.persistence.enable {
    #       homeCacheLinks = [
    #         ".config"
    #         ".cache"
    #         ".local"
    #         ".cloudflared"
    #       ];
    #     })
    #   ];
    # })
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        # Fix for file conflicts during darwin-rebuild/home-manager activation
        backupFileExtension = "backup";
        users = {
          "${user}" =
            { ... }:
            {
              # Common config
              imports = [
                inputs.catppuccin.homeModules.catppuccin
                inputs.nix-colors.homeManagerModules.default
              ];

              colorScheme = inputs.nix-colors.colorSchemes.catppuccin-macchiato;

              home = {
                stateVersion = config.kegs-dev.stateVersion;
                username = config.kegs-dev.user.name;
                homeDirectory = config.kegs-dev.user.homeDirectory;
                # sessionVariables = {
                #   SOPS_AGE_KEY_FILE = config.kegs-dev.user.homeDirectory + "/.config/sops/age/keys.txt";
                # };
              };

              programs.home-manager.enable = true;

              # User-specific catppuccin configuration
              catppuccin = {
                enable = true;
                flavor = flavor;
                accent = accent;
              };
            };
        };
      };
    }
  ];
}
