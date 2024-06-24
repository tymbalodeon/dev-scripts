#!/usr/bin/env nu

use ./hosts.nu get_configuration

# Open Nix REPL with flake loaded
export def main [
    host?: string # The target host configuration (auto-detected if not specified)
] {
  let configuration = (get_configuration $host)

  nix --extra-experimental-features repl-flake repl $configuration
}
