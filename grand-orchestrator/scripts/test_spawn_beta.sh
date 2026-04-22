#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export GRAND_ORCHESTRATOR_BETA_TEST_MODE=1

source "$SCRIPT_DIR/spawn_beta.sh"

capture_screen_output=""
set_capture_screen() {
  capture_screen_output="$1"
  beta_capture_screen() {
    printf '%s\n' "$capture_screen_output"
  }
}

assert_success_picker_model_number() {
  local name="$1"
  local expected="$2"
  local model="$3"
  local screen="$4"
  local scan_lines="${5:-}"
  local output
  local status

  set_capture_screen "$screen"
  set +e
  if [[ -n "$scan_lines" ]]; then
    output="$(GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES="$scan_lines" beta_picker_model_number "@w" "$model" 2>&1)"
  else
    output="$(beta_picker_model_number "@w" "$model" 2>&1)"
  fi
  status=$?
  set -e

  if [[ "$status" != "0" || "$output" != "$expected" ]]; then
    echo "FAIL $name"
    echo "  expected: $expected"
    echo "  got status=$status output=$output"
    return 1
  fi

  echo "PASS $name"
  return 0
}

assert_fail_picker_model_number() {
  local name="$1"
  local expected_fragment="$2"
  local model="$3"
  local screen="$4"
  local output
  local status

  set_capture_screen "$screen"
  set +e
  output="$(beta_picker_model_number "@w" "$model" 2>&1)"
  status=$?
  set -e

  if [[ "$status" == "0" ]]; then
    echo "FAIL $name"
    echo "  expected failure, got status=0 output=$output"
    return 1
  fi

  if [[ "$output" != *"$expected_fragment"* ]]; then
    echo "FAIL $name"
    echo "  expected error containing: $expected_fragment"
    echo "  got: $output"
    return 1
  fi

  echo "PASS $name"
  return 0
}

assert_success_picker_reasoning_number() {
  local name="$1"
  local expected="$2"
  local reasoning="$3"
  local screen="$4"
  local scan_lines="${5:-}"
  local output
  local status

  set_capture_screen "$screen"
  set +e
  if [[ -n "$scan_lines" ]]; then
    output="$(GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES="$scan_lines" beta_picker_reasoning_number "@w" "$reasoning" 2>&1)"
  else
    output="$(beta_picker_reasoning_number "@w" "$reasoning" 2>&1)"
  fi
  status=$?
  set -e

  if [[ "$status" != "0" || "$output" != "$expected" ]]; then
    echo "FAIL $name"
    echo "  expected: $expected"
    echo "  got status=$status output=$output"
    return 1
  fi

  echo "PASS $name"
  return 0
}

assert_success_key_name() {
  local name="$1"
  local expected="$2"
  local model="$3"
  local output
  local status

  set +e
  output="$(beta_model_key_from_name "$model" 2>&1)"
  status=$?
  set -e

  if [[ "$status" != "0" || "$output" != "$expected" ]]; then
    echo "FAIL $name"
    echo "  expected: $expected"
    echo "  got status=$status output=$output"
    return 1
  fi

  echo "PASS $name"
  return 0
}

assert_fail_key_name() {
  local name="$1"
  local expected_fragment="$2"
  local model="$3"
  local output
  local status

  set +e
  output="$(beta_validate_model "$model" 2>&1)"
  status=$?
  set -e

  if [[ "$status" == "0" ]]; then
    echo "FAIL $name"
    echo "  expected failure, got status=0 output=$output"
    return 1
  fi

  if [[ "$output" != *"$expected_fragment"* ]]; then
    echo "FAIL $name"
    echo "  expected error containing: $expected_fragment"
    echo "  got: $output"
    return 1
  fi

  echo "PASS $name"
  return 0
}

sent_key=""
sent_keys=""
sent_window=""
mock_send_key() {
  sent_window="$1"
  sent_key="$2"
  if [[ -z "$sent_keys" ]]; then
    sent_keys="$2"
  else
    sent_keys+=",${2}"
  fi
}

sent_open_model_picker=0
mock_open_model_picker() {
  sent_open_model_picker=1
}

mock_wait_until_model_applied() {
  :
}

override_for_select_model() {
  send_key() { mock_send_key "$@"; }
  beta_open_model_picker() { mock_open_model_picker "$@"; }
  beta_wait_until_model_applied() { mock_wait_until_model_applied "$@"; }
  sent_key=""
  sent_keys=""
  sent_window=""
  sent_open_model_picker=0
}

assert_success_select_model() {
  local name="$1"
  local expected_key="$2"
  local model="$3"
  local screen="$4"
  local scan_lines="${5:-}"
  local status

  set_capture_screen "$screen"
  override_for_select_model

  set +e
  if [[ -n "$scan_lines" ]]; then
    GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES="$scan_lines" beta_select_model "@w" "$model"
  else
    beta_select_model "@w" "$model"
  fi
  status=$?
  set -e

  if [[ "$status" != "0" ]]; then
    echo "FAIL $name"
    echo "  expected success, got status=$status"
    return 1
  fi

  if [[ "$sent_open_model_picker" -ne 1 || "$sent_window" != "@w" || "$sent_key" != "$expected_key" ]]; then
    echo "FAIL $name"
    echo "  expected window picker opened and key=$expected_key"
    echo "  sent_window=$sent_window sent_key=$sent_key sent_open_model_picker=$sent_open_model_picker"
    return 1
  fi

  echo "PASS $name"
  return 0
}

