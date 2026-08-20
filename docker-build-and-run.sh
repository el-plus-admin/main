#!/bin/bash

# shellcheck shell=bash
# shellcheck disable=SC1091

set -euo pipefail

SCRIPT_DIR="$(cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
source "${SCRIPT_DIR}/scripts/libs/common.sh"

cd "${SCRIPT_DIR}"

# Constants/Variables
readonly REMAINING_PHASE='@remaining'

# Keep the default generic. Add service groups only when their build order matters.
# Builds that declare build.ssh automatically use SSH_KEY_PATH or ~/.ssh/id_ed25519.
# Unlisted services are appended as one final phase. Use @remaining to place that
# automatic phase between explicit groups.
#
# Example:
# BUILD_PHASES=(
#     'account admin-frontend'
#     '@remaining'
#     'frontend'
# )
BUILD_PHASES=(
    "${REMAINING_PHASE}"
)

# Functions
build_services() {
    (($# > 0)) || return 0

    log_info "Building services: $* ..."
    docker compose "${compose_options[@]}" build "${build_options[@]}" "$@"
}

cleanup_ssh_agent() {
    if [[ -n "${SSH_AGENT_PID:-}" ]]; then
        ssh-agent -k >/dev/null 2>&1 || true
        unset SSH_AGENT_PID SSH_AUTH_SOCK
    fi
}

start_ssh_agent() {
    local compose_config="$1"
    local ssh_key_path="${SSH_KEY_PATH:-${HOME}/.ssh/id_ed25519}"

    grep -Eq '^[[:space:]]+ssh:' <<<"${compose_config}" || return 0

    eval "$(ssh-agent -s)"
    trap cleanup_ssh_agent EXIT
    ssh-add "${ssh_key_path}"
}

# Run
main() {
    local parallel
    local services_output
    local compose_config
    local phase
    local service
    local has_remaining_phase=false
    local -a compose_options
    local -a build_options=()
    local -a all_services=()
    local -a phase_services=()
    local -a remaining_services=()
    local -A known_services=()
    local -A explicit_services=()

    parallel="$(nproc)"
    if ((parallel > 8)); then
        parallel=8
    fi

    compose_options=(--parallel "${parallel}")

    for arg in "$@"; do
        if [[ "${arg}" == '-p' ]]; then
            build_options+=(--pull)
            docker compose pull &
            wait
            break
        fi
    done

    compose_config="$(docker compose config)"
    services_output="$(docker compose config --services)"
    mapfile -t all_services <<<"${services_output}"
    ((${#all_services[@]} > 0)) || {
        log_error 'No Compose services were found'
        return 1
    }

    for service in "${all_services[@]}"; do
        known_services["${service}"]=1
    done

    for phase in "${BUILD_PHASES[@]}"; do
        if [[ "${phase}" == "${REMAINING_PHASE}" ]]; then
            [[ "${has_remaining_phase}" == false ]] || {
                log_error "The ${REMAINING_PHASE} phase may only be used once"
                return 1
            }

            has_remaining_phase=true
            continue
        fi

        read -r -a phase_services <<<"${phase}"
        ((${#phase_services[@]} > 0)) || {
            log_error 'Build phases must not be empty'
            return 1
        }

        for service in "${phase_services[@]}"; do
            [[ -n "${known_services[${service}]+set}" ]] || {
                log_error "Unknown Compose service in build phase: ${service}"
                return 1
            }

            [[ -z "${explicit_services[${service}]+set}" ]] || {
                log_error "Compose service appears in multiple build phases: ${service}"
                return 1
            }

            explicit_services["${service}"]=1
        done
    done

    for service in "${all_services[@]}"; do
        [[ -n "${explicit_services[${service}]+set}" ]] || remaining_services+=("${service}")
    done

    start_ssh_agent "${compose_config}"

    for phase in "${BUILD_PHASES[@]}"; do
        if [[ "${phase}" == "${REMAINING_PHASE}" ]]; then
            build_services "${remaining_services[@]}"
        else
            read -r -a phase_services <<<"${phase}"
            build_services "${phase_services[@]}"
        fi
    done

    [[ "${has_remaining_phase}" == true ]] || build_services "${remaining_services[@]}"
    docker compose up -d --remove-orphans
}

main "$@"
