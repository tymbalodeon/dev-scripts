{
  inputs = {
    nixpkgs = {url = "github:nixos/nixpkgs/nixos-unstable";};
    nushell-syntax = {
      flake = false;
      owner = "stevenxxiu";
      repo = "sublime_text_nushell";
      type = "github";
    };
  };

  outputs = {
    nixpkgs,
    nushell-syntax,
    ...
  }: let
    supportedSystems = [
      "x86_64-darwin"
      "x86_64-linux"
    ];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems
      (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          ansible-language-server
          bat
          cocogitto
          deadnix
          eza
          flake-checker
          fzf
          gh
          git-cliff
          just
          lychee
          markdown-oxide
          marksman
          nil
          nodePackages.pnpm
          nodePackages.prettier
          nushell
          pdm
          pre-commit
          python311
          python311Packages.pre-commit-hooks
          python312Packages.pre-commit-hooks
          ripgrep
          statix
          stylelint
          taplo
          tokei
          vscode-langservers-extracted
          yaml-language-server
          yamlfmt
        ];

        shellHook = ''
          nushell_syntax="${nushell-syntax}/nushell.sublime-syntax"
          bat_config_dir=".config/bat"
          bat_syntax_dir="''${bat_config_dir}/syntaxes"
          bat_nushell_syntax="''${bat_syntax_dir}/nushell.sublime-syntax"

          mkdir -p "''${bat_syntax_dir}"
          cp "''${nushell_syntax}" "''${bat_nushell_syntax}"
          bat cache --build --source "''${bat_config_dir}"

          pre-commit install --hook-type commit-msg

          export PATH="''${PNPM_HOME}:''${PATH}"
        '';
      };
    });
  };
}
