{
  config,
  lib,
  pkgs,
  ...
}:
{
  config = {
    home-manager.users.${config.kegs-dev.user.name} = {
      programs.git = {
        enable = true;

        # Primary email: personal on Darwin, work on Linux
        # userEmail =
        #   if config.kegs-dev.isDarwin then config.kegs-dev.user.email else config.kegs-dev.user.workEmail;
        userEmail = config.kegs-dev.user.email;
        userName = config.kegs-dev.user.fullName;

        includes = lib.flatten [
        #   # Always include secretz configuration on both platforms
        #   {
        #     condition = "gitdir:${config.kegs-dev.user.homeDirectory}/projects/secretz/";
        #     contents = {
        #       user = {
        #         name = config.kegs-dev.user.fullName;
        #         email = "";
        #         signingKey = config.kegs-dev.user.gpgKey;
        #       };
        #       commit.gpgSign = true;
        #       core.sshCommand =
        #         if config.kegs-dev.isLinux then "ssh -i ~/.ssh/id_ed25519" else "ssh -i ~/.ssh/todo_key";
        #       gpg.program = if config.kegs-dev.isLinux then "${pkgs.gnupg}/bin/gpg2" else "/opt/homebrew/bin/gpg";
        #     };
        #   }

          # Darwin
          (lib.optionals config.kegs-dev.isDarwin [
            {
              condition = "gitdir:${config.kegs-dev.user.homeDirectory}/code/";
              contents = {
                user = {
                  name = config.kegs-dev.user.fullName;
                  email = config.kegs-dev.user.email;
                  signingKey = config.kegs-dev.user.gpgKey;
                };
                commit.gpgSign = true;
                core.sshCommand = "ssh -i ~/.ssh/id_rsa";
                gpg.program = "/opt/homebrew/bin/gpg";
              };
            }
          ])

          # Linux
          (lib.optionals config.kegs-dev.isLinux [
            {
              condition = "gitdir:${config.kegs-dev.user.homeDirectory}/code/";
              contents = {
                user = {
                  name = config.kegs-dev.user.fullName;
                  email = config.kegs-dev.user.email;
                  signingKey = config.kegs-dev.user.gpgKey;
                };
                commit.gpgSign = true;
                core.sshCommand = "ssh -i ~/.ssh/id_rsa";
                gpg.program = "${pkgs.gnupg}/bin/gpg2";
              };
            }
          ])
        ];

        # Primary configuration (work on Darwin, personal on Linux)
        extraConfig = {
          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          # pull.rebase = true;
          core.sshCommand = "ssh -i ~/.ssh/id_rsa";

          safe.directory = "${config.kegs-dev.user.homeDirectory}/nix";
          # safe.directory = "${config.kegs-dev.user.homeDirectory}/projects/personal/nixos-config";

          user.signingkey = config.kegs-dev.user.gpgKey;
          commit.gpgsign = true;
          gpg.program = if config.kegs-dev.isLinux then "${pkgs.gnupg}/bin/gpg2" else "/opt/homebrew/bin/gpg";
        };
      };

      # programs.lazygit = {
      #   enable = true;
      #   settings = {
      #     git = {
      #       commit = {
      #         signOff = true;
      #       };
      #     };
      #   };
      # };

      programs.gh = {
        enable = true;
        settings = {
          editor = "hx";
          git_protocol = "ssh";
        };
      };
    };
  };
}
