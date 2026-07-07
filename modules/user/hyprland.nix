{ ... }:
{
  config = {
    # Manage Hyprland and UWSM config files directly
    xdg.configFile = {
      "hypr/hyprland.lua".source = ../../config/hypr/hyprland.lua;
      "hypr/scripts" = {
        source = ../../config/hypr/scripts;
        recursive = true;
      };
      "uwsm/env".source = ../../config/uwsm/env;
    };
  };
}
