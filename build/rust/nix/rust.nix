{pkgs, ...}: {
  packages = with pkgs;
    [
      pkgs.libiconv
      cargo-bloat
      cargo-edit
      cargo-outdated
      cargo-udeps
      cargo-watch
      rust-analyzer
      rustToolchain
      zellij
    ]
    ++ (
      if stdenv.isDarwin
      then
        with pkgs; [
          zlib.dev
          darwin.apple_sdk.frameworks.CoreFoundation
          darwin.apple_sdk.frameworks.CoreServices
          darwin.apple_sdk.frameworks.SystemConfiguration
          darwin.IOKit
        ]
      else
        (
          if stdenv.isLinux
          then
            with pkgs; [
              pkg-config
              openssl
            ]
          else []
        )
    );
}
