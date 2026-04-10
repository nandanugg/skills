#!/usr/bin/env bash

# Gamma/Amp provider adapter for the workflow documented in ../SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/Users/nanda/skills/grand_orchestrator/scripts/tmux_runtime.sh
source "$SCRIPT_DIR/tmux_runtime.sh"

usage() {
  cat <<'EOF'
Usage:
  spawn_gamma.sh WINDOW_ID MODE

Examples:
  spawn_gamma.sh @12 smart
  spawn_gamma.sh @13 rush
EOF
}

gamma_capture_screen() {
  capture_screen "$1"
}

gamma_state_line() {
  local screen
  local line
  local state_line=""

  screen="$(gamma_capture_screen "$1")"
  while IFS= read -r line; do
    if [[ "$line" == *"──smart──"* || "$line" == *"──rush──"* ]]; then
      state_line="$line"
    fi
  done <<< "$screen"

  printf '%s\n' "$state_line"
}

gamma_ready() {
  [[ -n "$(gamma_state_line "$1")" ]]
}

gamma_current_mode() {
  local line
  line="$(gamma_state_line "$1")"
  [[ -n "$line" ]] || return 1

  case "$line" in
    *"──smart──"*) printf 'smart\n' ;;
    *"──rush──"*) printf 'rush\n' ;;
    *) return 1 ;;
  esac
}

gamma_wait_ready() {
  local window_id="$1"
  local timeout="${2:-$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT}"
  local interval="${3:-0.1}"
  local start

  start=$SECONDS
  while true; do
    if gamma_ready "$window_id"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "gamma screen state not ready for window $window_id within ${timeout}s"
      return 1
    fi

    sleep "$interval"
  done
}

gamma_wait_for_mode() {
  local window_id="$1"
  local mode="$2"
  local timeout="${3:-$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT}"
  local interval="${4:-0.1}"
  local current_mode
  local start

  start=$SECONDS
  while true; do
    current_mode="$(gamma_current_mode "$window_id" || true)"
    if [[ "$current_mode" == "$mode" ]]; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "gamma mode '$mode' not reached for window $window_id"
      return 1
    fi

    sleep "$interval"
  done
}

gamma_validate_mode() {
  case "$1" in
    smart|rush)
      return 0
      ;;
    *)
      fail "unsupported gamma mode: $1"
      return 1
      ;;
  esac
}

gamma_launch_if_needed() {
  local window_id="$1"

  if gamma_ready "$window_id"; then
    return 0
  fi

  send_commands "$window_id" "amp" 0.2
  gamma_wait_ready "$window_id" "$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT" 0.2
}

main() {
  local window_id="${1:-}"
  local mode="${2:-}"
  local current_mode

  if [[ -z "$window_id" || -z "$mode" ]]; then
    usage >&2
    exit 1
  fi

  gamma_validate_mode "$mode"
  gamma_launch_if_needed "$window_id"

  current_mode="$(gamma_current_mode "$window_id" || true)"
  if [[ "$current_mode" != "$mode" ]]; then
    send_key "$window_id" /
    sleep 0.1
    send_commands "$window_id" "$mode" 0.1
    sleep 0.2
  fi

  gamma_wait_for_mode "$window_id" "$mode" "$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT" 0.1
  printf 'OK gamma window=%s state="%s"\n' "$window_id" "$(gamma_state_line "$window_id")"
}

main "$@"
