{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

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
      nixpkgs.lib.genAttrs supportedSystems (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        FONTCONFIG_FILE = pkgs.makeFontsConf {
          fontDirectories = [pkgs.freefont_ttf];
        };

        packages = with pkgs; [
          google-java-format
          jdt-language-server
          openjdk
          watchexec
          zellij
        ];
      };
    });
  };
}