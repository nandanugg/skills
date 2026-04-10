#!/usr/bin/env bash

# Shared tmux adapter primitives for the workflow documented in ../SKILL.md.

GRAND_ORCHESTRATOR_ENTER_DELAY_DEFAULT="${GRAND_ORCHESTRATOR_ENTER_DELAY_DEFAULT:-0.2}"
GRAND_ORCHESTRATOR_POLL_INTERVAL="${GRAND_ORCHESTRATOR_POLL_INTERVAL:-0.1}"
GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT="${GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT:-3}"
GRAND_ORCHESTRATOR_WINDOW_RENAME_DELAY_DEFAULT="${GRAND_ORCHESTRATOR_WINDOW_RENAME_DELAY_DEFAULT:-0.1}"

fail() {
  printf 'grand_orchestrator error: %s\n' "$*" >&2
  return 1
}

# ---------------------------------------------------------------------------
# Window management
# ---------------------------------------------------------------------------

create_window() {
  local window_name="${1:?window_name is required}"
  local rename_delay="${2:-$GRAND_ORCHESTRATOR_WINDOW_RENAME_DELAY_DEFAULT}"

  local window_id
  window_id="$(tmux new-window -d -P -F '#{window_id}')" || {
    fail "failed to create tmux window"
    return 1
  }

  # Oh My Tmux can briefly override the initial window name on creation.
  sleep "$rename_delay"

  tmux rename-window -t "$window_id" "$window_name" || {
    fail "failed to rename window $window_id to $window_name"
    return 1
  }
  # Print the live window id so callers can capture it:
  #   WINDOW_ID="$(create_window "pay|doc|lg|settlement")"
  printf '%s\n' "$window_id"
}

kill_window() {
  local window_id="${1:?window_id is required}"

  tmux kill-window -t "$window_id" 2>/dev/null || {
    fail "failed to kill window $window_id (may already be gone)"
    return 1
  }
}

rename_window() {
  local old="${1:?old window name/id is required}"
  local new="${2:?new window name is required}"

  tmux rename-window -t "$old" "$new" || {
    fail "failed to rename window $old to $new"
    return 1
  }
}

list_windows() {
  tmux list-windows "$@"
}

send_key() {
  local window_id="${1:?window_id is required}"
  local key="${2:?key is required}"

  tmux send-keys -t "$window_id" "$key"
}

send_commands() {
  local window_id="${1:?window_id is required}"
  local text="${2:?text is required}"
  local delay="${3:-$GRAND_ORCHESTRATOR_ENTER_DELAY_DEFAULT}"

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
  local timeout="${3:-$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT}"
  local interval="${4:-$GRAND_ORCHESTRATOR_POLL_INTERVAL}"
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
  local timeout="${2:-$GRAND_ORCHESTRATOR_TIMEOUT_DEFAULT}"
  local interval="${3:-$GRAND_ORCHESTRATOR_POLL_INTERVAL}"
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
  tmux_runtime.sh create-window WINDOW_NAME
  tmux_runtime.sh kill-window WINDOW_ID
  tmux_runtime.sh rename-window OLD NEW
  tmux_runtime.sh list-windows [TMUX_ARGS...]
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
    create-window)
      shift
      create_window "$@"
      ;;
    kill-window)
      shift
      kill_window "$@"
      ;;
    rename-window)
      shift
      rename_window "$@"
      ;;
    list-windows)
      shift
      list_windows "$@"
      ;;
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