assert_success_select_reasoning() {
  local name="$1"
  local expected_keys="$2"
  local reasoning="$3"
  local screen="$4"
  local scan_lines="${5:-}"
  local status

  set_capture_screen "$screen"
  override_for_select_model

  set +e
  if [[ -n "$scan_lines" ]]; then
    GRAND_ORCHESTRATOR_BETA_ACTIVE_SCREEN_LINES="$scan_lines" beta_select_reasoning "@w" "$reasoning"
  else
    beta_select_reasoning "@w" "$reasoning"
  fi
  status=$?
  set -e

  if [[ "$status" != "0" ]]; then
    echo "FAIL $name"
    echo "  expected success, got status=$status"
    return 1
  fi

  if [[ "$sent_keys" != "$expected_keys" ]]; then
    echo "FAIL $name"
    echo "  expected keys=$expected_keys"
    echo "  sent_keys=$sent_keys"
    return 1
  fi

  echo "PASS $name"
  return 0
}

failures=0
run_test() {
  if ! "$@"; then
    failures=$((failures + 1))
  fi
}

run_test assert_success_picker_model_number \
  "picker model number scans whole screen (target above active tail)" \
  "1" \
  "gpt-5.4" \
  $'1. gpt-5.4\n2. gpt-5.4-mini\n3. gpt-5.3-codex\n4. gpt-5.3-codex-spark' \
  "3"

run_test assert_success_picker_model_number \
  "picker model number supports dot separator" \
  "3" \
  "gpt-5.3-codex-spark" \
  $'1. gpt-5.4\n2. gpt-5.4-mini\n3. gpt-5.3-codex-spark'

run_test assert_success_picker_model_number \
  "picker model number supports alternative row separators" \
  "3" \
  "gpt-5.3-codex-spark" \
  $'1) gpt-5.4\n2) gpt-5.4-mini\n3) gpt-5.3-codex-spark'

run_test assert_success_picker_model_number \
  "picker model number supports bullet separator" \
  "3" \
  "gpt-5.3-codex-spark" \
  $'1 · gpt-5.4\n2 · gpt-5.4-mini\n3 · gpt-5.3-codex-spark'

run_test assert_fail_picker_model_number \
  "picker model number fails when target model is missing" \
  "not found in picker" \
  "gpt-5.4" \
  $'1. gpt-5.4-mini\n2. gpt-5.3-codex\n3. gpt-5.3-codex-spark'

run_test assert_success_key_name \
  "model key validates supported model name" \
  "gpt-5.4" \
  "gpt-5.4"

run_test assert_fail_key_name \
  "model key rejects unsupported model name" \
  "unsupported beta model" \
  "gpt-5.2"

run_test assert_success_select_model \
  "beta_select_model sends resolved key from picker row" \
  "3" \
  "gpt-5.3-codex-spark" \
  $'1. gpt-5.4\n2. gpt-5.4-mini\n3. gpt-5.3-codex-spark'

run_test assert_success_select_model \
  "beta_select_model handles selected-row marker" \
  "3" \
  "gpt-5.3-codex-spark" \
  $'> 1. gpt-5.4\n 2. gpt-5.4-mini\n 3. gpt-5.3-codex-spark'

run_test assert_success_select_model \
  "beta_select_model scans whole screen for model row" \
  "1" \
  "gpt-5.4" \
  $'1. gpt-5.4\n2. gpt-5.4-mini\n3. gpt-5.3-codex\n4. gpt-5.3-codex-spark' \
  "3"

run_test assert_success_picker_reasoning_number \
  "picker reasoning number scans whole screen (target above active tail)" \
  "1" \
  "low" \
  $'Select Reasoning Level for gpt-5.4\n1. low\n2. medium\n3. high\n4. extra high' \
  "2"

run_test assert_success_picker_reasoning_number \
  "picker reasoning number supports bullet separator" \
  "3" \
  "high" \
  $'Select Reasoning Level for gpt-5.4\n1 · low\n2 · medium\n3 · high\n4 · extra high'

run_test assert_success_select_reasoning \
  "beta_select_reasoning sends resolved key from row picker" \
  "3" \
  "high" \
  $'Select Reasoning Level for gpt-5.4\n1. low\n2. medium\n3. high\n4. extra high'

run_test assert_success_select_reasoning \
  "beta_select_reasoning scans whole screen for current menu" \
  "1" \
  "low" \
  $'Select Reasoning Level for gpt-5.4\n1. low\n2. medium\n3. high\n4. extra high' \
  "2"

run_test assert_success_select_reasoning \
  "beta_select_reasoning falls back to key when row number missing" \
  "3" \
  "high" \
  $'Select Reasoning Level for gpt-5.4\nlow\nmedium\nhigh\nextra high'

if (( failures > 0 )); then
  echo "FAILED: $failures"
  exit 1
fi

echo "PASS all spawn_beta tests"
