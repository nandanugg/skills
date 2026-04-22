#!/usr/bin/env bash

# Beta/Codex provider adapter for the workflow documented in ../SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/Users/nanda/skills/grand_orchestrator/scripts/tmux_runtime.sh
source "$SCRIPT_DIR/tmux_runtime.sh"

GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT="${GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT:-10}"
GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES="${GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES:-60}"

usage() {
  cat <<'EOF'
Usage:
  spawn_beta.sh WINDOW_ID MODEL REASONING

Examples:
  spawn_beta.sh @12 gpt-5.4 high
  spawn_beta.sh @13 gpt-5.4-mini low
  spawn_beta.sh @14 gpt-5.3-codex-spark medium
  spawn_beta.sh @15 gpt-5.3-codex high
EOF
}

beta_capture_screen() {
  capture_screen "$1"
}

beta_active_screen() {
  local window_id="$1"
  beta_capture_screen "$window_id" | tail -n "$GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES"
}

beta_reasoning_menu_open() {
  local screen
  screen="$(beta_capture_screen "$1")"
  [[ "$screen" == *"Select Reasoning Level for"* || "$screen" == *"Select Reasoning Level"* ]]
}

beta_model_picker_open() {
  local screen
  screen="$(beta_capture_screen "$1")"
  [[ "$screen" == *"Select Model and Effort"* || "$screen" == *"Select Model"* ]]
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

beta_model_line() {
  local screen
  local line
  local model_line=""

  screen="$(beta_active_screen "$1")"
  while IFS= read -r line; do
    case "$line" in
      *"model:"*"gpt-"*)
        model_line="$line"
        ;;
      *"gpt-"*" · "*)
        model_line="$line"
        ;;
    esac
  done <<< "$screen"

  printf '%s\n' "$model_line"
}

beta_supported_models() {
  printf 'gpt-5.3-codex-spark\n'
  printf 'gpt-5.3-codex\n'
  printf 'gpt-5.2-codex\n'
  printf 'gpt-5.1-codex-max\n'
  printf 'gpt-5.4-mini\n'
  printf 'gpt-5.4\n'
}

beta_model_key_from_name() {
  local model_name="$1"

  while IFS= read -r model_name_in_map; do
    if [[ "$model_name" == "$model_name_in_map" ]]; then
      printf '%s\n' "$model_name"
      return 0
    fi
  done < <(beta_supported_models)

  return 1
}

beta_model_name_from_line() {
  local line="$1"
  local model

  while IFS= read -r model; do
    if [[ "$line" == *"$model"* ]]; then
      printf '%s\n' "$model"
      return 0
    fi
  done < <(beta_supported_models)

  return 1
}

