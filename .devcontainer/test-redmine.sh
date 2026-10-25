#!/bin/sh

# Starts the Redmine development stack from scratch with the Dev Container CLI
# and runs .devcontainer/test-redmine-in-container.sh in it. Pass "--system" to
# also run the system (E2E) tests.
#
#   export DOT_DEVCONTAINER_HOME="$HOME/dev_container_home"
#   .devcontainer/test-redmine.sh [--system]

set -eux

devcontainer --version

devcontainer up --workspace-folder . --remove-existing-container
exec devcontainer exec --workspace-folder . \
  .devcontainer/test-redmine-in-container.sh "$@"
