{ lib, config, pkgs, ... }: {
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$sudo"
        "$cmd_duration"
        "$line_break"
        "$jobs"
        "$time"
        "$status"
        "$os"
        "$shell"
        "$character"
      ];
    };
  };
}
