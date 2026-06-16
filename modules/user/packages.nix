{ pkgs, ... }:
{
  services.arch-package-sync = {
    enable = true;

    # These packages are installed as system packages
    # via pacman/yay. Run arch-package-sync to install them
    # after activating the home-manager flake.
    packages = [
      # { name = "tree"; }
      # {
      #   name = "cowsay";
      #   state = "absent";
      # }
    ];
  };

  home.packages = with pkgs.unstable; [
    # bootstrap
    pkgs.system-manager
    pkgs.yay
    jq

    gh
    fzf
    just
    yazi
    nil
    nixd
    nixfmt
    go_1_24
    golangci-lint
    rustup
    uv
    kubectl
    claude-code
  ];
}
