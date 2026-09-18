{ config, ... }:
{
  home.file.".claude/settings.json" = {
    # mkOutOfStoreSymlink keeps the file writable: Claude saves settings changes
    # back to it, and those edits land in this repo instead of failing on a
    # read-only nix store file.
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/config/claude/settings.json";
  };

  home.file.".claude/hooks/block-vcs-writes.sh" = {
    source = ../../config/claude/hooks/block-vcs-writes.sh;
    executable = true;
  };
}
