{ config, pkgs, ... }:
let cfg = config.kegs;
in {

  programs.git = {
    enable = true;
    userName = cfg.name;
    userEmail = if cfg.isWork then cfg.workEmail else cfg.email;
    extraConfig = {
      pull.rebase = true;
      commit.gpgsign = true;
      gpg = {
        format = "ssh";
        ssh.program = "op-ssh-sign";
      };
      user.signingkey =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICThloW6sHroEkrgK4oE6gHYmRWvpQ5AuLKBkHue1izb";
    };
  };
}
