# catch-all for random desktop-only configurations
{ ... }:
{
  config = {
    xdg.configFile = {
      "easyeffects/output/lappy_mctopface.json".source =
        ../config/easyeffects/output/lappy_mctopface.json;
    };
  };
}
