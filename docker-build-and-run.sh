#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

for arg in "$@"; do
    if [[ "${arg}" == '-p' ]]; then
        docker compose pull &
        docker pull busybox:latest &
        docker pull docker/dockerfile:labs &
        docker pull node:26-alpine &
        docker pull oven/bun:slim &
        wait
        break
    fi
done

docker compose up -d --build --remove-orphans
