{ lib, config, pkgs, ... }:
let cfg = config.kegs;
in {
  config = {
    home.file = {
      ".config/zed/keymap.json".source = ../config/zed/keymap.jsonc;
      ".config/zed/settings.json".source = ../config/zed/settings.jsonc;
    };
    programs.zed-editor = {
      enable = true;
      # use system zed
      package = null;
    };
  };
}
