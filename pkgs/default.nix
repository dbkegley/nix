inputs: pkgs: {
  # example = pkgs.callPackage ./example { };

  r-rig = pkgs.callPackage ./r-rig { };
  helix-file-watcher = pkgs.callPackage ./helix-file-watcher { inherit inputs; };
}
