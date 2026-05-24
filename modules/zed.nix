{ lib, config, pkgs, ... }:
let cfg = config.kegs;
in { config = { programs.zed-editor = { enable = true; }; }; }
