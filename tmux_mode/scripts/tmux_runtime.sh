#!/usr/bin/env bash

# Shared tmux adapter primitives for the workflow documented in ../SKILL.md.

TMUX_MODE_ENTER_DELAY_DEFAULT="${TMUX_MODE_ENTER_DELAY_DEFAULT:-0.2}"
TMUX_MODE_POLL_INTERVAL="${TMUX_MODE_POLL_INTERVAL:-0.1}"
TMUX_MODE_TIMEOUT_DEFAULT="${TMUX_MODE_TIMEOUT_DEFAULT:-3}"

fail() {
  printf 'tmux_mode error: %s\n' "$*" >&2
  return 1
}

send_key() {
  local window_id="${1:?window_id is required}"
  local key="${2:?key is required}"

  tmux send-keys -t "$window_id" "$key"
}

send_commands() {
  local window_id="${1:?window_id is required}"
  local text="${2:?text is required}"
  local delay="${3:-$TMUX_MODE_ENTER_DELAY_DEFAULT}"

  tmux send-keys -t "$window_id" "$text"
  sleep "$delay"
  tmux send-keys -t "$window_id" "" Enter
}

capture_pane() {
  local window_id="${1:?window_id is required}"

  tmux capture-pane -p -t "$window_id"
}

capture_screen() {
  capture_pane "$@"
}

capture_footer() {
  capture_screen "$1"
}

wait_for_screen() {
  local window_id="${1:?window_id is required}"
  local regex="${2:?regex is required}"
  local timeout="${3:-$TMUX_MODE_TIMEOUT_DEFAULT}"
  local interval="${4:-$TMUX_MODE_POLL_INTERVAL}"
  local screen
  local start

  start=$SECONDS
  while true; do
    screen="$(capture_screen "$window_id")"
    if [[ "$screen" =~ $regex ]]; then
      printf '%s\n' "$screen"
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "screen regex '$regex' not observed for window $window_id within ${timeout}s"
      return 1
    fi

    sleep "$interval"
  done
}

wait_for_footer() {
  wait_for_screen "$@"
}

wait_for_screen_markers() {
  local window_id="${1:?window_id is required}"
  local timeout="${2:-$TMUX_MODE_TIMEOUT_DEFAULT}"
  local interval="${3:-$TMUX_MODE_POLL_INTERVAL}"
  local screen
  local marker
  local all_found
  local start

  shift 3
  if (($# == 0)); then
    fail "at least one screen marker is required"
    return 1
  fi

  start=$SECONDS
  while true; do
    screen="$(capture_screen "$window_id")"
    all_found=1
    for marker in "$@"; do
      if [[ "$screen" != *"$marker"* ]]; then
        all_found=0
        break
      fi
    done

    if (( all_found )); then
      printf '%s\n' "$screen"
      return 0
    fi

    if (( SECONDS - start >= timeout )); then
      fail "screen markers not observed for window $window_id within ${timeout}s: $*"
      return 1
    fi

    sleep "$interval"
  done
}

wait_for_footer_markers() {
  wait_for_screen_markers "$@"
}

tmux_runtime_usage() {
  cat <<'EOF'
Usage:
  tmux_runtime.sh send-commands WINDOW_ID TEXT [ENTER_DELAY]
  tmux_runtime.sh send-key WINDOW_ID KEY
  tmux_runtime.sh capture-pane WINDOW_ID
  tmux_runtime.sh capture-screen WINDOW_ID
  tmux_runtime.sh capture-footer WINDOW_ID [LINES]
  tmux_runtime.sh wait-screen WINDOW_ID REGEX [TIMEOUT] [INTERVAL]
  tmux_runtime.sh wait-footer WINDOW_ID REGEX [TIMEOUT] [INTERVAL]
EOF
}

tmux_runtime_main() {
  local command="${1:-}"

  case "$command" in
    send-commands)
      shift
      send_commands "$@"
      ;;
    send-key)
      shift
      send_key "$@"
      ;;
    capture-pane)
      shift
      capture_pane "$@"
      ;;
    capture-screen)
      shift
      capture_screen "$@"
      ;;
    capture-footer)
      shift
      capture_footer "$@"
      ;;
    wait-screen)
      shift
      wait_for_screen "$@" >/dev/null
      ;;
    wait-footer)
      shift
      wait_for_footer "$@" >/dev/null
      ;;
    *)
      tmux_runtime_usage >&2
      return 1
      ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
  tmux_runtime_main "$@"
fi
