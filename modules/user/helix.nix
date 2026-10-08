{
  pkgs,
  inputs,
  config,
  ...
}:
let
  sharedLib = pkgs.stdenv.hostPlatform.extensions.sharedLibrary;
in
{

  config = {
    home.sessionVariables = {
      STEEL_HOME = "${config.home.homeDirectory}/.steel";
      STEEL_SEARCH_PATHS = "${config.xdg.configHome}/helix/plugins";
    };

    # Steel loads plugin libraries only from $STEEL_HOME/native.
    home.file.".steel/native/libhelix_file_watcher${sharedLib}".source =
      "${pkgs.helix-file-watcher}/lib/libhelix_file_watcher${sharedLib}";

    xdg.configFile = {
      "helix/themes/catppuccin_transparent.toml".source =
        ../../config/helix/themes/catppuccin_transparent.toml;

      # init.scm is a symlink so it is editable without a rebuild.
      "helix/init.scm".source =
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/config/helix/init.scm";

      # Plugin modules, found through STEEL_SEARCH_PATHS.
      "helix/plugins/helix-file-watcher".source = "${pkgs.helix-file-watcher}/share/helix-file-watcher";
    };

    programs.helix = {
      enable = true;
      # Steel plugin fork (mattwparas/helix, steel-event-system branch).
      package = inputs.helix-steel.packages.${pkgs.stdenv.hostPlatform.system}.default;
      settings = {
        theme = "catppuccin_transparent";
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

          lsp = {
            display-inlay-hints = true;
          };

          auto-save = {
            after-delay.enable = true;
          };

          indent-guides = {
            render = true;
            character = "┊";
            skip-levels = 1;
          };

          statusline = {
            mode.normal = "NORMAL";
            mode.insert = "INSERT";
            mode.select = "SELECT";
          };

          soft-wrap = {
            enable = true;
          };
        };

        keys.normal = {
          G.b = ":echo %sh{git blame -L %{cursor_line},+1 %{buffer_name}}"; # git blame
          G.d = [
            ":new"
            ":insert-output jj diff --name-only"
            "select_all"
            "split_selection_on_newline"
            "trim_selections"
            "goto_file"
          ];
          Y = "yank_to_clipboard";
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
        };
      };

      languages = {
        language = [
          {
            name = "go";
            auto-format = true;
            formatter.command = "goimports";
            language-servers = [
              "gopls"
              "golangci-lint-lsp"
            ];
          }
          {
            # uv tool install ty
            # uv tool install ruff
            # or install in .venv and start helix with: uv run hx ./
            # https://docs.astral.sh/ruff/editors/setup/#helix
            name = "python";
            auto-format = true;
            language-servers = [
              "ty"
              "ruff"
            ];
          }
          {
            name = "nix";
            auto-format = true;
            formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
          }
        ];

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

        language-server.pyright.config.python.analysis.typeCheckingMode = "basic";
      };

      ignores = [
        "!.github/"
        ".github/styles"
        "!.gitignore"
        "!.gitattributes"
      ];
    };
  };
}
