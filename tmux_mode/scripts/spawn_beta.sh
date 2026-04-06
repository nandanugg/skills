#!/usr/bin/env bash

# Beta/Codex provider adapter for the workflow documented in ../SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/Users/nanda/skills/tmux_mode/scripts/tmux_runtime.sh
source "$SCRIPT_DIR/tmux_runtime.sh"

TMUX_MODE_BETA_TIMEOUT_DEFAULT="${TMUX_MODE_BETA_TIMEOUT_DEFAULT:-5}"

usage() {
  cat <<'EOF'
Usage:
  spawn_beta.sh WINDOW_ID MODEL REASONING

Examples:
  spawn_beta.sh @12 gpt-5.4 high
  spawn_beta.sh @13 gpt-5.4-mini low
  spawn_beta.sh @14 gpt-5.3-codex medium
EOF
}

beta_capture_screen() {
  capture_screen "$1"
}

beta_reasoning_menu_open() {
  local screen
  screen="$(beta_capture_screen "$1")"
  [[ "$screen" == *"Select Reasoning Level for"* ]]
}

beta_model_picker_open() {
  local screen
  screen="$(beta_capture_screen "$1")"
  [[ "$screen" == *"Select Model and Effort"* ]]
}

beta_reasoning_menu_model() {
  local screen
  local line

  screen="$(beta_capture_screen "$1")"
  while IFS= read -r line; do
    if [[ "$line" == *"Select Reasoning Level for "* ]]; then
      line="${line#*Select Reasoning Level for }"
      printf '%s\n' "$line"
      return 0
    fi
  done <<< "$screen"

  return 1
}

beta_reasoning_menu_current() {
  local screen

  screen="$(beta_capture_screen "$1")"
  case "$screen" in
    *"Extra high"*"(current)"*) printf 'extra_high\n' ;;
    *"High"*"(current)"*) printf 'high\n' ;;
    *"Medium"*"(current)"*) printf 'medium\n' ;;
    *"Low"*"(current)"*) printf 'low\n' ;;
    *) return 1 ;;
  esac
}

beta_state_line() {
  local screen
  local line
  local state_line=""

  screen="$(beta_capture_screen "$1")"
  while IFS= read -r line; do
    if [[ "$line" =~ gpt-[^[:space:]]+[[:space:]]+(low|medium|high|extra[[:space:]]high)[[:space:]]+·[[:space:]]+[0-9]+%[[:space:]]+left[[:space:]]+·[[:space:]]+ ]]; then
      state_line="$line"
    fi
  done <<< "$screen"

  printf '%s\n' "$state_line"
}

beta_ready() {
  [[ -n "$(beta_state_line "$1")" ]]
}

beta_current_model() {
  local line
  line="$(beta_state_line "$1")"
  [[ -n "$line" ]] || return 1
  line="${line#*gpt-}"
  printf 'gpt-%s\n' "${line%% *}"
}

beta_current_reasoning() {
  local line
  line="$(beta_state_line "$1")"
  [[ -n "$line" ]] || return 1

  case "$line" in
    *" extra high · "*) printf 'extra_high\n' ;;
    *" high · "*) printf 'high\n' ;;
    *" medium · "*) printf 'medium\n' ;;
    *" low · "*) printf 'low\n' ;;
    *) return 1 ;;
  esac
}

beta_wait_ready() {
  local window_id="$1"
  local timeout="${2:-$TMUX_MODE_BETA_TIMEOUT_DEFAULT}"
  local interval="${3:-0.1}"
  local start

  start=$SECONDS
  while true; do
    if beta_ready "$window_id"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "beta screen state not ready for window $window_id within ${timeout}s"
      return 1
    fi

    sleep "$interval"
  done
}

beta_wait_until_model_applied() {
  local window_id="$1"
  local model="$2"
  local timeout="${3:-$TMUX_MODE_BETA_TIMEOUT_DEFAULT}"
  local interval="${4:-0.1}"
  local current_model
  local menu_model
  local start

  start=$SECONDS
  while true; do
    current_model="$(beta_current_model "$window_id" || true)"
    menu_model="$(beta_reasoning_menu_model "$window_id" || true)"
    if [[ "$current_model" == "$model" || "$menu_model" == "$model" ]]; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "beta model '$model' not observed for window $window_id"
      return 1
    fi

    sleep "$interval"
  done
}

