inputs: pkgs: {
  # example = pkgs.callPackage ./example { };
  dms-cli = inputs.dms-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
  dgop = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
