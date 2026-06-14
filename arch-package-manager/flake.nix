{
  description = "Declarative Arch Linux package management for Nix/system-manager";

  outputs =
    { ... }:
    {
      # Main module export - receives pkgs from the importing system
      nixosModules.default = ./default.nix;

      # Documentation and examples
      lib = {
        # Example configuration showing usage
        exampleConfig = {
          arch.packageManager = {
            enable = true;
            enableAUR = false;
            enableRemoval = false;

            packages = [
              # System packages
              { name = "base-devel"; }
              { name = "git"; }
              { name = "htop"; }

              # Development tools
              { name = "docker"; }
              { name = "postgresql"; }
              { name = "redis"; }

              # AUR packages (requires enableAUR = true)
              # { name = "visual-studio-code-bin"; source = "yay"; }
            ];
          };
        };

        # Usage example for documentation
        usageExample = ''
          # In your flake.nix:
          {
            inputs = {
              nixpkgs.url = "github:nixos/nixpkgs";
              system-manager.url = "github:numtide/system-manager";
              arch-package-manager.url = "github:yourusername/arch-package-manager";
            };

            outputs = { self, nixpkgs, system-manager, arch-package-manager, ... }:
            {
              systemConfigs.default = system-manager.lib.makeSystemConfig {
                modules = [
                  arch-package-manager.nixosModules.default
                  {
                    arch.packageManager = {
                      enable = true;
                      packages = [
                        { name = "postgresql"; }
                        { name = "nginx"; }
                      ];
                    };
                  }
                ];
              };
            };
          }
        '';
      };
    };
}
