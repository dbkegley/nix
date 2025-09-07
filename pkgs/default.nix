inputs: pkgs: {
  # example = pkgs.callPackage ./example { };
  dms-cli = inputs.dms-cli.packages.${pkgs.system}.default;
  dgop = inputs.dgop.packages.${pkgs.system}.default;
}
