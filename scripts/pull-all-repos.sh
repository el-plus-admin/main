#!/usr/bin/env bash

# shellcheck shell=bash
# shellcheck disable=SC1091

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
source "${SCRIPT_DIR}/libs/common.sh"
source "${SCRIPT_DIR}/libs/constants.sh"

# Constants/Variables
REPOS_DIR="$(cd -P -- "${SCRIPT_DIR}/.." && pwd)/repos"
readonly REPOS_DIR

# Functions
fetch_repo() {
    local repo_name="$1"
    local repo_dir="${REPOS_DIR}/${repo_name}"

    log_info "Fetching and pruning ${repo_name}..."
    git -C "${repo_dir}" fetch --prune
    log_success "Fetched and pruned ${repo_name}"
}

pull_repo() {
    local repo_name="$1"
    local repo_dir="${REPOS_DIR}/${repo_name}"

    log_info "Pulling ${repo_name}..."
    git -C "${repo_dir}" pull
    log_success "Pulled ${repo_name}"
}

# Run
main() {
    local repo_name

    log_info 'Fetching all repositories...'
    for repo_name in "${REPO_NAMES[@]}"; do
        fetch_repo "${repo_name}" &
    done

    wait

    log_info 'Pulling all repositories...'
    for repo_name in "${REPO_NAMES[@]}"; do
        pull_repo "${repo_name}" &
    done

    wait

    log_success 'All repositories updated.'
}

main "$@"
