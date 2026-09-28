# Claude Code CLI via Anthropic's native installer, which updates itself in the
# background (https://code.claude.com/docs/en/setup).
#
# Nix does not own the binary: a read-only nix store copy could never update
# itself. Instead, activation runs the official installer once, when
# ~/.local/bin/claude is missing, and leaves Claude Code alone after that. The
# installer needs no root and verifies SHA-256 checksums before it runs
# anything. ~/.local/bin is already on PATH (home.sessionPath in home.nix).
{ lib, pkgs, ... }:
{
  home.activation.installClaudeCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.local/bin/claude" ]; then
      verboseEcho "Installing Claude Code with the native installer"
      # The installer refuses to run when it sees sudo variables, to avoid
      # installing into root's home. Activation already runs as this user
      # with HOME set, so those variables are cleared for the installer.
      if ! run env -u SUDO_USER -u SUDO_UID -u SUDO_GID -u SUDO_COMMAND \
        PATH="${
          lib.makeBinPath [
            pkgs.curl
            pkgs.bash
            pkgs.coreutils
          ]
        }:/usr/bin:/bin" \
        bash -c 'curl -fsSL https://claude.ai/install.sh | bash'; then
        warnEcho "Claude Code install failed. Run: curl -fsSL https://claude.ai/install.sh | bash"
      fi
    fi
  '';
}
