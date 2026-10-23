version = "v1"

# `tera init --based-on plugin.codex/work-order-types/codex-task` wrote this
# declaration. This vault's recipes write the installation "codex"
# by its declared address, and this file says which major version of it they
# are written against: the major of the release it held when this was written.
# Moving the vault to another major is one edit to major_version, and the plan
# shows what it moves. init never rewrites this file.
builds_on "codex" {
  major_version = "v2"
}
