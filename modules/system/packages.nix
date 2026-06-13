{ ... }:
{
  arch.packageManager = {
    enable = true;
    dryRun = true;
    enableAUR = false;
    enableRemoval = false;
    continueOnError = false;

    packages = [
      { name = "tree"; }
    ];
  };
}
