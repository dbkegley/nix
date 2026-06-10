# This module configures both system-manager and home-manager together
{
  config,
  pkgs,
  ...
}:

{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";

    # Nixpkgs configuration
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
      # NOTE: overlays are defined in the flake and passed through
    };

    nix.enable = true;

    # create users on activation
    services.userborn.enable = true;

    # System packages that should be available system-wide
    environment.systemPackages = with pkgs; [
      # Core utilities
      git
      curl
      wget
      fzf
      jq
      just
      kubectl
      yazi

      # Language servers and formatters
      nil
      nixd
      nixfmt

      # Programming languages and tools
      go_1_24
      golangci-lint
      rustup
      uv

      # User applications (from unstable)
      pkgs.unstable.claude-code
    ];

    # System services
    systemd.services = {
      # Add system services here
    };

    # /etc files
    environment.etc = {
      "nix/nix.conf".text = ''
        experimental-features = nix-command flakes
        auto-optimise-store = true
        warn-dirty = false
      '';
    };

    # Configure users
    users.groups.${config.kegs.username}.gid = 1000;
    users.users.${config.kegs.username} = {
      isNormalUser = true;
      uid = 1000;
      group = config.kegs.username;
      home = "/home/${config.kegs.username}";
      createHome = true;
      extraGroups = [ "wheel" ];
    };

    # Home-manager configuration
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";

      users.${config.kegs.username} =
        { ... }:
        {
          config.kegs = config.kegs;

          imports = [ ../home-manager/home.nix ];
        };
    };
  };
}
