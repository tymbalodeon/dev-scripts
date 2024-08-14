#!/usr/bin/env nu

use ./command.nu

def main [
    args: list<string>
] {
    pdm run (command) ...$args
}
