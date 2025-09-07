{ config, pkgs, ... }: {
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    package = null;
    addKeysToAgent = "yes";
    matchBlocks = { "*" = { identityAgent = "~/.1password/agent.sock"; }; };
  };
}
