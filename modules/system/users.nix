{ config, ... }:
{
  config = {
    users.users.${config.kegs.username} = {
      isNormalUser = true;
      description = config.kegs.name;
      home = "/home/${config.kegs.username}";
      extraGroups = [
        "wheel"
      ];

      # TODO: configure /etc/shells and set user.shell here
      # shell = pkgs.zsh;
    };

    # Ensure zsh is available system-wide
    # environment.systemPackages = with pkgs; [
    #   zsh
    # ];
  };
}
