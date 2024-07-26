{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    rust-overlay,
    crane,
  }: let
    overlays = [
      rust-overlay.overlays.default
      (final: _prev: {
        rustToolchain = final.rust-bin.nightly.latest.default;
      })
    ];

    supportedSystems = [
      "x86_64-linux"
      "x86_64-darwin"
    ];

    forEachSupportedSystem = f:
      nixpkgs.lib.genAttrs supportedSystems (
        system:
          f {
            inherit system;

            pkgs = import nixpkgs {inherit overlays system;};
          }
      );
  in {
    packages = forEachSupportedSystem ({
      pkgs,
      system,
    }:
      with pkgs; let
        craneLib = crane.lib.${system};

        buildPackages = [
          libiconv
        ];

        darwinBuildPackages = [
          zlib.dev
          darwin.apple_sdk.frameworks.CoreFoundation
          darwin.apple_sdk.frameworks.CoreServices
          darwin.apple_sdk.frameworks.SystemConfiguration
          darwin.IOKit
        ];

        linuxBuildPackages = [
          pkg-config
          openssl
        ];
      in {
        default = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);

          buildInputs =
            buildPackages
            ++ (
              if stdenv.isDarwin
              then darwinBuildPackages
              else
                (
                  if stdenv.isLinux
                  then linuxBuildPackages
                  else []
                )
            );
        };
      });

    devShells = forEachSupportedSystem ({pkgs}:
      with pkgs; let
        buildPackages = [
          libiconv
        ];

        darwinBuildPackages = [
          zlib.dev
          darwin.apple_sdk.frameworks.CoreFoundation
          darwin.apple_sdk.frameworks.CoreServices
          darwin.apple_sdk.frameworks.SystemConfiguration
          darwin.IOKit
        ];

        linuxBuildPackages = [
          pkg-config
          openssl
        ];

        devPackages = [
          cargo-bloat
          cargo-edit
          cargo-outdated
          cargo-udeps
          cargo-watch
          rust-analyzer
          rustToolchain
          zellij
        ];
      in {
        default = pkgs.mkShell {
          packages =
            buildPackages
            ++ devPackages
            ++ (
              if stdenv.isDarwin
              then darwinBuildPackages
              else
                (
                  if stdenv.isLinux
                  then linuxBuildPackages
                  else []
                )
            );

          env.RUST_BACKTRACE = "1";
        };
      });
  };
}
