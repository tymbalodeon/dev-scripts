@_help:
    ./scripts/help.nu

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies
@deps *args:
    ./scripts/deps.nu {{ args }}

# View the diff between hosts
@diff *args:
    ./scripts/diff.nu {{ args }}

# Search available `just` recipes
[no-exit-message]
@find-recipe *search_term:
    ./scripts/find-recipe.nu {{ search_term }}

# View generations
@generations *help:
    ./scripts/generations.nu {{ help }}

# Search project history
@history *search_term:
    ./scripts/history.nu {{ search_term }}

# List available hosts
@hosts *help:
    ./scripts/hosts.nu {{ help }}

# Initialize direnv environment
@init *help:
    ./scripts/init.nu {{ help }}

# View issues
@issue *args:
    ./scripts/issue.nu {{ args }}

# Collect garbage and remove old generations
@prune *older_than:
    ./scripts/prune.nu {{ older_than }}

# Update README command output
@_readme *help:
    ./scripts/readme.nu {{ help }}

# Rebuild and switch to (or --test) a configuration
@rebuild *args:
    ./scripts/rebuild.nu {{ args }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# Rollback to a previous generation
@rollback *id:
    ./scripts/rollback.nu {{ id }}

# Open Nix REPL with flake loaded
@shell *host:
    ./scripts/shell.nu {{ host }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Update dependencies
@update *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}
