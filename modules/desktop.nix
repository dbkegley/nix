# catch-all for random desktop-only configurations
{
  lib,
  config,
  ...
}:
{
  config = lib.mkIf config.kegs.isDesktop {
    home.file = {
      ".config/easyeffects/output/lappy_mctopface.json".source =
        ../config/easyeffects/output/lappy_mctopface.json;
    };
  };
}
