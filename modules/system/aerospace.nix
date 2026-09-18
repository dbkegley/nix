# AeroSpace: an i3-like tiling window manager for macOS with its own virtual
# workspaces. nix-darwin installs it and runs it as a launchd user agent at
# login with the config generated from `settings`.
#
# AeroSpace workspaces are not macOS Spaces. Keep a single macOS desktop and do
# not use Dock > Options > Assign To, or the two systems fight over windows.
#
# All bindings use `cmd`, so `alt` stays free for apps. With the Option/Command
# swap in darwin.nix, `cmd` is the physical Option key. AeroSpace takes these
# keys before apps see them, so each binding replaces that Cmd shortcut in
# every app.
#
# Grant Accessibility access on first launch (System Settings > Privacy &
# Security > Accessibility).
#
# Monitors: workspace 1 (Slack) is pinned to the built-in display, and every
# other workspace to the macOS main display. With an external monitor, set it as
# the main display once (System Settings > Displays > Use as > Main display);
# macOS remembers that per monitor.
#
# AeroSpace's bindings win over app shortcuts, but not over macOS system
# shortcuts (System Settings > Keyboard > Keyboard Shortcuts). Do not assign
# those to the Cmd keys bound here.
{ lib, ... }:
let
  workspaces = map toString (lib.range 1 5);
in
{
  services.aerospace = {
    enable = true;
    settings = {
      # config-version 2 makes persistence explicit: only the workspaces listed
      # in persistent-workspaces stay alive when empty. (Version 1 inferred them
      # from `workspace N` bindings, so removing those made empty workspaces
      # disappear.)
      config-version = 2;
      persistent-workspaces = workspaces;

      mode.main.binding = {
        # h/l carry the focused window to the previous/next workspace on the
        # focused monitor, empty or not, and follow it, so repeated presses keep
        # carrying it.
        cmd-shift-h = "move-node-to-workspace --wrap-around --focus-follows-window prev";
        cmd-shift-l = "move-node-to-workspace --wrap-around --focus-follows-window next";
        # j/k move the focused window one position forward/back in window order
        # (the same order cmd-j cycles) by swapping it with its neighbor. The
        # layout is unchanged, and focus stays on the moved window. No
        # wrap-around: at the end it stops instead of swapping with the first.
        cmd-shift-j = "swap dfs-next";
        cmd-shift-k = "swap dfs-prev";

        cmd-shift-slash = "layout tiles horizontal vertical";
        cmd-shift-comma = "layout accordion horizontal vertical";
        cmd-shift-space = "layout floating tiling";
        cmd-shift-f = "fullscreen";

        cmd-shift-minus = "resize smart -50";
        cmd-shift-equal = "resize smart +50";

        cmd-shift-tab = "workspace-back-and-forth";

        # App hotkeys (formerly skhd). `open -a` launches the app or focuses it
        # if it is already running, and AeroSpace then switches to the app's
        # workspace.
        cmd-b = "exec-and-forget open -a Firefox";
        cmd-p = "exec-and-forget open -a 1Password";
        cmd-s = "exec-and-forget open -a Slack";
        cmd-semicolon = "exec-and-forget open -a Ghostty";
        cmd-quote = "exec-and-forget open -a Claude";

        cmd-m = "exec-and-forget open -a 'Mission Control'";

        # cmd-j cycles the windows of the current monitor's workspace in tree
        # order (dfs), so stacked windows are included, and wraps from the last
        # window to the first.
        cmd-j = "focus --boundaries-action wrap-around-the-workspace dfs-next";
        # cmd-k cycles between monitors, focusing each monitor's most recently
        # used window.
        cmd-k = "focus-monitor --wrap-around next";

        # Previous / next workspace on the focused monitor, empty or not,
        # wrapping at the ends. These replace macOS Cmd+H (hide app) and apps'
        # Cmd+L.
        cmd-h = "workspace --wrap-around prev";
        cmd-l = "workspace --wrap-around next";
      };

      # "built-in" is a case-insensitive regex matched against the monitor name
      # ("Built-in Retina Display"). "main" is the display set as Main in System
      # Settings > Displays.
      workspace-to-monitor-force-assignment = {
        "1" = "built-in";
      }
      // lib.genAttrs (lib.remove "1" workspaces) (_: "main");

      # New windows of these apps go to a fixed workspace. The rules also apply
      # to windows that already exist when AeroSpace starts. The first matching
      # rule wins.
      on-window-detected = [
        {
          "if".app-id = "com.tinyspeck.slackmacgap";
          run = "move-node-to-workspace 1";
        }
        # Ghostty uses macOS native tabs, which macOS reports as separate
        # windows, so each new tab would split the column. `layout tiling` did
        # not help; floating is Ghostty's documented fallback, and floating
        # windows are never split. Ghostty starts maximized (ghostty.nix), so it
        # still fills its workspace.
        # https://ghostty.org/docs/help/macos-tiling-wms
        # https://github.com/nikitabobko/AeroSpace/issues/68
        {
          "if".app-id = "com.mitchellh.ghostty";
          run = [
            "layout floating"
            "move-node-to-workspace 2"
          ];
        }
        {
          "if".app-id = "org.mozilla.firefox";
          run = "move-node-to-workspace 3";
        }
        {
          "if".app-id = "com.anthropic.claudefordesktop";
          run = "move-node-to-workspace 4";
        }
        # Keep the laptop screen for Slack only: any other window that opens
        # while Slack's workspace is focused goes to workspace 5.
        {
          "if".workspace = "1";
          run = "move-node-to-workspace 5";
        }
      ];
    };
  };

  # AeroSpace hides windows on other workspaces by parking them in a screen
  # corner. Grouping by app keeps Mission Control readable instead of showing
  # those windows as tiny slivers.
  system.defaults.dock.expose-group-apps = true;
}
