@_help:
    ./scripts/help.nu

# Add dependencies
@add *dependencies:
    ./scripts/add.nu {{ dependencies }}

# Build the application
@build *release:
    ./scripts/build.nu {{ release }}

# Check flake and run pre-commit hooks
@check *args:
    ./scripts/check.nu {{ args }}

# Remove generated files
@clean *help:
    ./scripts/clean.nu {{ help }}

# Run clippy
@clippy *help:
    ./scripts/clippy.nu {{ help }}

# Show application dependencies
@deps *help:
    ./scripts/deps.nu {{ help }}

# Open a pre-configured development environment
@dev *help:
    ./scripts/dev.nu {{ help }}

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

# Install the application
@install *help:
    ./scripts/install.nu {{ help }}

# View issues
@issue *args:
    ./scripts/issue.nu {{ args }}

# Create a new release
@release *args:
    ./scripts/release.nu  {{ args }}

# View remote repository
@remote *web:
    ./scripts/remote.nu  {{ web }}

# Remove dependencies
@remove *dependencies:
    ./scripts/remove.nu {{ dependencies }}

# Run the application, with any provided <args>. [`--help` is for the application, not the Justfile recipe]
@run *args:
    ./scripts/run.nu {{ args }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Update dependencies
@update-deps *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
@view-source *recipe:
    ./scripts/view-source.nu {{ recipe }}
