# Mitos editor (`ms`), a fork of helix. This mirrors the helix configuration
# in helix.nix. Mitos rejects unknown editor settings, so the names below
# follow the mitos reference:
# https://github.com/mitos-editor/mitos/blob/main/book/src/configuration.md
{
  pkgs,
  inputs,
  ...
}:
let
  toml = pkgs.formats.toml { };
in
{
  config = {
    home.packages = [
      inputs.mitos.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    # `hx` opens mitos in interactive zsh. Helix stays installed, so run
    # `command hx` (or `\hx`) to open helix.
    programs.zsh.shellAliases.hx = "ms";

    xdg.configFile = {
      # The helix theme file also works in mitos, which bundles catppuccin_frappe.
      "mitos/themes/catppuccin_transparent.toml".source =
        ../../config/helix/themes/catppuccin_transparent.toml;

      "mitos/config.toml".source = toml.generate "mitos-config.toml" {
        theme = "catppuccin_transparent";
        editor = {
          border-style = "rounded";

          completion = {
            trigger-delay = 100;
            replace = true;
          };

          files.save = {
            trim-trailing-whitespace = true;
            trim-final-newlines = true;
          };

          files.auto-save = {
            after-delay.enable = true;
          };

          lsp.inlay-hints.enable = true;

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
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ];
        };

        # Applies to every picker (file, buffer, git, file explorer, and others).
        keys.picker = {
          A-j = "move_down";
          A-k = "move_up";
          A-J = "preview_scroll_down";
          A-K = "preview_scroll_up";
        };

        # Completion and code action menus.
        keys.menu = {
          A-j = "move_down";
          A-k = "move_up";
        };
      };

      "mitos/languages.toml".source = toml.generate "mitos-languages.toml" {
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

      "mitos/ignore".text = ''
        !.github/
        .github/styles
        !.gitignore
        !.gitattributes
      '';
    };
  };
}
