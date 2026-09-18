{ lib, isDarwin, ... }:
{
  config = {
    programs.ghostty = {
      enable = true;
      # use system ghostty
      # https://github.com/ghostty-org/ghostty/issues/2025
      package = null;
      systemd.enable = false;
      enableZshIntegration = true;
      settings = {
        theme = "Catppuccin Frappe";
        font-family = "JetBrainsMono Nerd Font Mono";
        background-opacity = 0.9;
        background-blur = true;
        background-blur-radius = 20;
        background = "#11111b";
        window-decoration = true;
        window-padding-balance = true;
        mouse-hide-while-typing = true;
        mouse-scroll-multiplier = 2;
        keybind = [
          "alt+t=new_tab"
          "alt+w=close_surface" # close the active tab or split
          "alt+v=new_split:right"
          "alt+shift+v=new_split:down"
          "alt+h=previous_tab"
          "alt+l=next_tab"
          "alt+p=toggle_command_palette"
        ]
        # Global quick terminal works on macOS. On niri, `global:` keybinds never
        # fire because niri does not implement org.freedesktop.portal.GlobalShortcuts,
        # so this binding is darwin-only.
        # https://github.com/niri-wm/niri/discussions/2775
        ++ lib.optional isDarwin "global:alt+space=toggle_quick_terminal";
      };
    };
  };
}
