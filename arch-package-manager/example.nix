# Example configuration using pre-activation assertion for Arch packages
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Import the arch package manager module
    ./default.nix
  ];

  # Configure Arch package management
  arch.packageManager = {
    enable = true;

    # TODO: bootstrap yay with makepkg -si inside a nix build?
    # Enable AUR if you need packages from AUR
    # Note: requires yay to be installed manually first
    enableAUR = false;

    # Enable automatic removal of packages not in the list
    # Be careful with this - it will remove packages!
    enableRemoval = false;

    # Whether to continue activation if package install fails
    # Default false = fail fast and abort activation
    continueOnError = false;

    # Packages to manage
    packages = [
      # Basic system packages (from official repos)
      { name = "base-devel"; }
      { name = "git"; }
      { name = "vim"; }
      { name = "htop"; }
      { name = "tree"; }

      # Development tools
      { name = "docker"; }
      { name = "docker-compose"; }
      { name = "nodejs"; }
      { name = "npm"; }
      { name = "python"; }
      { name = "python-pip"; }

      # Databases
      { name = "postgresql"; }
      { name = "redis"; }
      { name = "sqlite"; }

      # Web servers
      { name = "nginx"; }
      {
        name = "apache";
        state = "absent";
      } # Ensure apache is NOT installed

      # AUR packages (requires enableAUR = true)
      # { name = "visual-studio-code-bin"; source = "yay"; }
      # { name = "spotify"; source = "yay"; }
      # { name = "slack-desktop"; source = "yay"; }
    ];
  };

  # System-manager configuration that depends on Arch packages
  environment.etc = {
    # Nginx configuration (nginx installed via pacman)
    "nginx/nginx.conf" =
      lib.mkIf (lib.elem "nginx" (map (p: p.name) config.arch.packageManager.packages))
        {
          text = ''
            user http;
            worker_processes auto;

            events {
              worker_connections 1024;
            }

            http {
              include mime.types;
              default_type application/octet-stream;

              server {
                listen 80;
                server_name localhost;

                location / {
                  root /srv/http;
                  index index.html;
                }
              }
            }
          '';
        };

    # PostgreSQL configuration
    "postgresql/postgresql.conf" =
      lib.mkIf (lib.elem "postgresql" (map (p: p.name) config.arch.packageManager.packages))
        {
          text = ''
            # Basic PostgreSQL configuration
            listen_addresses = 'localhost'
            port = 5432
            max_connections = 100
            shared_buffers = 128MB
          '';
        };
  };

  # Services that use Arch packages
  # These will only start if the pre-activation assertion succeeds
  systemd.services = {
    # Example: Ensure Docker is enabled
    docker-enabled =
      lib.mkIf (lib.elem "docker" (map (p: p.name) config.arch.packageManager.packages))
        {
          description = "Enable Docker daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.systemd}/bin/systemctl enable --now docker.service";
          };
        };

    # Example: Custom service that requires packages
    my-web-app =
      lib.mkIf
        (
          lib.elem "nginx" (map (p: p.name) config.arch.packageManager.packages)
          && lib.elem "postgresql" (map (p: p.name) config.arch.packageManager.packages)
        )
        {
          description = "My Web Application";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "postgresql.service"
          ];

          # This service will only run if nginx and postgresql were successfully installed
          # during the pre-activation phase
          serviceConfig = {
            Type = "simple";
            ExecStartPre = "${pkgs.bash}/bin/bash -c 'echo Starting web app with nginx and postgresql'";
            ExecStart = "${pkgs.bash}/bin/bash -c 'echo Web app running'";
            Restart = "always";
          };
        };
  };

  # Environment setup
  environment = {
    # Add helpful aliases
    shellAliases = {
      # Check package status
      "arch-status" = "arch-packages-status";
      "arch-check" = "arch-packages-check";
    };

    # System packages installed via Nix (not pacman)
    systemPackages = with pkgs; [
      # Nix-based tools that complement Arch packages
      jq
      curl
      wget
    ];
  };
}
