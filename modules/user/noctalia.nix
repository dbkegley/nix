{ config, ... }:
{
  # Use mkOutOfStoreSymlink to create editable symlinks to the config files
  # This allows you to edit the settings directly in Noctalia
  xdg.configFile = {
    "noctalia/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/config/zed/settings.jsonc";
  };
}
