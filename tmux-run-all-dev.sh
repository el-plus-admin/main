#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Constants/Variables
readonly SCRIPT_NAME='tmux-run-dev.sh'

# Run
"./repos/ops-workers-ts/${SCRIPT_NAME}"
"./repos/management-backend/${SCRIPT_NAME}"
sleep 3
"./repos/admin-frontend/${SCRIPT_NAME}"
