{ lib, ... }:
{
  options.kegs = {
    isWork = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is a work environment";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = "david";
      description = "unix username";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = "David Kegley";
      description = "full name";
    };
    email = lib.mkOption {
      type = lib.types.str;
      default = "david@kegley.me";
      description = "personal email";
    };
    workEmail = lib.mkOption {
      type = lib.types.str;
      default = "david.kegley@posit.co";
      description = "work email";
    };
  };
}
