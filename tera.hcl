# tera-init: this file is authored by `tera init`.
# Delete that line and this file is yours: a re-run of tera init leaves it alone.
#
# This repository's deployment manifest. It maps the repository's own
# .tera/ onto its vault on the deployment, so `tera config plan` and
# `tera config apply`, run here, change this vault and nothing else.

target {
  context = "local"
}

vault "gs-ci" {
  source = "."
}
# tera-init-digest: sha256:988b0c469eb06a25cded1822d3e805ab15b1149249bedbeb3f2d5b1ab5e44faf (edit this file and it is yours: init then replaces it only with --force <path>)
