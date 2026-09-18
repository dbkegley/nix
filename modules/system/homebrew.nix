# Homebrew management for nix-darwin.
#
# Two layers work together here. nix-homebrew installs and owns the Homebrew
# prefix, because nix-darwin does not install Homebrew on its own. The nix-darwin
# `homebrew` module then declares the taps and formulas to install.
{ config, ... }:
{
  # Install and own Homebrew. On Apple Silicon the prefix is /opt/homebrew,
  # owned by this user. mutableTaps stays true by default, so Homebrew can clone
  # the tap declared below.
  nix-homebrew = {
    enable = true;
    user = config.kegs.username;
  };

  homebrew = {
    enable = true;

    onActivation = {
      # autoUpdate runs a full `brew update` on every switch, which is slow, so
      # it is off. upgrade keeps declared formulas current on each switch.
      # cleanup is "zap", so this file is the only source of truth for Homebrew:
      # any tap or formula not declared here is removed on the next switch.
      autoUpdate = false;
      upgrade = true;
      cleanup = "zap";
    };
  };
}
