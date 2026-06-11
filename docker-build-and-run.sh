#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

if [[ " $@ " =~ ' -p ' ]]; then
    docker compose pull &
    docker pull busybox:latest &
    docker pull docker/dockerfile:labs &
    docker pull node:26-alpine &
    docker pull oven/bun:slim &
    wait
fi

docker compose up -d --build --remove-orphans
