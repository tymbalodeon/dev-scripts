#!/usr/bin/env nu

# Update dependencies
export def main [] {
    nix flake update
}
