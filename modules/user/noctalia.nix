{ config, pkgs, ... }:
{
  xdg.configFile."noctalia/config.toml".source = (pkgs.formats.toml { }).generate "noctalia.toml" {
    shell = {
      font_family = "Adwaita Mono";
      telemetry_enabled = false;
      setup_wizard_enabled = false;
    };

    theme = {
      mode = "dark";
      source = "wallpaper";
      wallpaper_scheme = "m3-tonal-spot";
      sync_color_scheme = true;
    };

    wallpaper = {
      directory = "${config.home.homeDirectory}/nix/wallpapers";
      fill_mode = "crop";
      fill_color = "#000000";
      transition = [ "fade" "disc" "stripes" "wipe" "pixel" "honeycomb" ];
      transition_duration = 1500;
      edge_smoothness = 0.05;
      transition_on_startup = true;
      automation = {
        enabled = true;
        interval_seconds = 1800;
        order = "random";
      };
    };

    lockscreen.lock_before_suspend = true;

    bar.default = {
      position = "top";
      background_opacity = 0.0;
      capsule = true;
      capsule_opacity = 0.5;
      font_scale = 1.25;
      margin_ends = 4;
      margin_edge = 4;
      padding = 5;
      widget_spacing = 10;
      start = [ "control-center" "launcher" "clock" "cpu" "cpu-temperature" "ram" ];
      center = [ "privacy" "workspaces" "media" ];
      end = [
        "audio_visualizer"
        "tray"
        "notifications"
        "battery"
        "network"
        "bluetooth"
        "volume"
        "brightness"
      ];
    };

    widget = {
      clock = {
        format = "{:%-I:%M%p // %a, %b %d}";
        tooltip_format = "{:%-I:%M %p // %a, %b %d}";
      };
      cpu = { type = "sysmon"; stat = "cpu_usage"; };
      cpu-temperature = { type = "sysmon"; stat = "cpu_temp"; };
      ram = { type = "sysmon"; stat = "ram_used"; };
    };
  };
}
