# View help text
@help *recipe:
    ./scripts/help.nu {{ recipe }}

# Recipe one
[no-cd]
@one *args:
    ./scripts/one.nu {{ args }}

# Recipe two
@two *args:
    ./scripts/two.nu {{ args }}
