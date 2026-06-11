#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

find . -name '.git' -prune -type d | while read -r dir; do
    cd "$dir"/../
    git pull
    cd "${SCRIPTS_DIR}"
done

./docker-build-and-run.sh -p
