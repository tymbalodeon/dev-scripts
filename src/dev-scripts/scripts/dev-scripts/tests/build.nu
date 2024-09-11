use std assert

use ../build.nu merge_justfiles

let generic_justfile = ($env.FILE_PWD | path join generic-justfile.just)
let environment_justfile = ($env.FILE_PWD | path join environment-justfile.just)

let actual_justfile = (
  merge_justfiles environment $generic_justfile $environment_justfile
)

let expected_justfile = "# View help text
@help *recipe:
    ./scripts/help.nu {{ recipe }}

# Recipe one
[no-cd]
@one *args:
    ./scripts/one.nu {{ args }}

# Recipe two
@two *args:
    ./scripts/two.nu {{ args }}

mod environment \"just/environment.just\"

# Alias for `environment three`
@three *args:
    just environment three {{ args }}
"

assert equal $actual_justfile $expected_justfile