beta_picker_option_number_from_line() {
  local line="$1"
  local numbered_pattern='^[[:space:]]*(>|›|❯)?[[:space:]]*([0-9]+)[.)][[:space:]]+'
  local bullet_pattern='^[[:space:]]*(>|›|❯)?[[:space:]]*([0-9]+)[[:space:]]+·[[:space:]]+'

  if [[ "$line" =~ $numbered_pattern ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi

  if [[ "$line" =~ $bullet_pattern ]]; then
    printf '%s\n' "${BASH_REMATCH[2]}"
    return 0
  fi

  return 1
}

beta_picker_model_number() {
  local window_id="$1"
  local target_model="$2"
  local screen line number model

  screen="$(beta_capture_screen "$window_id")"
  while IFS= read -r line; do
    model="$(beta_model_name_from_line "$line" || true)"
    if [[ "$model" != "$target_model" ]]; then
      continue
    fi

    number="$(beta_picker_option_number_from_line "$line" || true)"
    if [[ -n "$number" ]]; then
      printf '%s\n' "$number"
      return 0
    fi
  done <<< "$screen"

  fail "beta model '$target_model' not found in picker for window $window_id"
  return 1
}

beta_state_line_candidates() {
  local screen
  local line

  screen="$(beta_active_screen "$1")"
  while IFS= read -r line; do
    if [[ "$line" == *"gpt-"* && "$line" == *" · "* ]] ||
       [[ "$line" == *"gpt-"* && "$line" == *"model:"* ]] ||
       [[ "$line" == *"gpt-"* && "$line" == *"Reasoning"* ]] ||
       [[ "$line" == *"gpt-"* && "$line" == *"reasoning"* ]]; then
      printf '%s\n' "$line"
    elif [[ "$line" == *"gpt-"* && ("$line" == *"Extra high"* || "$line" == *"extra high"* || "$line" == *"xhigh"* || "$line" == *"x high"* || "$line" == *"High"* || "$line" == *"high"* || "$line" == *"Medium"* || "$line" == *"medium"* || "$line" == *"Low"* || "$line" == *"low"*) ]]; then
      printf '%s\n' "$line"
    fi
  done <<< "$screen"
}

beta_state_is_runtime() {
  local line
  line="$1"

  [[ "$line" == *"gpt-"* && "$line" == *" · "* ]] && return 0
  [[ "$line" == *"model:"* && "$line" == *"gpt-"* ]] && return 0
  [[ "$line" == *"gpt-"* && "$line" == *"Reasoning"* && "$line" == *"select"* ]] && return 0
  [[ "$line" == *"gpt-"* && ("$line" == *"Extra high"* || "$line" == *"extra high"* || "$line" == *"xhigh"* || "$line" == *"x high"* || "$line" == *"High"* || "$line" == *"high"* || "$line" == *"Medium"* || "$line" == *"medium"* || "$line" == *"Low"* || "$line" == *"low"*) ]] && return 0

  return 1
}

beta_state_line() {
  local line
  local state_line=""
  local fallback_line=""

  while IFS= read -r line; do
    if beta_state_is_runtime "$line"; then
      state_line="$line"
      if [[ "$line" == *"gpt-"* && "$line" == *" · "* ]]; then
        printf '%s\n' "$line"
        return 0
      fi
    fi

    if [[ "$line" == *"gpt-"* && "$line" == *"model:"* ]]; then
      fallback_line="$line"
    fi
  done <<< "$(beta_state_line_candidates "$1")"

  if [[ -n "$state_line" ]]; then
    printf '%s\n' "$state_line"
    return 0
  fi

  if [[ -n "$fallback_line" ]]; then
    printf '%s\n' "$fallback_line"
    return 0
  fi

  beta_model_line "$1"
}

beta_ready() {
  local screen

  screen="$(beta_active_screen "$1")"
  if beta_model_picker_open "$1" || beta_reasoning_menu_open "$1"; then
    return 0
  fi

  [[ "$screen" == *"OpenAI Codex"* && "$screen" == *"model:"* ]] || [[ "$screen" == *"gpt-5."*"·"* ]]
}

beta_current_model() {
  local line
  line="$(beta_state_line "$1")"
  [[ -n "$line" ]] || return 1
  if [[ "$line" =~ (gpt-[^[:space:]]+) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

beta_current_reasoning() {
  local line
  line="$(beta_state_line "$1")"
  [[ -n "$line" ]] || return 1

  # Codex state line format may include a speed label between reasoning and ·
  # e.g. "gpt-5.4 low fast · ~/skills" or "gpt-5.3-codex-spark medium · ~/skills"
  case "$line" in
    *" xhigh "*|*" xhigh"*|*" extra high "*|*" extra high"*|*"Extra high"*) printf 'extra_high\n' ;;
    *" extra_high "*|*" extra_high"*|*"extra_high"*) printf 'extra_high\n' ;;
    *" extra high · "*|*" extra high "*"·"*) printf 'extra_high\n' ;;
    *"x high"*|*" x high "*|*"xhigh"*|*" xhigh "*|*" xhigh"*) printf 'extra_high\n' ;;
    *" high "*"·"*) printf 'high\n' ;;
    *" medium "*"·"*) printf 'medium\n' ;;
    *" low "*"·"*) printf 'low\n' ;;
    *) return 1 ;;
  esac
}

