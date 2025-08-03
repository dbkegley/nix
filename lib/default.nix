{ lib, pkgs, ... }:
{
  kegs-dev = {
    isDarwin = pkgs.stdenv.isDarwin;
    isLinux = pkgs.stdenv.isLinux;
  };
}
