#!/usr/bin/env bash

# Alpha/Claude provider adapter for the workflow documented in ../SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/Users/nanda/skills/grand-orchestrator/scripts/tmux_runtime.sh
source "$SCRIPT_DIR/tmux_runtime.sh"

GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT="${GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT:-10}"

usage() {
  cat <<'EOF'
Usage:
  spawn_alpha.sh WINDOW_ID MODEL

Examples:
  spawn_alpha.sh @12 sonnet
  spawn_alpha.sh @13 opus
  spawn_alpha.sh @14 haiku
EOF
}

alpha_capture_screen() {
  capture_screen "$1"
}

alpha_validate_model() {
  case "$1" in
    haiku|sonnet|opus)
      return 0
      ;;
    *)
      fail "unsupported alpha model: $1"
      return 1
      ;;
  esac
}

alpha_model_screen_pattern() {
  # Match patterns like "Sonnet 4.6" or "Opus 4.5" in the Claude Code header
  case "$1" in
    haiku) printf 'Haiku\n' ;;
    sonnet) printf 'Sonnet\n' ;;
    opus) printf 'Opus\n' ;;
    *) fail "unsupported alpha model: $1"; return 1 ;;
  esac
}

alpha_ready() {
  local screen
  screen="$(alpha_capture_screen "$1")"
  [[ "$screen" == *"Claude Code"* ]]
}

alpha_ready_with_model() {
  local screen pattern
  screen="$(alpha_capture_screen "$1")"
  pattern="$(alpha_model_screen_pattern "$2")"
  [[ "$screen" == *"$pattern"* ]]
}

alpha_current_model() {
  local screen
  screen="$(alpha_capture_screen "$1")"

  if [[ "$screen" == *"Opus"* ]]; then
    printf 'opus\n'
  elif [[ "$screen" == *"Sonnet"* ]]; then
    printf 'sonnet\n'
  elif [[ "$screen" == *"Haiku"* ]]; then
    printf 'haiku\n'
  else
    return 1
  fi
}

alpha_wait_ready() {
  local window_id="$1"
  local model="$2"
  local timeout="${3:-$GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT}"
  local interval="${4:-0.3}"
  local start

  start=$SECONDS
  while true; do
    if alpha_ready_with_model "$window_id" "$model"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "alpha screen state not ready for window $window_id within ${timeout}s"
      return 1
    fi

    sleep "$interval"
  done
}

alpha_launch_if_needed() {
  local window_id="$1"
  local model="$2"

  if alpha_ready_with_model "$window_id" "$model"; then
    return 0
  fi

  # If Claude is running with a different model, exit first
  if alpha_ready "$window_id"; then
    send_commands "$window_id" "/exit" 0.2
    local exit_start=$SECONDS
    while alpha_ready "$window_id"; do
      if (( SECONDS - exit_start >= 5 )); then
        send_key "$window_id" C-c
        sleep 0.5
        break
      fi
      sleep 0.3
    done
  fi

  send_commands "$window_id" "claude --dangerously-skip-permissions --model=$model" 0.2
  alpha_wait_ready "$window_id" "$model" "$GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT" 0.3
}

main() {
  local window_id="${1:-}"
  local model="${2:-}"
  local current_model

  if [[ -z "$window_id" || -z "$model" ]]; then
    usage >&2
    exit 1
  fi

  alpha_validate_model "$model"
  alpha_launch_if_needed "$window_id" "$model"

  current_model="$(alpha_current_model "$window_id" || true)"
  if [[ "$current_model" != "$model" ]]; then
    fail "alpha model '$model' did not stick for window $window_id (got '$current_model')"
    exit 1
  fi

  printf 'OK alpha window=%s model=%s\n' "$window_id" "$model"
}

main "$@"
