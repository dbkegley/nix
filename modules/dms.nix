{
  config,
  pkgs,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [
      dms-cli
      dgop

      # System utilities
      ddcutil
      libsForQt5.qt5ct
      kdePackages.qt6ct
    ];

    fonts.packages = with pkgs; [
      material-symbols
      inter
      fira-code
    ];

    # User-level configuration via home-manager
    home-manager.users.${config.kegs.username} =
      { ... }:
      {
        fonts.fontconfig.enable = true;

        xdg.configFile = {
          "DankMaterialShell/default-settings.json".source =
            ../config/DankMaterialShell/default-settings.json;

          "quickshell/dms".source = "${
            builtins.fetchGit {
              url = "https://github.com/AvengeMedia/DankMaterialShell.git";
              rev = "eb5afcdc40ea5446c27e18552ff4a19f9daf9484"; # 1.4.6
            }
          }/quickshell";
        };

        home.file = {
          ".local/state/DankMaterialShell/default-session.json".source =
            ../config/DankMaterialShell/default-session.json;

          "Pictures/wallpapers" = {
            source = ../wallpapers;
            recursive = true;
          };
        };
      };
  };
}
