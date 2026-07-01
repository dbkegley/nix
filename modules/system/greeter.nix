{ ... }:
let
  # https://github.com/apognu/tuigreet#theming
  theme = "border=magenta;text=cyan;prompt=green;time=red;action=blue;button=yellow;container=black;input=red";

  # tuigreet is provided by the `greetd-tuigreet` pacman package (binary: tuigreet).
  #   --time             show a clock
  #   --remember         remember the last logged-in username
  #   --remember-session remember the last selected session
  #   --asterisks        mask the password with asterisks
  #   --sessions         directory of Wayland session desktop entries to offer;
  #                      tuigreet lets you switch between them with F3.
  #   --theme            component=color;... styling (see `theme` above).
  greeter =
    "tuigreet --time --remember --remember-session --asterisks "
    + "--sessions /usr/share/wayland-sessions --cmd niri-session "
    + "--theme '${theme}'";
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
