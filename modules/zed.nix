{ lib, config, pkgs, ... }:
let cfg = config.kegs;
in {
  config = {
    home.file = {
      ".config/zed/keymap.json".source = ../config/zed/keymap.jsonc;
    };
    programs.zed-editor = {
      enable = true;
    };
  };
}
