{ ... }:
{
  services.ssh-agent.enable = true;
  programs.ssh = {
    enable = true;
    package = null;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
