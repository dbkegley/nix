{ config, pkgs, ... }: {
  # Use mkOutOfStoreSymlink to create editable symlinks to the config files
  # This allows you to edit the settings directly in Zed or any editor
  xdg.configFile = {
    "zed/settings.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix/config/zed/settings.jsonc";

    "zed/keymap.json".source = config.lib.file.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/nix/config/zed/keymap.jsonc";
  };
}
