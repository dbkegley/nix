{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    kegs-dev.isLinux = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the host is a Linux system.";
    };

    kegs-dev.isDarwin = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      description = "Whether the host is a Darwin system.";
    };

    kegs-dev.font = lib.mkOption {
      type = lib.types.str;
      description = "Default font for the system.";
    };

    kegs-dev.colorScheme.flavor = lib.mkOption {
      type = lib.types.str;
      description = "Default flavor for the color scheme.";
      default = "macchiato";
    };

    kegs-dev.colorScheme.accent = lib.mkOption {
      type = lib.types.str;
      description = "Default accent for the color scheme.";
      default = "peach";
    };

    # System version option
    kegs-dev.stateVersion = lib.mkOption {
      type = lib.types.str;
      example = "23.11";
      description = "NixOS state version";
    };

    kegs-dev.timeZone = lib.mkOption {
      type = lib.types.str;
      default = "America/New_York";
      description = "Time zone for the system.";
    };

    # Impermanence options
    # kegs-dev.persistence = {
    #   enable = lib.mkEnableOption "Enable persistence/impermanence";
      
    #   dataPrefix = lib.mkOption {
    #     type = lib.types.str;
    #     default = "/data";
    #     description = "Prefix for persistent data storage";
    #   };
      
    #   cachePrefix = lib.mkOption {
    #     type = lib.types.str;
    #     default = "/cache";
    #     description = "Prefix for persistent cache storage";
    #   };
    # };

    # Stub for core namespace so that shared modules referencing
    # `kegs-dev.core.*` options are accepted when running on platforms
    # that do not import the Linux-specific ZFS module.
    kegs-dev.core = lib.mkOption {
      type = lib.types.submodule {};
      default = {};
      description = "Namespace for Linux-only core settings. Empty on Darwin.";
    };
  };

  config = {
    kegs-dev.isLinux = lib.kegs-dev.isLinux;
    kegs-dev.isDarwin = lib.kegs-dev.isDarwin;
    kegs-dev.font = if lib.kegs-dev.isDarwin then "0xProto" else "0xProto Nerd Font";
    
    # Enable persistence by default only on Linux systems
    # This can be overridden per-machine as needed
    # kegs-dev.persistence.enable = lib.mkDefault config.kegs-dev.isLinux;
  };
}
