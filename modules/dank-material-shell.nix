{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.kegs.isDesktop {

    fonts.fontconfig.enable = true;

    home.packages = with pkgs; [
      # dank material shell
      dms-cli
      dgop
      material-symbols
      inter
      fira-code
      ddcutil
      libsForQt5.qt5ct
      kdePackages.qt6ct
    ];

    home.file = {
      ".local/state/DankMaterialShell/default-session.json".source =
        ../config/DankMaterialShell/default-session.json;

      ".config/DankMaterialShell/default-seetings.json".source =
        ../config/DankMaterialShell/default-settings.json;

      ".config/quickshell/dms".source = builtins.fetchGit {
        url = "https://github.com/AvengeMedia/DankMaterialShell.git";
        rev = "d4816bd174901cb5582151dac6ead636cf96090d";
      };

      "Pictures/wallpapers" = {
        source = ../wallpapers;
        recursive = true;
      };
    };
  };
}
