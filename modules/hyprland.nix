{ lib, config, pkgs, ... }: {
  config = lib.mkIf config.kegs.isDesktop {

    home.file = {
      ".config/uwsm/env".source = ../config/uwsm/env;
      ".config/hypr/scripts" = {
        source = ../config/hypr/scripts;
        recursive = true;
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = null;
      portalPackage = null;
      # https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/#programs-dont-work-in-systemd-services-but-do-on-the-terminal
      systemd.variables = [ "--all" ];
      # https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.conf
      settings = {
        monitor = "eDP-1, 2880x1920@120, 0x0, 2";
        "$mod" = "SUPER";
        "$terminal" = "uwsm app -- ghostty";
        "$focus-or-start" = "$HOME/.config/hypr/scripts/focus-or-start.sh";
        "$electron_flags" =
          "--enable-features=UseOzonePlatform --ozone-platform=wayland";

        windowrule = [
          # everything on workspace 3 by default
          "workspace 3, class:^(.*)$"

          # 1password and spotify are hidden on special workspaces
          "workspace special:1password, class:^(.*1Password.*)$"
          "workspace special:spotify, class:^(.*spotify.*)$"

          "workspace 1, class:^(.*ghostty.*)$"
          "workspace 2, class:^(.*firefox.*)$"
        ];

        exec-once = [
          # enable easyeffects at startup
          # NOTE: apply this preset with: easyeffects -l lappy_mctopface
          # I tried to set it in the exec-once but that doesn't seem to work.
          "uwsm app -- easyeffects --gapplication-service"

          # enable polkit agent for interactive auth
          "uwsm app -- /usr/lib/polkit-kde-authentication-agent-1"

          # start clipboard history process
          "uwsm app -- wl-paste --type text --watch cliphist store"
          "uwsm app -- wl-paste --type image --watch cliphist store"

          # start 1password and ghostty automatically
          # TODO: how can we start 1password with the silent flag?
          "[workspace special:1password silent] uwsm app -- 1password $electron_flags"
          "uwsm app -- $terminal"

          # start Dank Material Shell
          "uwsm app -- dms run"
        ];
        bind = [
          "$mod, Q, exec, systemctl suspend"
          "$mod, W, exec, $HOME/.config/hypr/scripts/hide-or-kill.sh"
          "$mod SHIFT, F, fullscreen"
          "$mod, N, exec, $terminal"

          # allow ghostty's quickterminal on any workspace
          "ALT, SPACE, pass, class:^(.*ghostty.*)$"

          "$mod, SPACE, exec, dms ipc call spotlight toggle"
          "$mod, V, exec, dms ipc call clipboard toggle"
          "$mod, T, exec, dms ipc call processlist toggle"

          # tui-apps
          "$mod, F, exec, $terminal -e yazi"

          # apps
          "$mod, B, exec, $focus-or-start firefox firefox"
          "$mod, M, exec, $focus-or-start spotify-launcher spotify"
          "$mod, P, exec, $focus-or-start '1password $electron_flags' 1Password"
          "$mod, D, exec, $focus-or-start 'discord $electron_flags' discord"
          "$mod, O, exec, $focus-or-start 'obsidian $electron_flags' obsidian"

          # cycle active window focus
          "$mod, J, cyclenext"
          "$mod, K, cyclenext, prev"

          # move active window left/right
          "$mod SHIFT, H, movetoworkspace, -1"
          "$mod SHIFT, L, movetoworkspace, +1"

          # navigate workspace left/right
          "$mod, H, workspace, -1"
          "$mod, L, workspace, +1"

          # screenshot window, workspace, or selection
          "$mod, PRINT, exec, uwsm app -- hyprshot -m window"
          "$mod SHIFT, PRINT, exec, uwsm app -- hyprshot -m output"
          "$mod SHIFT, 4, exec, uwsm app -- hyprshot -m region"

          # media controls
          ", XF86AudioMicMute, exec, dms ipc call audio micmute"
          ", XF86AudioMute, exec, dms ipc call audio mute"
          ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 10"
          ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 10"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPrev, exec, playerctl previous"

          # screen brightness
          ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 5 ''"
          ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5 ''"
        ];
        input = {
          # change speed of keyboard repeat
          repeat_rate = 45;
          repeat_delay = 400;
          kb_options = "caps:escape";
        };
        # unscale XWayland
        xwayland = { force_zero_scaling = true; };
      };
    };
  };
}
