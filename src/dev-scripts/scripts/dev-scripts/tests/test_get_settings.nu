use std assert

use ../build.nu get_settings

let test_settings = [
  {
    actual: (get_settings dev-scripts)
    expected: {
      environment: dev-scripts
      generic_source_directory: src/generic
      generic_build_directory: build/generic
      source_directory: src/dev-scripts
      build_directory: ""
    }
  }

  {
    actual: (get_settings python)
    expected: {
      environment: python
      generic_source_directory: src/generic
      generic_build_directory: build/generic
      source_directory: src/python
      build_directory: build/python
    }
  }
]

for settings in $test_settings {
  assert equal $settings.actual $settings.expected
}
