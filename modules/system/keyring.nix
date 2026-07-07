{ ... }:
{
  config = {
    # Auto-start and auto-unlock the GNOME keyring at login so the Secret
    # Service (org.freedesktop.secrets) is available to apps like 1Password.
    #
    # greetd reads /etc/pam.d/greetd, per the Arch wiki:
    # https://wiki.archlinux.org/title/GNOME/Keyring
    #
    #   auth    optional  pam_gnome_keyring.so              -> captures login pw
    #   session optional  pam_gnome_keyring.so auto_start   -> starts + unlocks
    #
    # Auto-unlock requires the keyring password to match the login password.
    #
    # Optional: to keep the keyring password following your login password when
    # you change it, also add `password optional pam_gnome_keyring.so` to the
    # end of /etc/pam.d/passwd.
    environment.etc."pam.d/greetd" = {
      replaceExisting = true;
      text = ''
        #%PAM-1.0

        auth       required     pam_securetty.so
        auth       requisite    pam_nologin.so
        auth       include      system-local-login
        auth       optional     pam_gnome_keyring.so
        account    include      system-local-login
        session    include      system-local-login
        session    required     pam_systemd.so
        session    optional     pam_gnome_keyring.so auto_start
      '';
    };
  };
}
