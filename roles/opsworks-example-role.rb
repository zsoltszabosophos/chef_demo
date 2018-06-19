name "opsworks-example-role"
description "This role specifies all recipes described in the starter kit guide (README.md)"

run_list(
  "recipe[chef-client]",
  "recipe[apache2]",
  "recipe[opsworks-audit]"
  # "recipe[ssh-hardening]"
)
