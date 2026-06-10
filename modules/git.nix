{ config, ... }:
{

  programs.git = {
    enable = true;
    userName = config.kegs.name;
    userEmail = if config.kegs.isWork then config.kegs.workEmail else config.kegs.email;
    extraConfig = {
      pull.rebase = true;
      commit.gpgsign = true;
      gpg = {
        format = "ssh";
        ssh.program = "op-ssh-sign";
      };
      user.signingkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICThloW6sHroEkrgK4oE6gHYmRWvpQ5AuLKBkHue1izb";
    };
  };
}
