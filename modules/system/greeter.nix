{ ... }:
{
  config = {
    environment.etc."greetd/config.toml" = {
      replaceExisting = true;
      text = ''
        [terminal]
        vt = 1

        [default_session]
        command = "/usr/bin/noctalia-greeter-session -- --session niri"
        user = "greeter"
      '';
    };

    # enable greetd using the systemd service that ships with Arch
    environment.etc."systemd/system/display-manager.service" = {
      source = "/usr/lib/systemd/system/greetd.service";
      replaceExisting = true;
    };
  };
}
