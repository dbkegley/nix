{ lib, config, ... }:
{
  options.kegs = {
    username = lib.mkOption {
      type = lib.types.str;
      default = "david";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "David Kegley";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "david@kegley.me";
    };
    homeDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.kegs.username}";
    };
  };
}
