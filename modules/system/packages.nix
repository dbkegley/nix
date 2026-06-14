{ ... }:
{
  arch.packageManager = {
    enable = true;
    dryRun = true;
    enableAUR = false;
    enableRemoval = false;

    packages = [
      { name = "tree"; }
    ];
  };
}
