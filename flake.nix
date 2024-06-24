{
  description = "Nix configuration";

  inputs = {
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-elm = {
      url = "github:nixos/nixpkgs/3030f185ba6a4bf4f18b87f345f104e6a6961f34";
    };

    nushell-syntax = {
      type = "github";
      owner = "stevenxxiu";
      repo = "sublime_text_nushell";
      flake = false;
    };
  };

  outputs = {
    home-manager,
    nixpkgs,
    nixpkgs-darwin,
    nixpkgs-elm,
    nushell-syntax,
    ...
  } @ inputs: let
    supportedSystems = [
      "x86_64-darwin"
      "x86_64-linux"
    ];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems
      (system:
        f {
          pkgs =
            if system == "x86_64-darwin"
            then import nixpkgs-darwin {inherit system;}
            else import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          alejandra
          ansible-language-server
          bat
          deadnix
          delta
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

        shellHook = "pre-commit install --hook-type commit-msg";
      };
    });

    homeConfigurations = let
      hosts = ["benrosen" "work"];

      mkHost = hostName: {
        name = hostName;

        value = home-manager.lib.homeManagerConfiguration {
          modules = [./darwin/${hostName}/home.nix];
          pkgs = nixpkgs-darwin.legacyPackages.x86_64-darwin;

          extraSpecialArgs = {
            inherit nushell-syntax;

            pkgs-elm = import nixpkgs-elm {
              config.allowUnfree = true;
              system = "x86_64-darwin";
            };
          };
        };
      };
    in
      builtins.listToAttrs (map mkHost hosts);

    nixosConfigurations = let
      hosts = ["bumbirich" "ruzia"];

      mkHost = hostName: {
        name = hostName;

        value = nixpkgs.lib.nixosSystem {
          modules = [
            ./nixos/configuration.nix
            ./nixos/hardware-configurations/${hostName}.nix
            {networking.hostName = hostName;}
          ];

          specialArgs = {inherit inputs;};
        };
      };
    in
      builtins.listToAttrs (map mkHost hosts);
  };
}