beta_wait_for_state() {
  local window_id="$1"
  local model="$2"
  local reasoning="$3"
  local timeout="${4:-$TMUX_MODE_BETA_TIMEOUT_DEFAULT}"
  local interval="${5:-0.1}"
  local current_model
  local current_reasoning
  local start

  start=$SECONDS
  while true; do
    current_model="$(beta_current_model "$window_id" || true)"
    current_reasoning="$(beta_current_reasoning "$window_id" || true)"
    if [[ "$current_model" == "$model" && "$current_reasoning" == "$reasoning" ]]; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "beta state '$model $reasoning' not reached for window $window_id"
      return 1
    fi

    sleep "$interval"
  done
}

beta_model_key() {
  case "$1" in
    gpt-5.4) printf '1\n' ;;
    gpt-5.4-mini) printf '2\n' ;;
    gpt-5.3-codex) printf '3\n' ;;
    *) fail "unsupported beta model: $1"; return 1 ;;
  esac
}

beta_reasoning_key() {
  case "$1" in
    low) printf '1\n' ;;
    medium) printf '2\n' ;;
    high) printf '3\n' ;;
    extra_high) printf '4\n' ;;
    *) fail "unsupported beta reasoning: $1"; return 1 ;;
  esac
}

beta_launch_if_needed() {
  local window_id="$1"

  if beta_ready "$window_id"; then
    return 0
  fi

  send_commands "$window_id" "codex --sandbox danger-full-access" 0.2
  beta_wait_ready "$window_id" "$TMUX_MODE_BETA_TIMEOUT_DEFAULT" 0.2
}

beta_open_model_picker() {
  local window_id="$1"
  local timeout="${2:-$TMUX_MODE_BETA_TIMEOUT_DEFAULT}"
  local start

  start=$SECONDS
  while true; do
    if beta_model_picker_open "$window_id"; then
      return 0
    fi

    send_commands "$window_id" "/model" 0.1
    sleep 0.2

    if beta_model_picker_open "$window_id"; then
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "beta model picker did not open for window $window_id within ${timeout}s"
      return 1
    fi

    sleep 0.2
  done
}

beta_select_model() {
  local window_id="$1"
  local model="$2"
  local model_key

  model_key="$(beta_model_key "$model")"
  beta_open_model_picker "$window_id"
  send_key "$window_id" "$model_key"
  sleep 0.2
  beta_wait_until_model_applied "$window_id" "$model" "$TMUX_MODE_BETA_TIMEOUT_DEFAULT" 0.1
}

beta_select_reasoning() {
  local window_id="$1"
  local reasoning="$2"
  local reasoning_key
  local current_menu_reasoning

  reasoning_key="$(beta_reasoning_key "$reasoning")"

  if ! beta_reasoning_menu_open "$window_id"; then
    beta_open_model_picker "$window_id"
    send_key "$window_id" Enter
    sleep 0.2
  fi

  current_menu_reasoning="$(beta_reasoning_menu_current "$window_id" || true)"
  if [[ "$current_menu_reasoning" == "$reasoning" ]]; then
    send_key "$window_id" Enter
  else
    send_key "$window_id" "$reasoning_key"
  fi
  sleep 0.2
}

main() {
  local window_id="${1:-}"
  local model="${2:-}"
  local reasoning="${3:-}"
  local current_model
  local current_reasoning
  local menu_model

  if [[ -z "$window_id" || -z "$model" || -z "$reasoning" ]]; then
    usage >&2
    exit 1
  fi

  beta_model_key "$model" >/dev/null
  beta_reasoning_key "$reasoning" >/dev/null

  beta_launch_if_needed "$window_id"
  current_model="$(beta_current_model "$window_id")"
  current_reasoning="$(beta_current_reasoning "$window_id")"

  if [[ "$current_model" != "$model" ]]; then
    beta_select_model "$window_id" "$model"
  fi

  current_model="$(beta_current_model "$window_id" || true)"
  current_reasoning="$(beta_current_reasoning "$window_id" || true)"
  menu_model="$(beta_reasoning_menu_model "$window_id" || true)"
  if [[ "$current_model" != "$model" && "$menu_model" != "$model" ]]; then
    fail "beta model '$model' did not stick for window $window_id"
    exit 1
  fi

  if [[ "$current_reasoning" != "$reasoning" ]]; then
    beta_select_reasoning "$window_id" "$reasoning"
  fi

  beta_wait_for_state "$window_id" "$model" "$reasoning" "$TMUX_MODE_BETA_TIMEOUT_DEFAULT" 0.1

  printf 'OK beta window=%s state="%s"\n' "$window_id" "$(beta_state_line "$window_id")"
}

main "$@"