beta_wait_ready() {
  local window_id="$1"
  local timeout="${2:-$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT}"
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
  local timeout="${3:-$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT}"
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
  local timeout="${4:-$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT}"
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

beta_validate_model() {
  if ! beta_model_key_from_name "$1" >/dev/null; then
    fail "unsupported beta model: $1"
    return 1
  fi
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

beta_reasoning_name_from_line() {
  local line="$1"

  if [[ "$line" == *"Extra high"* || "$line" == *"extra high"* || "$line" == *"xhigh"* || "$line" == *"x high"* || "$line" == *"Extra_High"* || "$line" == *"extra_high"* ]]; then
    printf 'extra_high\n'
    return 0
  fi

  if [[ "$line" == *"High"* || "$line" == *"high"* ]]; then
    printf 'high\n'
    return 0
  fi

  if [[ "$line" == *"Medium"* || "$line" == *"medium"* ]]; then
    printf 'medium\n'
    return 0
  fi

  if [[ "$line" == *"Low"* || "$line" == *"low"* ]]; then
    printf 'low\n'
    return 0
  fi

  return 1
}

beta_picker_reasoning_number() {
  local window_id="$1"
  local target_reasoning="$2"
  local screen line number reasoning

  screen="$(beta_capture_screen "$window_id")"
  while IFS= read -r line; do
    number="$(beta_picker_option_number_from_line "$line" || true)"
    if [[ -z "$number" ]]; then
      continue
    fi

    reasoning="$(beta_reasoning_name_from_line "$line" || true)"
    if [[ -n "$reasoning" && "$reasoning" == "$target_reasoning" ]]; then
      printf '%s\n' "$number"
      return 0
    fi
  done <<< "$screen"

  return 1
}

beta_launch_if_needed() {
  local window_id="$1"

  if beta_ready "$window_id"; then
    return 0
  fi

  send_commands "$window_id" "codex --sandbox danger-full-access" 0.2
  beta_wait_ready "$window_id" "$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT" 0.2
}

beta_open_model_picker() {
  local window_id="$1"
  local timeout="${2:-$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT}"
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
  local model_number

  beta_open_model_picker "$window_id"
  model_number="$(beta_picker_model_number "$window_id" "$model")"
  send_key "$window_id" "$model_number"
  sleep 0.2
  beta_wait_until_model_applied "$window_id" "$model" "$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT" 0.1
}

beta_select_reasoning() {
  local window_id="$1"
  local reasoning="$2"
  local reasoning_number

  if ! beta_reasoning_menu_open "$window_id"; then
    beta_open_model_picker "$window_id"
    send_key "$window_id" Enter
    sleep 0.2
  fi

  local current_menu_reasoning
  current_menu_reasoning="$(beta_reasoning_menu_current "$window_id" || true)"
  if [[ "$current_menu_reasoning" == "$reasoning" ]]; then
    send_key "$window_id" Enter
    return 0
  fi

  reasoning_number="$(beta_picker_reasoning_number "$window_id" "$reasoning" || true)"
  if [[ -n "$reasoning_number" ]]; then
    send_key "$window_id" "$reasoning_number"
  else
    # Fallback to hardcoded key mapping
    send_key "$window_id" "$(beta_reasoning_key "$reasoning")"
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

  beta_validate_model "$model"
  beta_reasoning_key "$reasoning" >/dev/null

  beta_launch_if_needed "$window_id"
  current_model="$(beta_current_model "$window_id" || true)"
  current_reasoning="$(beta_current_reasoning "$window_id" || true)"

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

  beta_wait_for_state "$window_id" "$model" "$reasoning" "$GRAND_ORCHESTRATOR_BETA_TIMEOUT_DEFAULT" 0.1

  printf 'OK beta window=%s state="%s"\n' "$window_id" "$(beta_state_line "$window_id")"
}

if [[ "${GRAND_ORCHESTRATOR_BETA_TEST_MODE:-0}" != "1" ]]; then
  main "$@"
fi
