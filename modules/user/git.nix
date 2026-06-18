{ config, ... }:
{

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = config.kegs.name;
        email = config.kegs.email;
        signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICThloW6sHroEkrgK4oE6gHYmRWvpQ5AuLKBkHue1izb";
      };
      pull.rebase = true;
      commit.gpgsign = true;
      gpg = {
        format = "ssh";
        ssh.program = "/opt/1Password/op-ssh-sign";
      };
    };
  };
}
