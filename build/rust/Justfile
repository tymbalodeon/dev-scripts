@_help:
    ./scripts/_help.nu

# Add dependencies
@add *dependencies:
    ./scripts/add.nu {{ dependencies }}

# View file annotated with version control information
@annotate *filename:
    ./scripts/annotate.nu {{ invocation_directory() }} {{ filename }}

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
    ./scripts/find-recipe.nu {{ invocation_directory() }} {{ search_term }}

# View project history
@history *args:
    ./scripts/history.nu {{ invocation_directory() }} {{ args }}

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

# Run the application, with any provided <args>.
@run *args:
    ./scripts/run.nu {{ args }}

# View repository analytics
@stats *help:
    ./scripts/stats.nu {{ help }}

# Run the tests
@test *package:
    ./scripts/test.nu {{ package }}

# Update dependencies
@update-deps *help:
    ./scripts/update-deps.nu {{ help }}

# View the source code for a recipe
@view-source *recipe:
    ./scripts/view-source.nu {{ invocation_directory() }} {{ recipe }}
