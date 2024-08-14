#!/usr/bin/env nu

# Check flake and run pre-commit hooks
def main [
    ...hooks: string # The hooks to run
    --all # Run `nix flake check` and all pre-commit hooks
    --flake # Run `nix flake check`
    --list # List hook ids
    --update # Update all pre-commit hooks
] {
    if $list {
        print (
            rg '\- id:' .pre-commit-config.yaml
            | str replace --all "- id:" ""
            | lines
            | str trim
            | sort
            | to text
        )

        return
    }

    if $all or $flake {
        nix flake check

        if $flake {
            return
        }
    }

    if $update {
        pre-commit autoupdate

        return
    }

    if $all or ($hooks | is-empty) {
        pre-commit run --all-files
    } else {
        for hook in $hooks {
          pre-commit run $hook --all-files
        }
    }
}
