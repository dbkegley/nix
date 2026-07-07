{ ... }:
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
          "alt+j=goto_split:previous"
          "alt+k=goto_split:next"
          "alt+p=toggle_command_palette"
          # Quick terminal global keybind disabled: niri does not implement the
          # org.freedesktop.portal.GlobalShortcuts protocol, so ghostty's `global:`
          # keybinds never fire while ghostty is unfocused. (It worked under Hyprland
          # via its key-forwarding `pass` dispatcher, which niri has no equivalent for.)
          # https://github.com/niri-wm/niri/discussions/2775
          # "global:alt+space=toggle_quick_terminal"
        ];
      };
    };
  };
}
