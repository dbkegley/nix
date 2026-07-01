{ ... }:
let
  greeter = "/usr/bin/noctalia-greeter-session -- --session niri";
in
{
  config = {
    environment.etc."greetd/config.toml" = {
      replaceExisting = true;
      text = ''
        [terminal]
        vt = 1

        [default_session]
        command = "${greeter}"
        user = "greeter"
      '';
    };

    systemd.services.greetd = {
      enable = true;
      description = "greetd login manager";

      after = [
        "systemd-user-sessions.service"
        "getty@tty1.service"
      ];
      wants = [ "systemd-user-sessions.service" ];
      conflicts = [ "getty@tty1.service" ];
      wantedBy = [ "graphical.target" ];

      serviceConfig = {
        ExecStart = "/usr/bin/greetd";
        Restart = "always";
        RestartSec = 1;
        TimeoutStopSec = 30;
        KillMode = "mixed";

        Type = "idle";
        StandardInput = "tty";
        StandardOutput = "tty";
        TTYPath = "/dev/tty1";
        TTYReset = true;
        TTYVHangup = true;
        TTYVTDisallocate = true;
      };
    };
  };
}
