#!/usr/bin/env nu

export def get_pre_commit_hook_names [config: record<repos: list<any>>] {
    $config
    | get repos
    | get hooks
    | each {|hook| $hook | get id}
    | flatten
    | sort
    | to text
}

# Check flake and run pre-commit hooks
def main [
    ...hooks: string # The hooks to run
    --flake # Run `nix flake check`
    --list # List hook ids
    --pre-commit # Run pre-commit hooks
    --update # Update all pre-commit hooks
] {
    if $list {
        return (
            get_pre_commit_hook_names (open .pre-commit-config.yaml)
        )
    }

    let all = (
        [
            $flake
            $pre_commit
            $update
        ] | all {|option| not $option}
    )

    if $all or $flake {
        nix flake check

        if $flake and not $pre_commit {
            return
        }
    }

    if $update and not $pre_commit {
        pre-commit run pre-commit-update --all-files

        if ([$flake $pre_commit] | all {|option| not $option}) {
            return
        }
    }

    if $all or ($hooks | is-empty) {
        pre-commit run --all-files
    } else {
        for hook in $hooks {
          pre-commit run $hook --all-files
        }
    }
}
