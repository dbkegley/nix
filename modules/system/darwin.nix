# nix-darwin system configuration (macOS system layer).
{ config, pkgs, ... }:
{
  # aarch64 (Apple Silicon).
  nixpkgs.hostPlatform = "aarch64-darwin";

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Required by nix-darwin. Bump only when the release notes say to.
  system.stateVersion = 5;

  # The primary interactive user; required for user-scoped defaults below.
  system.primaryUser = config.kegs.username;
  users.users.${config.kegs.username} = {
    name = config.kegs.username;
    home = config.kegs.homeDir;
  };

  # System-level Nix settings. Unlike ~/.config/nix/nix.conf (user, non-trusted),
  # these land in /etc/nix/nix.conf and ARE honoured by the daemon -- so
  # restricted settings like auto-optimise-store take effect here.
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    interval = {
      Weekday = 7;
      Hour = 3;
      Minute = 15;
    };
    options = "--delete-older-than 30d";
  };

  # Keyboard / keybindings.
  system.keyboard = {
    enableKeyMapping = true;
    # HID usage codes (0x700000000 + usage id).
    userKeyMapping = [
      # Caps Lock -> Escape
      {
        HIDKeyboardModifierMappingSrc = 30064771129; # Caps Lock
        HIDKeyboardModifierMappingDst = 30064771113; # Escape
      }
      # Swap Option and Command (both sides).
      {
        HIDKeyboardModifierMappingSrc = 30064771298; # Left Option
        HIDKeyboardModifierMappingDst = 30064771299; # Left Command
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771299; # Left Command
        HIDKeyboardModifierMappingDst = 30064771298; # Left Option
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771302; # Right Option
        HIDKeyboardModifierMappingDst = 30064771303; # Right Command
      }
      {
        HIDKeyboardModifierMappingSrc = 30064771303; # Right Command
        HIDKeyboardModifierMappingDst = 30064771302; # Right Option
      }
    ];
  };

  # Global keyboard behaviour (key repeat, press-and-hold).
  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
    ApplePressAndHoldEnabled = false;
  };

  # `open -a` is open-or-focus: it launches an app or focuses it if already running.
  services.skhd = {
    enable = true;
    skhdConfig = ''
      cmd - z      : open -a "Zed"
      cmd - b      : open -a "Firefox"
      cmd - p      : open -a "1Password"
      cmd - return : open -a "Ghostty"
    '';
  };
}
