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
      nixpkgs.lib.genAttrs supportedSystems
      (system:
        f {
          pkgs = import nixpkgs {inherit system;};
        });
  in {
    devShells = forEachSupportedSystem ({pkgs}: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          git-cliff
          lychee
          nodePackages.pnpm
          pdm
          python311
          python311Packages.pre-commit-hooks
        ];

        shellHook = ''
          echo hi from python
        '';
      };
    });
  };
}
