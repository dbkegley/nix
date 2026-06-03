{ config, pkgs, ... }: {
  home.file = {
    ".config/zed/keymap.json".source = ../config/zed/keymap.jsonc;
    ".config/zed/settings.json".source = ../config/zed/settings.jsonc;
  };
  # programs.zed-editor = {
  #   enable = true;

  #   # use system zed
  #   # TODO: Why doesn't this allow null?
  #   # package = null;

  #   # TODO: Figure out mutable settings
  #   # https://github.com/nix-community/home-manager/issues/6835
  #   #
  #   # reference an out-of-nix symlink so we can use the visual editor for the settings/keymap?
  #   # xdg.configFile."zed/settings.json".source =
  #   #   config.lib.file.mkOutOfStoreSymlink /path/to/your/dotfiles/zed/settings.json;
  #   # or
  #   # mutableUserSettings = true; ?
  # };
}
