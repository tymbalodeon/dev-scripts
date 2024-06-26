{
  description = "Dev Scripts";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nushell-syntax = {
      type = "github";
      owner = "stevenxxiu";
      repo = "sublime_text_nushell";
      flake = false;
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
          deadnix
          flake-checker
          fzf
          gh
          just
          lychee
          markdown-oxide
          marksman
          nil
          nodePackages.prettier
          nushell
          pre-commit
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
          bat_config_dir=".config/bat"
          bat_syntax_dir="''${bat_config_dir}/syntaxes"
          mkdir -p "''${bat_syntax_dir}"
          cp ${nushell-syntax}/nushell.sublime-syntax \
            "''${bat_syntax_dir}/nushell.sublime-syntax"
          bat cache --build --source "''${bat_config_dir}"
          pre-commit install --hook-type commit-msg
        '';
      };
    });
  };
}
