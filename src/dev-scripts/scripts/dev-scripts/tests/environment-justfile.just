# View help text
@help *recipe:
    ../scripts/dev-scripts/help.nu {{ recipe }}

# Recipe one
[no-cd]
@one *args:
    ./scripts/dev-scripts/one.nu {{ args }}

# Recipe three
[no-cd]
@three *args:
    ./scripts/dev-scripts/three.nu {{ args }}
