@_help:
    ./scripts/help.nu

# Create Justfiles
@justfile *type:
    ./scripts/justfile.nu {{ type }}
