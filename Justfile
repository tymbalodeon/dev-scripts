@_help:
    ./scripts/help.nu

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# List dependencies
@deps *args:
    ./scripts/deps.nu {{ args }}

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

# Reload environment
@reload *help:
    ./scripts/reload.nu  {{ help }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Update dependencies
@update *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}
