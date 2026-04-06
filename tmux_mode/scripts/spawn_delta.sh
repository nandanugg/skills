#!/usr/bin/env bash

# Delta/OpenCode provider adapter for the workflow documented in ../SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/Users/nanda/skills/tmux_mode/scripts/tmux_runtime.sh
source "$SCRIPT_DIR/tmux_runtime.sh"

usage() {
  cat <<'EOF'
Usage:
  spawn_delta.sh WINDOW_ID MODEL_LABEL REASONING_LABEL

Examples:
  spawn_delta.sh @12 "GPT-5.4 OpenAI" xhigh
  spawn_delta.sh @13 "GPT-5.4 mini OpenAI" low
  spawn_delta.sh @14 "GPT-5.3 Codex OpenAI" medium
EOF
}

delta_validate_model() {
  case "$1" in
    "GPT-5.4 mini OpenAI"|"GPT-5.4 OpenAI"|"GPT-5.3 Codex OpenAI")
      return 0
      ;;
    *)
      fail "unsupported delta model label: $1"
      return 1
      ;;
  esac
}

delta_validate_reasoning() {
  case "$1" in
    low|medium|high|xhigh)
      return 0
      ;;
    *)
      fail "unsupported delta reasoning label: $1"
      return 1
      ;;
  esac
}

delta_capture_screen() {
  capture_screen "$1"
}

delta_selector_open() {
  local screen
  screen="$(delta_capture_screen "$1")"
  [[ "$screen" == *"Select variant"* ]]
}

delta_build_line() {
  local screen
  local line
  local build_line=""

  screen="$(delta_capture_screen "$1")"
  while IFS= read -r line; do
    if [[ "$line" == *"Build "* ]]; then
      build_line="$line"
    fi
  done <<< "$screen"

  printf '%s\n' "$build_line"
}

delta_main_ui_ready() {
  local screen
  local build_line

  screen="$(delta_capture_screen "$1")"
  build_line="$(delta_build_line "$1")"
  [[ -n "$build_line" && "$screen" == *"ctrl+p commands"* && "$screen" != *"Select variant"* ]]
}

delta_close_selector_if_open() {
  local window_id="$1"
  local attempts=0

  while delta_selector_open "$window_id"; do
    attempts=$((attempts + 1))
    if (( attempts > 3 )); then
      fail "delta selector did not close for window $window_id"
      return 1
    fi

    send_key "$window_id" Enter
    sleep 0.2
  done
}

delta_wait_for_main_ui() {
  local window_id="$1"
  local timeout="${2:-$TMUX_MODE_TIMEOUT_DEFAULT}"
  local interval="${3:-0.1}"
  local start

  start=$SECONDS
  while true; do
    if delta_selector_open "$window_id"; then
      delta_close_selector_if_open "$window_id"
    fi

    if delta_main_ui_ready "$window_id"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "delta main screen state not ready for window $window_id within ${timeout}s"
      return 1
    fi

    sleep "$interval"
  done
}

delta_launch_if_needed() {
  local window_id="$1"

  if delta_main_ui_ready "$window_id"; then
    return 0
  fi

  if delta_selector_open "$window_id"; then
    delta_close_selector_if_open "$window_id"
  fi

  if delta_main_ui_ready "$window_id"; then
    return 0
  fi

  send_commands "$window_id" "opencode" 0.2
  delta_wait_for_main_ui "$window_id" "$TMUX_MODE_TIMEOUT_DEFAULT" 0.2
}

delta_read_reasoning() {
  local build_line

  build_line="$(delta_build_line "$1")"
  if [[ -z "$build_line" ]]; then
    fail "delta build footer missing for window $1"
    return 1
  fi

  case "$build_line" in
    *"· none"*)
      printf 'none\n'
      ;;
    *"· low"*)
      printf 'low\n'
      ;;
    *"· medium"*)
      printf 'medium\n'
      ;;
    *"· high"*)
      printf 'high\n'
      ;;
    *"· xhigh"*)
      printf 'xhigh\n'
      ;;
    *)
      printf 'empty\n'
      ;;
  esac
}

delta_select_model() {
  local window_id="$1"
  local model_label="$2"
  local timeout="$TMUX_MODE_TIMEOUT_DEFAULT"
  local build_line
  local start

  send_commands "$window_id" "/models" 0.1
  sleep 0.15
  send_commands "$window_id" "$model_label" 0.1
  sleep 0.2
  delta_close_selector_if_open "$window_id" || true
  delta_wait_for_main_ui "$window_id" "$TMUX_MODE_TIMEOUT_DEFAULT" 0.1

  start=$SECONDS
  while true; do
    build_line="$(delta_build_line "$window_id")"
    if [[ "$build_line" == *"$model_label"* ]]; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "delta model '$model_label' did not stick for window $window_id"
      return 1
    fi

    sleep 0.1
  done
}

delta_cycle_reasoning() {
  local window_id="$1"
  local target="$2"
  local current
  local attempts=0

  current="$(delta_read_reasoning "$window_id")"
  while [[ "$current" != "$target" ]]; do
    attempts=$((attempts + 1))
    if (( attempts > 8 )); then
      fail "delta reasoning '$target' not reached for window $window_id; last state was '$current'"
      return 1
    fi

    send_key "$window_id" C-t
    sleep 0.2
    delta_close_selector_if_open "$window_id" || true
    current="$(delta_read_reasoning "$window_id")"
  done
}

main() {
  local window_id="${1:-}"
  local model_label="${2:-}"
  local reasoning_label="${3:-}"
  local build_line

  if [[ -z "$window_id" || -z "$model_label" || -z "$reasoning_label" ]]; then
    usage >&2
    exit 1
  fi

  delta_validate_model "$model_label"
  delta_validate_reasoning "$reasoning_label"
  delta_launch_if_needed "$window_id"
  delta_select_model "$window_id" "$model_label"
  delta_cycle_reasoning "$window_id" "$reasoning_label"

  build_line="$(delta_build_line "$window_id")"
  if [[ "$build_line" != *"$model_label"* || "$build_line" != *"· $reasoning_label"* ]]; then
    fail "delta runtime verification failed for window $window_id: $build_line"
    exit 1
  fi

  printf 'OK delta window=%s build="%s"\n' "$window_id" "$build_line"
}

main "$@"
