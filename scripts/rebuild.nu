#!/usr/bin/env nu

use ./hosts.nu get_available_hosts
use ./hosts.nu get_built_host_name
use ./hosts.nu is_nixos
use ./prune.nu
use ./update-deps.nu

# Rebuild and switch to (or --test) a configuration
export def main [
    host?: string # The target host configuration (auto-detected if not specified)
    --hosts # The available hosts on the current system
    --no-prune # Skip running `just prune` after rebuilding
    --test # Apply the configuration without adding it to the boot menu
    --update # Update the flake lock before rebuilding
] {
  if $update {
    update-deps
  }

  let is_nixos = (is_nixos)

  if $hosts {
    let hosts = if $is_nixos {
      get_available_hosts | get NixOS
    } else {
      get_available_hosts | get Darwin
    }

    return ($hosts | to text)
  }

  let host = if ($host | is-empty) {
    get_built_host_name
  } else {
    $host
  }

  let host = $".#($host)"

  git add .

  if $is_nixos {
    if $test {
        sudo nixos-rebuild test --flake $host
    } else {
        sudo nixos-rebuild switch --flake $host
    }
  } else {
    home-manager switch --flake $host
  }

  bat cache --build

  if not $no_prune {
    prune
  }

  if not (git status --short | is-empty) {
    git status
  }
}
