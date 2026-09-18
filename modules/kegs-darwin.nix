# Darwin identity overrides for the kegs options. Imported into BOTH the
# nix-darwin system config and the home-manager config so they share one source.
{ config, ... }:
{
  kegs.email = "david.kegley@posit.co";
  kegs.homeDir = "/Users/${config.kegs.username}";
}
