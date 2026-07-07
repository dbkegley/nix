{ lib, ... }:
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
  };
}
