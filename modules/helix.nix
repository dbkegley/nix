{ lib, config, pkgs, ... }:
let cfg = config.kegs;
in {

  config = {
    home.file = lib.mkIf cfg.isDesktop {
      ".config/helix/themes/catppuccin_transparent.toml".source =
        ../config/helix/themes/catppuccin_transparent.toml;
    };

    programs.helix = {
      enable = true;
      settings = {
        theme = if cfg.isDesktop then
          "catppuccin_transparent"
        else
          "catppuccin_frappe";
        editor = {
          completion-timeout = 100;
          completion-replace = true;
          popup-border = "all";

          # use :set ... false to temporarily disable in helix
          trim-trailing-whitespace = true;
          trim-final-newlines = true;

          # end-of-line-diagnostics = "hint"
          # inline-diagnostics = {
          #   cursor-line = "warning" # show warnings and errors on the cursorline inline
          # }

          lsp = { display-inlay-hints = true; };

          auto-save = { after-delay.enable = true; };

          indent-guides = {
            render = true;
            character = "⸽";
            skip-levels = 1;
          };

          statusline = {
            mode.normal = "NORMAL";
            mode.insert = "INSERT";
            mode.select = "SELECT";
          };

          soft-wrap = { enable = true; };
        };

        keys.normal = {
          G.b =
            ":echo %sh{git blame -L %{cursor_line},+1 %{buffer_name}}"; # git blame
          space.w = ":w";
          space.q = ":q";
          esc = [ "collapse_selection" "keep_primary_selection" ];
        };
      };

      languages = {
        language = [
          {
            name = "go";
            auto-format = true;
            formatter.command = "goimports";
            language-servers = [ "gopls" "golangci-lint-lsp" ];
          }
          {
            # uv tool install pyright
            # uv tool install ruff
            # or install in .venv and start helix with: uv run hx ./
            # https://docs.astral.sh/ruff/editors/setup/#helix
            name = "python";
            auto-format = true;
            language-servers = [ "pyright" "ruff" ];
          }
          {
            name = "nix";
            auto-format = true;
            formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          }
        ];

        language-server.ruff = {
          command = "ruff";
          args = [ "server" ];
        };

        language-server.rust-analyzer.config.check.command = "clippy";

        # https://golangci-lint.run/welcome/install/#local-installation
        # https://github.com/golang/vscode-go/issues/3732#issuecomment-2758960259
        language-server.golangci-lint-lsp.config.command = [
          "golangci-lint"
          "run"
          "--output.json.path=stdout"
          "--show-stats=false"
          "--issues-exit-code=1"
        ];

        language-server.pyright.config.python.analysis.typeCheckingMode =
          "basic";
      };

      ignores =
        [ "!.github/" ".github/styles" "!.gitignore" "!.gitattributes" ];
    };
  };
}
