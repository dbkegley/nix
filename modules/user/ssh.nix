{ lib, isDarwin, ... }:
{
  # services.ssh-agent uses a systemd user service; Linux only.
  services.ssh-agent.enable = lib.mkIf (!isDarwin) true;

  programs.ssh = {
    enable = true;
    package = null;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityAgent =
          if isDarwin then
            ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"''
          else
            "~/.1password/agent.sock";
      };
    };
  };
}
