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
  local last_header pattern
  pattern="$(alpha_model_screen_pattern "$2")"
  # Check only the LAST Claude Code header line to avoid matching stale
  # scrollback from a previous session still visible in capture-pane.
  last_header="$(alpha_capture_screen "$1" \
    | grep -iE '^\S*[▜▛█]' \
    | tail -1)" || true
  [[ -n "$last_header" && "$last_header" == *"$pattern"* ]]
}

alpha_current_model() {
  local last_model
  # Use the LAST model header line in the screen buffer to handle
  # scrollback from previous sessions still visible in capture-pane.
  last_model="$(alpha_capture_screen "$1" \
    | grep -iE 'Opus|Sonnet|Haiku' \
    | grep -iE '^\S*[▜▛█]' \
    | tail -1)" || true

  if [[ -z "$last_model" ]]; then
    return 1
  fi

  if [[ "$last_model" == *"Opus"* ]]; then
    printf 'opus\n'
  elif [[ "$last_model" == *"Sonnet"* ]]; then
    printf 'sonnet\n'
  elif [[ "$last_model" == *"Haiku"* ]]; then
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

alpha_model_picker_open() {
  local screen
  screen="$(alpha_capture_screen "$1")"
  [[ "$screen" == *"Select model"* ]]
}

alpha_open_model_picker() {
  local window_id="$1"
  local timeout="${2:-$GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT}"
  local start

  start=$SECONDS
  while true; do
    if alpha_model_picker_open "$window_id"; then
      return 0
    fi

    send_commands "$window_id" "/model" 0.1
    sleep 0.5

    if alpha_model_picker_open "$window_id"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "alpha model picker did not open for window $window_id within ${timeout}s"
      return 1
    fi

    sleep 0.2
  done
}

alpha_picker_model_number() {
  local window_id="$1"
  local target_model="$2"
  local screen line number
  local pattern
  pattern="$(alpha_model_screen_pattern "$target_model")"
  local picker_row='^[[:space:]]*(❯)?[[:space:]]*([0-9]+)\.'

  screen="$(alpha_capture_screen "$window_id")"
  while IFS= read -r line; do
    if [[ "$line" =~ $picker_row && "$line" == *"$pattern"* ]]; then
      printf '%s\n' "${BASH_REMATCH[2]}"
      return 0
    fi
  done <<< "$screen"

  fail "alpha model '$target_model' not found in picker for window $window_id"
  return 1
}

alpha_select_model() {
  local window_id="$1"
  local model="$2"
  local model_number

  alpha_open_model_picker "$window_id"
  model_number="$(alpha_picker_model_number "$window_id" "$model")"
  send_key "$window_id" "$model_number"
  sleep 0.3
  send_key "$window_id" Enter
  sleep 0.3

  alpha_wait_ready "$window_id" "$model" "$GRAND_ORCHESTRATOR_ALPHA_TIMEOUT_DEFAULT" 0.3
}

alpha_launch_if_needed() {
  local window_id="$1"
  local model="$2"

  if alpha_ready_with_model "$window_id" "$model"; then
    return 0
  fi

  # Claude is running with a different model — use /model to switch
  if alpha_ready "$window_id"; then
    alpha_select_model "$window_id" "$model"
    return 0
  fi

  # No Claude running — launch fresh
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
