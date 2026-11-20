{ config, lib, pkgs, ... }:
let
  simpleEnglishVersion = "2.1.2";
  simpleEnglish = pkgs.fetchFromGitHub {
    owner = "AminBlg";
    repo = "SimpleEnglish";
    rev = "300432a9e4c473229a7049ab61b8ca2522d9214c";
    hash = "sha256-/2IZGQg5RaXsbB2a+anFlD6lLFIOuBzJxXCZVDNhW8I=";
  };
  blockVcsWrites = pkgs.writeShellScript "codex-block-vcs-writes" ''
    export PATH=${
      lib.makeBinPath [
        pkgs.jq
        pkgs.gnugrep
      ]
    }
    ${builtins.readFile ../../config/claude/hooks/block-vcs-writes.sh}
  '';
in
{
  services.arch-package-sync.packages = [
    { name = "openai-codex-bin"; }
    { name = "nodejs"; } # required for session hooks.
  ];

  # Codex's plugin cache expects the version entry to be a directory.
  home.file.".codex/plugins/cache/simple-english/simple-english/${simpleEnglishVersion}" = {
    source = simpleEnglish;
    recursive = true;
  };

  home.file.".codex/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/config/codex/config.toml";

  home.file.".codex/marketplaces/simple-english".source = simpleEnglish;
  home.file.".codex/hooks/block-vcs-writes".source = blockVcsWrites;
}
