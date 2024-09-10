# View help text
@help *recipe:
    ../scripts/dev-scripts/help.nu {{ recipe }}

# Build dev environments
[no-cd]
@build *args:
    ./scripts/dev-scripts/build.nu {{ args }}

# Run an environment Justfile
[no-cd]
@justfile *args:
    ./scripts/dev-scripts/justfile.nu {{ args }}

# List available environments and files
[no-cd]
@list *help:
    ./scripts/dev-scripts/list.nu {{ help }}
