{ ... }:
{
  config = {
    xdg.configFile = {
      "niri/config.kdl".source = ../../config/niri/config.kdl;
      "niri/scripts" = {
        source = ../../config/niri/scripts;
        recursive = true;
      };
    };
  };
}
