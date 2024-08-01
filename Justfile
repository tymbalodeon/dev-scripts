@_help:
    ./scripts/help.nu

# Build dev environments
@build *args:
    ./scripts/build.nu {{ args }}

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies
@deps *args:
    ./scripts/deps.nu {{ args }}

# View the diff between environments
@diff-env *args:
    ./scripts/diff-env.nu {{ args }}

# Search available `just` recipes
[no-exit-message]
@find-recipe *search_term:
    ./scripts/find-recipe.nu {{ search_term }}

# Search project history
@history *search_term:
    ./scripts/history.nu {{ search_term }}

# Initialize direnv environment
@init *help:
    ./scripts/init.nu {{ help }}

# View issues
@issue *args:
    ./scripts/issue.nu {{ args }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Update dependencies
@update-deps *help:
    ./scripts/update-deps.nu {{ help }}

# Update environment pre-commit hook versions
@update-pre-commit *help:
    ./scripts/update-pre-commit.nu {{ help }}

# View the source code for a recipe
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}
