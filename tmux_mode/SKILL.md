---
name: tmux-mode-orchestrator
description: Activates when the user says "tmux mode". Runs a discovery-first, window-based tmux orchestrator inside the current tmux session. Each subagent is a tmux window (tab) visible in Oh My Tmux. Uses context lanes instead of rigid categories, file-based outputs, and keystroke-based inputs across Claude, Codex, Amp, and OpenCode.
---

# Tmux Mode Orchestrator (Discovery-First, Window-Based)

Trigger this skill when the user says exactly or clearly intends: **"tmux mode"**.

This skill turns tmux into a persistent multi-agent runtime. It is optimized for **Oh My Tmux tabs** and for **warm context reuse**.

It does **not** start from rigid predefined categories.

Instead, it uses this flow:

1. survey the work first
2. run discovery against task + repo + existing lane context
3. infer a context profile
4. find or create the best warm lane
5. route the task into a tmux window
6. keep the lane warm through concise context files

This skill uses:

- **one tmux session**: your current tmux session
- **one subagent = one tmux window**
- **keystrokes = input**
- **files = output**
- **`.tmux/` = durable reconciler**
- **context lanes = persistent warm specialists**

All checked-in tmux helper scripts live at the fixed path prefix `~/skills/tmux_mode/scripts/`. Do not derive this path from the current repo location or workdir.

## Core principles

1. Each lane window is persistent and reusable.
2. Each lane is identified by: workdir abbreviation, phase (`doc` or `code`), reasoning tier (`sm`/`md`/`lg`/`xl`), and a short discovered lane label.
3. Input is delivered by injecting keystrokes into the tmux window.
4. Output is returned by having the agent write structured files.
5. `.tmux/<lane_key>/` is the durable source of truth.
6. Tmux window names should be human-navigable and include the workdir name, phase, reasoning tier, and lane label.
7. Warm lanes should be reused when context match is strong.
8. Model or mode selection happens during provisioning and is written into metadata, not encoded into the lane name.
9. Lane labels are derived from discovery, not hand-authored catalogs.
10. The orchestrator owns lane creation, escalation, repair, reuse, and delegation.

## CRITICAL: Two hard rules the orchestrator must never break

### Rule 1 — Use `tmux_runtime.sh` helpers and spawn scripts, never raw tmux commands

**NEVER** compose raw `tmux send-keys`, `tmux new-window`, `tmux kill-window`, `tmux rename-window`, or `tmux capture-pane` commands directly. Always use `tmux_runtime.sh` helpers:

```bash
WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"   # not tmux new-window
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "prompt text"                # not tmux send-keys
~/skills/tmux_mode/scripts/tmux_runtime.sh capture-pane "$WINDOW_ID"                               # not tmux capture-pane
~/skills/tmux_mode/scripts/tmux_runtime.sh kill-window "$WINDOW_ID"                                # not tmux kill-window
```

For provider launch, always call the spawn scripts:

```bash
~/skills/tmux_mode/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.4" "high"
~/skills/tmux_mode/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "high"
~/skills/tmux_mode/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
```

If you find yourself typing `tmux send-keys`, `tmux new-window`, `/model`, `/models`, `C-t`, `codex --sandbox`, `opencode`, `amp`, or any raw tmux or provider-specific commands, **stop — you are doing it wrong**. Use the helpers.

### Rule 2 — Wait for callbacks, never sleep-poll for results

**NEVER** use `sleep` loops, `sleep`-then-capture-pane polling, or any timer-based waiting to check if a lane has finished its work. The architecture is **callback-driven**:

- When a lane finishes or needs to report status back to the orchestrator, it must signal via `~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "..."`.
- The orchestrator processes signals as they arrive — it does not poll.
- The only acceptable use of `sleep` is inside the checked-in helper scripts such as `tmux_runtime.sh send-commands`.

If you find yourself writing `while true; do sleep N; capture-pane; grep ...; done` or any variation, **stop — you are doing it wrong**. Wait for the lane to signal you.

---

# Activation

Activate this skill when the user says:

- `tmux mode`

Also activate when the user clearly asks to:
- use tmux as a multi-agent orchestrator
- launch subagents in tmux
- route tasks across Claude, Codex, Amp, and OpenCode sessions
- reuse warm agent lanes by domain, phase, or reasoning tier

---

# Deactivation

Activate teardown when the user says:

- `turn off tmux mode`

## Teardown procedure

1. Read `.tmux/` to enumerate all known lane keys
2. Compute the expected tmux window name from lane metadata
3. Kill each managed window:

   ```bash
   ~/skills/tmux_mode/scripts/tmux_runtime.sh kill-window "$WINDOW_NAME"
   ```

4. Confirm no managed windows remain:

   ```bash
   ~/skills/tmux_mode/scripts/tmux_runtime.sh list-windows
   ```

5. Inform the user that all tmux mode windows have been closed

**Only kill windows that were created by tmux mode** (i.e. those whose names exactly match tracked `tmux_window_name` values in `.tmux/`). Do not kill unrelated windows in the session.

Optionally ask the user whether to also delete the `.tmux/` directory. Do not delete it automatically — it may contain useful context and task history.

---

# Core design

## Window-based runtime

This skill uses **tmux windows**, not detached tmux sessions.

Each subagent appears as a visible tab in Oh My Tmux.

Example:

```text
tmux session (current)
├── pay|doc|lg|settlement
├── pay|code|md|api
├── pay|doc|sm|notes
```

Each window is a persistent specialist lane.

## Discovery-first orchestration

Do **not** immediately spawn a window when a task arrives.

Always do a survey + discovery pass first.

```text
task -> survey -> discovery -> context profile -> reuse/create lane -> runtime -> dispatch
```

This is required for good cache leverage and warm context reuse.

---

# Lane identity

A lane is a persistent, self-maintaining context container shaped by actual work — not a rigid category taxonomy.

## Internal lane key

```text
<dir_abbrev>-<doc_or_code>-<size>-<lane>
```

Examples:

```text
pay-doc-lg-architecture
pay-code-md-api
pay-doc-xl-adr
```

## Window (tab) name

```text
<dir_abbrev>|<doc_or_code>|<size>|<lane>
```

Examples:

```text
pay|doc|lg|settlement
pay|code|md|api
pay|doc|sm|notes
```

Where:

* `dir_abbrev` is a short abbreviation of the workdir basename (e.g. first 3–5 chars: `payments` → `pay`, `frontend` → `fe`, `infra` → `inf`)
* `doc_or_code` is the phase marker: `doc` for decision-phase work, `code` for coding-phase work
* `size` is the reasoning tier: `sm` = low, `md` = medium, `lg` = high, `xl` = extra_high
* `lane` is the short discovered lane label (e.g. `settlement`, `api`, `refactor`)

The `|` separator makes lanes scannable in the Oh My Tmux tab bar at a glance.

Use `-` for the internal `lane_key` and folder name, and `|` for the tmux window name. Provider, model, and mode are metadata, not naming components.

## Lane label convention

Lane labels are short and derived from discovered context, not hand-authored, for example:

```text
settlement
api
refactor
frontend
ledger
auth
query
infra
```

Avoid long, overfit names unless truly needed.

---

# Directory layout

Use `.tmux/` at the repo/workdir root.

```text
.tmux/
  runtime.yaml
  lanes.yaml
  shared_board.yaml
  journal.md                    ← orchestrator running log
  pay-doc-lg-settlement/
    meta.yaml
    status.yaml
    context/
      summary.md
      glossary.md
      assumptions.md
      hotspots.md
      recent_findings.md
      last_delta.yaml
    inbox/
    outbox/
    requests/                   ← lane-local requests for orchestrator-owned global state
    logs/
      journal.md                ← lane running log
      pane.latest.txt           ← latest pane capture (poll_window.sh)
  pay-code-md-api/
    ...
  pay-doc-sm-notes/
    ...
```

`.tmux/<lane_key>/` is the durable reconciler and source of truth.

The tmux window is the live runtime.

---

# Task decomposition via survey

Before routing or splitting any task, **survey the work first**. The task may not be a codebase — it could be a list of PRs, a set of tickets, a batch of documents, a collection of issues, etc.

## Survey step

Ask: what is the shape of the work?

- **Codebase task** → run `tree -L 3` to understand directory/module structure and find natural split points
- **PR review batch** → list the PRs (e.g. via `gh pr list`), understand scope and overlap of each
- **Ticket/issue batch** → enumerate the tickets, understand dependencies and domains
- **Document/file batch** → list the files, understand groupings
- **Mixed** → survey all dimensions before deciding

The survey output is the input to discovery. Do not skip it.

## Decomposition step

After surveying:

1. Identify natural boundaries (modules, PRs, domains, file groups)
2. Estimate how many sub-tasks make sense based on:
   - independence (can they run in parallel?)
   - size and complexity per unit
   - domain separation
3. Produce an explicit task split plan before provisioning any windows

Example — codebase:

```text
tree shows: src/payments/  src/ledger/  src/gateway/

→ task-001: payments reconciliation  → beta
  task-002: ledger mismatch fix      → beta
  task-003: gateway report parsing   → beta
```

Example — PR review batch:

```text
gh pr list shows: PR #41 (auth), PR #42 (payments), PR #43 (infra)

→ task-001: review PR #41  → beta
  task-002: review PR #42  → beta
  task-003: review PR #43  → beta
```

Default to more splits rather than fewer. One big task per window is usually wrong.

---

# Discovery-first workflow

After the survey, run a discovery pass before spawning or reusing any lane.

## Discovery goals

Infer:

* what the task is really about
* which code/docs/dirs are relevant
* whether an existing lane already matches
* what provider/runtime is appropriate
* whether large context is needed (if so, use a `gpt-5.4` runtime at at least medium reasoning, via `beta` or `delta`)

## Discovery sources

Inspect as appropriate:

* user task text
* current workdir name
* repo structure (from survey)
* likely relevant directories/files
* docs such as `README`, `docs/`, `specs/`
* existing `.tmux/*/context/summary.md`
* existing `.tmux/*/context/hotspots.md`
* recent lane outputs in `.tmux/*/outbox/`

Do a small but real dig before deciding.

## Discovery output: context profile

Produce a compact context profile:

```yaml
domain: payments settlement flow
task_shape: investigation
hotspots:
  - internal/settlement
  - internal/ledger
  - docs/reconciliation
needs_code_changes: false
needs_large_context: false
phase: doc
size: lg
allowed_runtimes:
  - gamma:smart
  - beta:gpt-5.4:high
  - delta:gpt-5.4:high
suggested_lane: settlement
```

This profile drives lane reuse or creation.

---

# Lane reuse and creation

After discovery, score existing lanes.

## Reuse scoring factors

Score lanes based on:

* overlap with `context/summary.md`
* overlap with `context/hotspots.md`
* glossary term overlap
* same workdir
* same or similar task shape
* recent usage recency
* runtime suitability

## Reuse decision

Reuse a lane if:

* similarity score is above threshold (default: 0.72)
* runtime is suitable
* window is healthy
* context drift is acceptable

Otherwise create a new lane.

## Lane creation principle

Create new lanes from discovered context, not from a rigid catalog.

---

# Lane self-management

Lanes manage their own context files. The orchestrator controls topology.

## Lane-owned knowledge state

A lane maintains:

* `context/summary.md` — what this lane is about
* `context/glossary.md` — stable domain vocabulary
* `context/assumptions.md` — reusable assumptions and invariants
* `context/hotspots.md` — important files, directories, modules, docs
* `context/recent_findings.md` — recent useful learnings
* `context/last_delta.yaml` — most recent proposed knowledge update

### Context file templates

Agents must create these files when initializing a lane. Copy the skeletons below and fill in discovered values.

#### `context/summary.md`

```markdown
# Lane summary: <lane_label>

## Domain
<1-2 sentences: what area of the codebase/system this lane covers>

## Current focus
<1-2 sentences: what the lane is actively working on or was last working on>

## Key invariants
- <invariant 1>
- <invariant 2>
```

#### `context/glossary.md`

```markdown
# Glossary: <lane_label>

| Term | Definition |
|------|-----------|
| <term> | <short definition> |
```

#### `context/assumptions.md`

```markdown
# Assumptions: <lane_label>

- **<assumption>** — <basis or source> (confidence: high/medium/low)
```

#### `context/hotspots.md`

```markdown
# Hotspots: <lane_label>

## Files
- `<path/to/file>` — <why it matters>

## Directories
- `<path/to/dir/>` — <what lives here>

## Docs
- `<path/to/doc>` — <relevance>
```

#### `context/recent_findings.md`

```markdown
# Recent findings: <lane_label>

## [<ISO-timestamp>] <short title>
<1-3 sentences: what was learned and why it matters for future tasks>
```

Keep all context files concise. Prune `recent_findings.md` to the 5-10 most relevant entries. Update `glossary.md` and `assumptions.md` only when terms or assumptions are reusable beyond a single task.

## Orchestrator-owned responsibilities

The orchestrator owns:

* when to create a lane
* when to reuse a lane
* when to retire or reset a lane
* when to escalate runtime
* when to merge or ignore context deltas
* minting global task ids and question ids
* updating global registry files from lane-local requests

Lanes manage knowledge. Orchestrator manages structure.

## File ownership table

`O` = orchestrator, `L` = lane agent.

| File | Created by | Updated by | Notes |
|------|-----------|-----------|-------|
| `.tmux/runtime.yaml` | O | O | L never touches |
| `.tmux/lanes.yaml` | O | O | Orchestrator-owned topology and lane index |
| `.tmux/shared_board.yaml` | O | O | Orchestrator-owned canonical board state |
| `.tmux/journal.md` | O | O | Orchestrator running log; L never writes |
| `meta.yaml` | O | O + L | O creates and updates identity/runtime fields; L updates `scope_keywords` |
| `status.yaml` | O | O + L | O creates and updates dispatch/provisioning fields; L updates `state`, `needs_input`, `blocked_reason`, `last_heartbeat` |
| `context/summary.md` | L | L | |
| `context/glossary.md` | L | L | |
| `context/assumptions.md` | L | L | |
| `context/hotspots.md` | L | L | |
| `context/recent_findings.md` | L | L | |
| `context/last_delta.yaml` | L | L | O reads; O may delete after merge |
| `inbox/<task>.yaml` | O | O | L reads only; O owns lifecycle |
| `outbox/<task>.result.yaml` | L | L | O reads; O may delete/archive |
| `requests/*.yaml` | L | L | Lane-local requests that ask the orchestrator to update global files |
| `logs/journal.md` | L | L | Lane running log; O never writes |
| `logs/pane.latest.txt` | O | O | Written by poll; L never touches |

Lanes must not delete inbox or outbox files. The orchestrator owns file lifecycle for both.

Global files at `.tmux/` root are orchestrator-only. If a lane needs to update global state such as `.tmux/lanes.yaml` or `.tmux/shared_board.yaml`, it must write a lane-local request file in `requests/` and signal the orchestrator. The orchestrator then applies the update.

Field ownership for duplicated lane state:

* `meta.yaml` is first-class lane state for identity and live runtime facts: `lane_key`, `tmux_window_name`, `tmux_window_id`, `provider`, `model`, `mode`, `reasoning`, `phase`, `size`, `lane`, `workdir`, `workdir_name`, `context_profile`, `verified`, `created_at`, and `scope_keywords`
* `.tmux/lanes.yaml` is first-class orchestrator index state: lane registry, topology summary, `last_used_at`, and `warmth_score`
* if a field appears in both places, the orchestrator must treat `meta.yaml` as authoritative for identity/runtime fields and `.tmux/lanes.yaml` as authoritative for orchestrator index fields
* when the orchestrator refreshes a live window, repairs a lane, or mirrors scope changes from a lane-local request, it must update both files as needed so overlapping facts do not drift

---

# Shared board

The shared board is the orchestrator-owned coordination layer for cross-lane questions. Lanes do not write `.tmux/shared_board.yaml` directly. Instead, they write lane-local request files in `.tmux/<lane_key>/requests/` and signal the orchestrator. The orchestrator reflects those requests into `.tmux/shared_board.yaml` and, when needed, `.tmux/lanes.yaml`.

## Board file

`.tmux/shared_board.yaml` — a single YAML list of board entries.

Create it as an empty list if it does not exist:

```yaml
[]
```

## Board entry schema

```yaml
- question_id: q-001
  asked_by_lane: pay-code-md-api
  asked_by_window_name: pay|code|md|api
  question: Does the settlement cutoff apply in gateway local time or UTC?
  target_lane: pay-doc-lg-settlement
  target_window_name: pay|doc|lg|settlement
  answer: null
  status: pending
  asked_at: "2026-03-31T10:25:00Z"
  answered_at: null
  acked_at: null
```

`status` values:

```text
pending       — question written, waiting for orchestrator to route
routed        — orchestrator sent keystrokes to target agent
answered      — target agent wrote an answer
ack           — questioner acknowledged the answer
self-resolved — no other lane owned the topic; questioner dug deeper and resolved it
ambiguous     — more than one lane matched; orchestrator must fix lane criteria or topology
```

`question_id` values are orchestrator-minted. Lanes may use simple local counting for request filenames inside their own `requests/` directory, but only the orchestrator assigns global `q-###` ids.

## Lane-local question request

If a lane needs help from another lane, it writes a lane-local request file such as `.tmux/pay-code-md-api/requests/question-001.yaml`:

```yaml
request_type: question
local_request_id: question-001
from_lane: pay-code-md-api
from_window_name: pay|code|md|api
question: Does the settlement cutoff apply in gateway local time or UTC?
ownership_matches: 1
candidate_target_lane: pay-doc-lg-settlement
self_resolved: false
answer: null
status: pending
```

For self-resolved questions, set `ownership_matches: 0`, `self_resolved: true`, and populate `answer` with a brief summary. For ambiguous ownership, set `ownership_matches` to the number of matching lanes and leave `candidate_target_lane: null`.

## Agent flow: mid-task question

When a lane hits a question it cannot confidently answer on its own:

### Step 1 — check other lanes' scope

Read all `.tmux/*/meta.yaml` files. Scan `scope_keywords` of each lane.

If exactly one lane's `scope_keywords` overlap with the topic of the question → that lane is the target.

If no lane's `scope_keywords` match → the current agent self-resolves (see step 3b).

If more than one lane matches → do not pick a winner. Treat this as ambiguous ownership and escalate to the orchestrator via a request file. The fix belongs in lane criteria or topology, not in a hidden tie-break rule.

### Step 2 — write a lane-local request and signal the orchestrator

Write a lane-local request file in `requests/` with:

- `status: "pending"`
- `ownership_matches`
- `candidate_target_lane` set only if exactly one lane matched
- `answer: null` unless `self_resolved: true`

Then signal the orchestrator:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "Board request posted at .tmux/pay-code-md-api/requests/question-001.yaml. Check it."
```

The agent should then continue with whatever it can do independently while waiting. It does not block unless the answer is strictly required.

### Step 3b — self-resolve (no matching lane)

If no other lane owns the topic:

1. Update own `meta.yaml` — add the new topic to `scope_keywords` **before** digging
2. Investigate the question
3. Update `meta.yaml` again after — confirm the expanded scope reflects what was learned
4. Write a lane-local request file in `requests/` with `self_resolved: true`, populate `answer` with a brief summary, and include any scope keywords that were added
5. Signal the orchestrator:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "Board request posted at .tmux/pay-code-md-api/requests/question-001.yaml with self_resolved=true. Check it."
```

## Orchestrator flow: routing a question

When the orchestrator receives a board request signal:

1. Read the lane-local request file in `.tmux/<lane_key>/requests/`
2. Mint the next global `question_id`
3. If `ownership_matches == 0` and `self_resolved == true`:
   - append a `self-resolved` entry to `.tmux/shared_board.yaml`
   - sync `.tmux/lanes.yaml` from the lane's updated `meta.yaml`
   - no routing is needed
4. If `ownership_matches == 1`:
   - append a `pending` entry to `.tmux/shared_board.yaml`
   - resolve the target lane's current `tmux_window_id` from its `meta.yaml`
   - inject keystrokes into the target window with the question and the path to the board entry:

```bash
TARGET_WINDOW_ID="@12"
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$TARGET_WINDOW_ID" "Board question q-001 from pay|code|md|api: 'Does the settlement cutoff apply in gateway local time or UTC?' Read .tmux/shared_board.yaml entry q-001. Write your answer to .tmux/pay-doc-lg-settlement/requests/answer-q-001.yaml. Then signal the orchestrator."
```

   - update the board entry's `status` to `routed`
5. If `ownership_matches > 1`:
   - append an `ambiguous` entry to `.tmux/shared_board.yaml`
   - do not route it
   - treat it as a topology or lane-criteria issue and fix the lane boundaries before continuing

## Target agent flow: answering

When the target agent receives a board question via keystrokes:

1. Read the board entry from `.tmux/shared_board.yaml`
2. Write a lane-local request file such as `.tmux/pay-doc-lg-settlement/requests/answer-q-001.yaml`
3. The filename is the signal. The file contents may be just the answer text or a tiny note for the orchestrator; no additional answer schema is required
4. Signal the orchestrator:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "Board answer posted at .tmux/pay-doc-lg-settlement/requests/answer-q-001.yaml. Check it."
```

## Orchestrator flow: delivering the answer

When the orchestrator receives an answered signal:

1. Read the answer request file
2. Update `.tmux/shared_board.yaml` with `answer`, `status: answered`, and `answered_at`
3. Resolve the questioner lane's current `tmux_window_id` from its `meta.yaml`
4. Inject keystrokes into the questioner window with the answer:

```bash
QUESTIONER_WINDOW_ID="@13"
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$QUESTIONER_WINDOW_ID" "Board answer for q-001: '<answer text>'. Acknowledge by writing .tmux/pay-code-md-api/requests/ack-q-001.yaml and then signal the orchestrator."
```

## Questioner flow: acknowledging

When the questioner receives the answer:

1. Write `.tmux/<lane_key>/requests/ack-q-001.yaml`
2. The filename is the signal. No additional ack schema is required
3. Signal the orchestrator:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "Board ack posted at .tmux/pay-code-md-api/requests/ack-q-001.yaml. Check it."
```

## Orchestrator flow: acknowledging

When the orchestrator receives an ack signal:

1. Read the ack request file
2. Update `.tmux/shared_board.yaml` entry `q-001` with `status: ack` and `acked_at`
3. Mark the request file handled or archive it

## Chain reaction summary

```text
agent posts question → signals orchestrator
  → orchestrator routes question to target → marks routed
    → target answers → signals orchestrator
      → orchestrator delivers answer to questioner
        → questioner acks → signals orchestrator
          → orchestrator confirms resolved
```

Each signal triggers the next action. There is no timer. The user is the safety net.

---

# Window reconciliation

Each `.tmux/<lane_key>/` directory implies the lane should exist.

Check live windows using:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh list-windows
```

For each lane directory:

1. Compute expected window name from `meta.yaml` field `tmux_window_name`
2. Check `~/skills/tmux_mode/scripts/tmux_runtime.sh list-windows`
3. If present → resolve the current live `tmux_window_id` from tmux and refresh metadata before reusing it
4. If missing → create the window
5. If broken or stale → reset it

## Create window

Always use `create_window` from `tmux_runtime.sh`. It handles `-d` (no focus steal), captures the window id, and renames atomically — avoiding the common bug where a bare `tmux rename-window` renames the orchestrator window instead:

```bash
WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
```

## Kill broken window

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh kill-window "$WINDOW_ID"
```

## Rename drifted window

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh rename-window "$OLD_NAME" "$NEW_NAME"
```

## Window name is permanent

The window name is the lane name and never changes during task execution. The `tmux_window_id` is the live tmux handle and may change if the window is recreated.

```text
pay|doc|lg|settlement   ← always, whether idle or running
```

Do not rename the window when a task is dispatched or when it completes. The lane is the window's permanent identity.

---

# Runtime configuration

Create `.tmux/runtime.yaml`:

```yaml
version: 1

naming:
  lane_key: "<dir_abbrev>-<doc_or_code>-<size>-<lane>"
  tmux_window_name: "<dir_abbrev>|<doc_or_code>|<size>|<lane>"
  # tmux_window_id is not a naming template. It is the live tmux handle
  # written into each lane's meta.yaml after window creation or repair.

reuse:
  threshold: 0.72
  stale_after_hours: 24

providers:
  beta:
    launch_cmd: "codex --sandbox danger-full-access"
    selector_kind: "interactive_menu"
    open_selector: "/model"
    models:
      gpt-5.4:
        key: "1"
        note: "general-purpose high-capability Codex model"
      gpt-5.4-mini:
        key: "2"
        note: "lightweight Codex model for bounded large-context or mechanical work"
      gpt-5.3-codex:
        key: "3"
        note: "coding-specialist Codex model"
    reasoning_levels:
      # after model selection, send a number key (no Enter needed)
      low:
        key: "1"
      medium:
        key: "2"
      high:
        key: "3"
      extra_high:
        key: "4"
        note: "reserved for architectural, high-level, executive, ADR, and planning tasks only"

  delta:
    launch_cmd: "opencode"
    selector_kind: "exact_text_entry_then_variant_screen_cycle"
    open_selector: "/models"
    variant_screen_title: "Select variant"
    variant_screen_exit_key: "Enter"
    models:
      gpt-5.4:
        picker_label: "GPT-5.4 OpenAI"
        note: "general-purpose high-capability OpenCode model"
      gpt-5.4-mini:
        picker_label: "GPT-5.4 mini OpenAI"
        note: "lightweight OpenCode model for bounded decision work"
      gpt-5.3-codex:
        picker_label: "GPT-5.3 Codex OpenAI"
        note: "coding-specialist OpenCode model"
    reasoning_levels:
      low:
        ui_label: "low"
      medium:
        ui_label: "medium"
      high:
        ui_label: "high"
      extra_high:
        ui_label: "xhigh"
        note: "UI shows xhigh; metadata remains extra_high"
    readiness_markers:
      - "Build"
      - "ctrl+p commands"
    reasoning_detection_source: "whole_screen_build_regex"
    reasoning_screen_regex: "Build\\s+.+?(?:·\\s*(none|low|medium|high|xhigh))?$"
    empty_reasoning_when_no_build_suffix: true
    reasoning_toggle_key: "C-t"
    reasoning_cycle_order:
      - empty
      - none
      - low
      - medium
      - high
      - xhigh
    disallowed_reasoning_states:
      - empty
      - none

  gamma:
    launch_cmd: "amp"
    mode_switch_prefix: "/"
    modes:
      smart:
        command: "smart"
        note: "default Amp mode; equivalent to gpt-5.4 at medium-high reasoning"
      rush:
        command: "rush"
        note: "lightweight Amp mode; equivalent to gpt-5.4-mini"
    max_active_windows: 2

defaults:
  discovery_lane:
    phase: doc
    size: md

runtime_bands:
  doc:
    sm:
      allowed:
        - provider: gamma
          mode: rush
        - provider: beta
          model: gpt-5.4-mini
          reasoning: low
        - provider: delta
          model: gpt-5.4-mini
          reasoning: low
    md:
      allowed:
        - provider: gamma
          mode: smart
        - provider: beta
          model: gpt-5.4
          reasoning: medium
        - provider: delta
          model: gpt-5.4
          reasoning: medium
    lg:
      allowed:
        - provider: gamma
          mode: smart
        - provider: beta
          model: gpt-5.4
          reasoning: high
        - provider: delta
          model: gpt-5.4
          reasoning: high
    xl:
      allowed:
        - provider: beta
          model: gpt-5.4
          reasoning: extra_high
        - provider: delta
          model: gpt-5.4
          reasoning: extra_high
  code:
    sm:
      allowed:
        - provider: beta
          model: gpt-5.3-codex
          reasoning: low
        - provider: delta
          model: gpt-5.3-codex
          reasoning: low
    md:
      allowed:
        - provider: beta
          model: gpt-5.3-codex
          reasoning: medium
        - provider: delta
          model: gpt-5.3-codex
          reasoning: medium
    lg:
      allowed:
        - provider: beta
          model: gpt-5.3-codex
          reasoning: high
        - provider: delta
          model: gpt-5.3-codex
          reasoning: high
    xl:
      allowed:
        - provider: beta
          model: gpt-5.3-codex
          reasoning: extra_high
        - provider: delta
          model: gpt-5.3-codex
          reasoning: extra_high

# Written by orchestrator when context limit approaches (see "Orchestrator session limits").
# Null or absent during normal operation.
resume_hint: null
```

---

# Lanes registry

Use `.tmux/lanes.yaml` for lightweight lane metadata. This is not a rigid predefined catalog — it is a summary index of discovered lanes.

Create `.tmux/lanes.yaml` on fresh start as:

```yaml
version: 1
lanes: {}
```

This file is the orchestrator's first-class summary index. It should track registry and reuse metadata such as `last_used_at` and `warmth_score`, while `meta.yaml` remains authoritative for lane identity and live runtime facts.

Example:

```yaml
version: 1

lanes:
  pay-doc-lg-settlement:
    workdir: "/repo/payments"
    tmux_window_name: "pay|doc|lg|settlement"
    tmux_window_id: "@12"
    last_used_at: "2026-03-31T10:20:00Z"
    warmth_score: 0.91
    scope_keywords: [settlement, payout, reconciliation, ledger, cutoff]

  pay-code-md-api:
    workdir: "/repo/payments"
    tmux_window_name: "pay|code|md|api"
    tmux_window_id: "@13"
    last_used_at: "2026-03-31T10:10:00Z"
    warmth_score: 0.83
    scope_keywords: [api, routing, gateway, request, response]
```

---

# Window provisioning

Provisioning has two phases:

1. runtime provisioning
2. discovered-context warmup

## Phase 1: runtime provisioning

### Step 1: create window

```bash
WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
```

Immediately persist both values:

* `tmux_window_name` = durable human identity
* `tmux_window_id` = live tmux command target

All live tmux operations must target `"$WINDOW_ID"`, not `"$WINDOW_NAME"`.

### Step 2: provision runtime

**MANDATORY:** For `beta`, `delta`, and `gamma`, call the checked-in helper scripts. Do NOT replay raw `/model`, `/models`, `C-t`, `codex --sandbox`, `opencode`, `amp`, or any provider picker keystrokes inline. The scripts are the single source of truth for launch sequences. See "Rule 1" under Core principles.

#### Claude (reserved / future provider)

Claude is reserved for future use. Do not select it during normal orchestration unless `runtime_bands` explicitly maps a lane class to Claude.

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "claude --dangerously-skip-permissions"
```

1. Wait for readiness
2. Send `/model`
3. Send menu choice:

   * `1` for Sonnet 4.6
   * `5` for Haiku 4.5
4. Verify selected model from pane output
5. Write metadata

#### Codex

Use the provider adapter instead of replaying Codex picker keystrokes inline:

```bash
~/skills/tmux_mode/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.4" "high"
```

The helper owns launch of `codex --sandbox danger-full-access`, readiness detection, model selection, reasoning selection, and runtime verification.

Model mapping:

* `gpt-5.4` → beta general runtime for `doc-md`, `doc-lg`, or `doc-xl`
* `gpt-5.4-mini` → beta lightweight runtime for `doc-sm`
* `gpt-5.3-codex` → beta coding runtime for `code-sm`, `code-md`, `code-lg`, or `code-xl`

Reasoning by lane size:

* **sm** → low
* **md** → medium
* **lg** → high
* **xl** → extra_high

#### Delta (OpenCode)

Use the provider adapter instead of replaying OpenCode picker keystrokes inline:

```bash
~/skills/tmux_mode/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "high"
```

The helper owns launch of `opencode`, main UI readiness detection, `/models`, exact picker-label selection, `Select variant` exit handling, `C-t` cycling, and `Build ...` verification.

Model-label mapping:

* `GPT-5.4 mini OpenAI` → gpt-5.4-mini for `doc-sm`
* `GPT-5.4 OpenAI` → gpt-5.4 for `doc-md`, `doc-lg`, or `doc-xl`
* `GPT-5.3 Codex OpenAI` → gpt-5.3-codex for `code-sm`, `code-md`, `code-lg`, or `code-xl`

The observed `C-t` cycle order is:

```text
empty -> none -> low -> medium -> high -> xhigh -> empty
```

Map lane size to the target reasoning label:

* **sm** → `low`
* **md** → `medium`
* **lg** → `high`
* **xl** → `xhigh` (store `extra_high` in metadata)

Treat `empty` as "the `Build ...` line shows no reasoning suffix". The goal is to land on a real reasoning level, never `empty` and never `none`. Use whole-screen matching against the concrete `Build ...` runtime line, not bare reasoning words by themselves. Delta is currently mapped for all `doc-*` lanes and all `code-*` lanes.

#### Amp

Use the provider adapter instead of replaying Amp mode-switch keystrokes inline:

```bash
~/skills/tmux_mode/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
```

The helper owns launch of `amp`, active-mode detection, switch-only-when-needed behavior, and mode verification.

Mode mapping by lane size: `doc-sm` → `rush`, `doc-md`/`doc-lg` → `smart`, `doc-xl` is not allowed on Amp. Amp has a hard global cap of two active tmux windows. If the selected runtime band allows Amp but two Amp windows are already active, choose the beta runtime from the same allowed band instead.

Use provider-specific adapters rather than pretending all providers share the same interface.

## Phase 2: discovered-context warmup

After runtime selection, initialize the lane with the context profile from discovery.

Use **Template A** for a brand new lane, or **Template B** when a lane already has context files but needs a fresh subagent (prior one hit context limits or session died).

### Template A: new lane, new subagent

```text
You are a persistent lane agent for the <lane_label> area.
Lane key: <lane_key>  Window: <tmux_window_name>  Workdir: <workdir>

Context from discovery:
- Domain: <domain_summary>
- Hotspots: <hotspot_list>
- Scope keywords: <scope_keywords_csv>

Bootstrap your lane:
1. Create context files in context/ (summary.md, glossary.md, assumptions.md, hotspots.md, recent_findings.md) using the discovered values above.
2. Scope keywords are in meta.yaml — keep them current as you learn new areas.

File ownership — you write: context/*, outbox/*, requests/*, logs/journal.md, status.yaml (lane-state fields), meta.yaml (`scope_keywords` only).
You never write: inbox/*, logs/pane.latest.txt, runtime.yaml, .tmux/journal.md, .tmux/lanes.yaml, or .tmux/shared_board.yaml. You never delete inbox or outbox files.

Context hygiene: work from the injected task file, lane-local files, and explicitly referenced repo files. Do not open `SKILL.md` or other global orchestrator docs unless the task explicitly tells you to.

Journaling: maintain logs/journal.md. Append a timestamped markdown entry when you receive a task, make a significant finding, post or receive a board question, or complete/block.

Board protocol: before asking a cross-lane question, read all `.tmux/*/meta.yaml` `scope_keywords`. If exactly one other lane owns the topic, write a request file in `requests/` and signal the orchestrator with `tmux_runtime.sh send-commands`. If no lane owns it, expand your own `scope_keywords`, self-resolve, and signal the orchestrator the same way so it can mirror the update into global files. If more than one lane matches, write a request file and escalate — do not pick a winner yourself.

Await your first task in inbox/.
```

### Template B: existing lane, replacement subagent

```text
You are resuming the <lane_label> lane. The prior subagent ended (context limit or session loss).
Lane key: <lane_key>  Window: <tmux_window_name>  Workdir: <workdir>

Reconstruct your state:
1. Read context/ files (summary.md, glossary.md, assumptions.md, hotspots.md, recent_findings.md) — your accumulated knowledge.
2. Read logs/journal.md — your recent work history and decisions.
3. Read status.yaml — check for interrupted task (state=running means a task was in progress).
4. Read meta.yaml — your scope_keywords and lane identity.
5. If status shows a task_id, check inbox/<task_id>.yaml for the task and outbox/ for partial or complete result.

File ownership — you write: context/*, outbox/*, requests/*, logs/journal.md, status.yaml (lane-state fields), meta.yaml (`scope_keywords` only).
You never write: inbox/*, logs/pane.latest.txt, runtime.yaml, .tmux/journal.md, .tmux/lanes.yaml, or .tmux/shared_board.yaml. You never delete inbox or outbox files.

Context hygiene: work from the injected task file, lane-local files, and explicitly referenced repo files. Do not open `SKILL.md` or other global orchestrator docs unless the task explicitly tells you to.

Journaling: maintain logs/journal.md. Append a timestamped markdown entry when you receive a task, make a significant finding, post or receive a board question, or complete/block. Start now with a [resumed] entry.

Board protocol: before asking a cross-lane question, read all `.tmux/*/meta.yaml` `scope_keywords`. If exactly one other lane owns the topic, write a request file in `requests/` and signal the orchestrator with `tmux_runtime.sh send-commands`. If no lane owns it, expand your own `scope_keywords`, self-resolve, and signal the orchestrator the same way so it can mirror the update into global files. If more than one lane matches, write a request file and escalate — do not pick a winner yourself.

If an interrupted task exists, continue it. Otherwise, set status.yaml state to idle and await dispatch.
```

Fill `<placeholders>` from the context profile and lane metadata before injecting via `tmux_runtime.sh send-commands`.

---

# Lane metadata

Each lane must have:

## `meta.yaml`

Example:

```yaml
lane_key: pay-doc-lg-settlement
tmux_window_name: pay|doc|lg|settlement
tmux_window_id: "@12"
provider: beta
model: gpt-5.4
phase: doc
size: lg
lane: settlement
workdir: /repo/payments
workdir_name: payments
context_profile: normal
verified: true
created_at: "2026-03-31T10:00:00Z"
scope_keywords:
  - settlement
  - payout
  - reconciliation
  - ledger
  - cutoff
```

`scope_keywords` is the authoritative list of topics this lane owns. It is used by other agents to decide whether this lane can answer a cross-lane question. It must be kept up to date — expand it whenever the agent digs into a new area.

`tmux_window_name` is the durable human identity. `tmux_window_id` is the live tmux command target. The orchestrator must refresh `tmux_window_id` whenever a window is created, repaired, or recreated.

`meta.yaml` is authoritative for lane identity and live runtime facts. `.tmux/lanes.yaml` is the orchestrator's summary index. Keep them synchronized, but if they disagree, treat `meta.yaml` as authoritative for runtime identity and treat `.tmux/lanes.yaml` as authoritative for orchestrator index fields such as `last_used_at` and `warmth_score`.

OpenAI-backed providers should also include:

```yaml
reasoning: high
```

For `delta`, the UI label `xhigh` maps to metadata value `extra_high`.

For `delta`, `empty` means the `Build ...` line shows no reasoning suffix at all. Never persist `empty` or `none` as the lane reasoning.

gamma should also include:

```yaml
mode: smart
```

Set `mode` to `smart` or `rush` as part of runtime metadata.

## `status.yaml`

Example:

```yaml
state: idle
task_id: null
needs_input: false
blocked_reason: null
last_heartbeat: "2026-03-31T10:20:00Z"
runtime_verified: true
context_initialized: true
```

---

# Lane states

Use this state machine:

```text
provisioning
booting_cli
selecting_runtime
verifying_runtime
warming_context
idle
running
needs_input
done
failed
stale
```

Do not collapse everything into just running/not-running.

State meaning:

* `provisioning` — lane directory exists and orchestrator is creating metadata and files
* `booting_cli` — tmux window exists and the runtime process is launching
* `selecting_runtime` — orchestrator is choosing provider model or mode
* `verifying_runtime` — orchestrator is checking the pane to confirm the selected runtime
* `warming_context` — Template A or B is being injected and lane context is being initialized
* `idle` — ready for work, no active `task_id`
* `running` — actively working on the current `task_id`
* `needs_input` — blocked on a question or decision, still owns the same `task_id`
* `done` — lane finished the task and wrote the result file; waiting for orchestrator collection
* `failed` — lane cannot continue without repair, reset, or replacement
* `stale` — lane exists but should not be reused until refreshed or reset

Required task-state transitions:

* orchestrator dispatches a task: `idle -> running`
* lane blocks on a question or decision: `running -> needs_input`
* lane resumes after input is resolved: `needs_input -> running`
* lane finishes and writes the result file: `running -> done`
* orchestrator collects the result: `done -> idle`, clears `task_id`, clears `needs_input`, clears `blocked_reason`, updates `last_used_at`, and recomputes `warmth_score`

---

# Input contract

Input goes in by:

1. writing a task file into `inbox/`
2. injecting keystrokes telling the agent to read it and respond by file

The task file must include the orchestrator window address so the worker can signal completion back. The orchestrator window name is always `orchestrator` (the main Claude Code window running tmux mode), and the worker must use `tmux_runtime.sh send-commands` for that callback instead of raw `tmux send-keys`.

`task_id` is orchestrator-minted and immutable. Lanes never mint global task ids.

Example task file:

```yaml
task_id: task-004
goal: Investigate payout mismatch between gateway reports and internal ledger totals.
constraints:
  - Preserve auditability
  - Call out assumptions explicitly
output_path: .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml
context_delta_path: .tmux/pay-doc-lg-settlement/context/last_delta.yaml
orchestrator_window: orchestrator
```

Example injected keystrokes:

```text
Read .tmux/pay-doc-lg-settlement/inbox/task-004.yaml.
Do the task.
Write the result to .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml.
Update status.yaml when done.
If blocked, write needs_input state and your blocking question.
If you discover reusable knowledge, write a context delta to .tmux/pay-doc-lg-settlement/context/last_delta.yaml.
When done, signal the orchestrator by running:
  ~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "orchestrator" "Task task-004 is complete. Result at .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml"
```

**All CLIs:** always use `tmux_runtime.sh send-commands` to inject prompts. It handles the text, sleep, and Enter automatically:

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "your prompt here"
```

If the CLI in that window is already launched, do not relaunch the binary for the next prompt. Just call `tmux_runtime.sh send-commands` with the next prompt.

Before injecting a prompt, capture the pane (`~/skills/tmux_mode/scripts/tmux_runtime.sh capture-pane "$WINDOW_ID"`) and make sure there is no update notice, warning, modal, or other obstruction sitting on screen. If there is, dismiss it first and only then send the prompt. Use `tmux_window_id` for all live tmux commands.

Keep keystrokes thin. Put real detail in files.

### Inbox naming and cleanup

Naming: `inbox/<task_id>.yaml` (e.g., `inbox/task-004.yaml`).

Cleanup: The orchestrator may delete inbox files after collecting the corresponding result from outbox. Lanes must not delete their own inbox files — the orchestrator owns inbox lifecycle.

---

# Output contract

Every lane must write:

* `status.yaml`
* one result file in `outbox/`
* `logs/journal.md` — append entries as the task progresses (received, findings, board events, complete/blocked)

Optional:

* `context/last_delta.yaml`

### Outbox naming and cleanup

Naming: `outbox/<task_id>.result.yaml` (e.g., `outbox/task-004.result.yaml`).

Cleanup: The orchestrator may delete or archive outbox files after processing. Lanes must not delete their own outbox files. During discovery, the orchestrator may scan `outbox/` of existing lanes to assess recent work (see Discovery sources).

## Result file

Example:

```yaml
task_id: task-004
agent: pay-doc-lg-settlement
summary: Found mismatch caused by UTC settlement cutoff drift between gateway batch date and internal posting date.
artifacts:
  - docs/reconciliation-findings.md
recommended_next_step: Validate the cutoff logic against three historical settlement days.
insufficient_runtime: false
```

## Needs input

Example `status.yaml`:

```yaml
state: needs_input
task_id: task-004
needs_input: true
blocked_reason: Need confirmation whether settlement date should be compared in gateway local time or UTC.
last_heartbeat: "2026-03-31T10:30:00Z"
```

## Context delta

Example `context/last_delta.yaml`:

```yaml
task_id: task-004
new_terms:
  - settlement cutoff drift
new_patterns:
  - gateway batch date can differ from posting date across timezone boundary
new_assumptions:
  - settlement comparisons should default to UTC unless upstream rules override
hotspots:
  - internal/settlement
  - internal/ledger
confidence: 0.84
```

Use file-based output as the canonical handoff. Pane scraping is for monitoring and repair only.

---

# YAML tooling

`yq` is installed. Use it for all YAML reads, writes, and updates — do not manually concatenate or sed YAML files.

## Common patterns

### Read a field

```bash
yq '.state' '.tmux/pay-doc-lg-settlement/status.yaml'
yq '.scope_keywords' '.tmux/pay-doc-lg-settlement/meta.yaml'
```

### Update a field in-place

```bash
yq -i '.state = "running"' '.tmux/pay-doc-lg-settlement/status.yaml'
yq -i '.last_used_at = "2026-03-31T11:00:00Z"' '.tmux/pay-doc-lg-settlement/meta.yaml'
```

### Append to a list

```bash
yq -i '.scope_keywords += ["cutoff"]' '.tmux/pay-doc-lg-settlement/meta.yaml'
```

### Append a new board entry

```bash
yq -i '. += [{"question_id": "q-002", "status": "pending", ...}]' .tmux/shared_board.yaml
```

### Update a board entry by question_id

```bash
yq -i '(.[] | select(.question_id == "q-001")).status = "answered"' .tmux/shared_board.yaml
yq -i '(.[] | select(.question_id == "q-001")).answer = "Use UTC."' .tmux/shared_board.yaml
```

### Read all lanes' scope_keywords (for cross-lane matching)

```bash
for f in .tmux/*/meta.yaml; do
  echo "=== $f ==="
  yq '.tmux_window_name + ": " + (.scope_keywords | join(", "))' "$f"
done
```

### Create a new status.yaml

```bash
yq -n '.state = "provisioning" | .task_id = null | .needs_input = false' > .tmux/my-lane/status.yaml
```

Use `yq` everywhere YAML files are read or written — in scripts, in injected keystrokes, and in orchestrator operations.

---

# Pane scraping policy

Use `tmux capture-pane` for:

* readiness detection
* model/mode/reasoning verification
* progress monitoring
* error detection
* detecting blocked/input-needed states
* troubleshooting stuck windows

Do not use pane output as the primary structured result path.

For Delta specifically, capture the whole visible pane and parse the `Build ...` line with a concrete regex. Do not verify reasoning by grepping for bare words like `high` or `medium` without the surrounding runtime context.

---

# Log files

Each lane has a `logs/` directory with these files:

## `logs/journal.md`

The lane's running log. See [Lane journal](#lane-journal) under Journaling protocol for format and write triggers.

## `logs/pane.latest.txt`

Written by `poll_window.sh` or the orchestrator's monitoring loop. Contains the most recent `tmux capture-pane -p` output for the lane window. Overwritten on each poll cycle (not appended).

```text
<raw terminal output from tmux capture-pane -p>
```

Used by the orchestrator for readiness detection, error detection, and stuck-state diagnosis. Not read by the lane agent itself.

---

# Routing rules

Route from the discovered context profile, not from rigid categories.

## Runtime bands

Use these runtime bands throughout routing:

* `Amp smart / gpt-5.4` = high-capability general runtime band
* `Amp rush / gpt-5.4-mini` = lightweight general runtime band
* `gpt-5.3-codex` = coding runtime band

## Phase split

Every task must be classified into exactly one phase before dispatch:

| Phase | Purpose | Allowed runtimes |
|---|---|---|
| Decision phase | planning, decomposition, documentation, analysis, non-code reasoning | `Amp smart / gpt-5.4` or `Amp rush / gpt-5.4-mini`, depending on work type and complexity |
| Coding phase | implementation, debugging investigation, refactor, tests, code review summaries, PR descriptions, migration execution | `gpt-5.3-codex` |

Hard rules:

* all planning, decomposition, and scope decisions happen before dispatching a coding lane
* coding lanes do not re-plan the task
* if a coding lane hits ambiguity or missing decisions, it must use the asking mechanism
* the orchestrator decides whether to answer directly, revise scope, or spawn another lane

## Phase + size mapping

The lane name and runtime mapping must agree:

| Lane class | Meaning | Allowed runtimes |
|---|---|---|
| `doc-sm` | lightweight decision work | `Amp rush / gpt-5.4-mini` |
| `doc-md` | standard decision work | `Amp smart / gpt-5.4 medium` |
| `doc-lg` | harder decision work | `Amp smart / gpt-5.4 high` |
| `doc-xl` | hardest decision work | `gpt-5.4 extra_high` |
| `code-sm` | lightweight coding work | `gpt-5.3-codex low` |
| `code-md` | standard coding work | `gpt-5.3-codex medium` |
| `code-lg` | harder coding work | `gpt-5.3-codex high` |
| `code-xl` | hardest coding work | `gpt-5.3-codex extra_high` |

## Decision-phase work tables

### Text work

Criteria: the primary output is prose for humans to read, such as summaries, documentation, notes, or rewrites. Ordinary documentation stays here unless it becomes planning or strategy.

| Work shape | Criteria | Examples | Allowed runtimes |
|---|---|---|---|
| Ordinary explanatory text work | prose requires judgment about what matters, how to explain it, or how to frame it for the audience | explanatory documentation, rationale writeup, design note | `Amp smart / gpt-5.4` |
| High-stakes text work | persuasive or strategic writing where judgment errors are expensive | strategic memo, recommendation, executive brief | `Amp smart / gpt-5.4` |

### Analytical work

Criteria: the task is about deciding what should happen, comparing options, or choosing a direction before execution starts.

| Work shape | Criteria | Examples | Allowed runtimes |
|---|---|---|---|
| Standard analytical work | bounded planning or comparison with moderate ambiguity | decomposition, tradeoff analysis, plan review | `Amp smart / gpt-5.4` |
| Hard analytical work | planning mistakes are expensive and the task needs deeper reasoning | architecture decision, ADR, orchestrator topology, costly decomposition | `Amp smart / gpt-5.4` |

### Mechanical work

Criteria: the task is tightly scoped, deterministic, and transformation-heavy. The prompt must be specific, include output shape, scope limits, and guardrails to reduce hallucination.

| Work shape | Criteria | Examples | Allowed runtimes |
|---|---|---|---|
| Mechanical transform | deterministic, low-judgment transformation with explicit instructions | extraction, formatting, classification, reformatting | `Amp rush / gpt-5.4-mini` |
| Large but bounded mechanical/text work | large corpus, but still specific and guardrailed | bulk summarization with strict schema, status notes, structured rewrite batch | `Amp rush / gpt-5.4-mini` |

## Coding-phase work table

Criteria: the task changes, explains, investigates, or delivers code-shaped work. If the artifact is about code work, it belongs here even if the final output is text.

| Work shape | Criteria | Examples | Allowed runtimes |
|---|---|---|---|
| Coding work | code implementation or investigation inside an already-decided scope | implementation, debugging investigation, refactor, tests, code review summaries, PR descriptions, migration execution | `gpt-5.3-codex` |

## Reasoning levels

Reasoning level is chosen after runtime band selection:

| Reasoning | Use when |
|---|---|
| `low` | deterministic, bounded, low-cost mistakes |
| `medium` | bounded synthesis with some ambiguity |
| `high` | ambiguous, coupled, or multi-step work that is harder to verify quickly |
| `extra_high` | only when decomposition, architecture, ADR, or planning mistakes are especially expensive |

Reasoning guidance by runtime band:

* `Amp smart` is roughly comparable to `gpt-5.4` at `medium` to `high`
* the hardest decision work should use `gpt-5.4` at `extra_high`
* only use `Amp rush / gpt-5.4-mini` when the prompt is highly specific, bounded, and includes strong guardrails

## Runtime tie-break rules

When a row allows multiple runtimes:

1. Reuse a strong warm lane first
2. If no warm lane matches, prefer Amp while active Amp windows are below the global cap of `2`
3. If Amp is allowed but the cap is full, choose the same-band OpenAI fallback instead
4. For decision-phase `gpt-5.4` work, prefer the warmer matching lane between `beta` and `delta`; if there is no meaningful warmth difference, default to `beta`
5. For coding-phase `gpt-5.3-codex` work, prefer the warmer matching lane between `beta` and `delta`; if there is no meaningful warmth difference, default to `beta`
6. If the task moves outside its current scope, use the asking mechanism and let the orchestrator decide whether to answer, escalate, or create a new lane

---

# Reuse and drift policy

Reuse a lane when:

* it matches the discovered context strongly (above threshold)
* it lives in the same repo/workdir
* the runtime is suitable
* the lane is healthy
* drift is acceptable

Avoid reuse when:

* the lane's context has drifted too far
* the domain changed substantially
* the runtime is too weak
* the window is stuck or stale

Warm context is valuable, but stale or contaminated context should be reset.

---

# Escalation policy

Lanes should not autonomously spawn stronger lanes.

If a lane thinks it needs more capability or a harder decision, it should first use the asking mechanism so the orchestrator can decide whether to answer directly, upgrade the runtime, or create a new lane.

If the lane needs to signal that its current runtime band is insufficient, it should write:

```yaml
insufficient_runtime: true
recommended_phase: doc
recommended_size: xl
recommended_allowed_runtimes:
  - beta:gpt-5.4:extra_high
  - delta:gpt-5.4:extra_high
reason: Task requires a harder planning decision before execution can continue.
```

Then the orchestrator decides whether to:

* upgrade runtime
* create a new lane
* continue with the current lane

The orchestrator owns escalation and topology.

---

# Orchestrator session limits

The orchestrator runs inside a Claude Code session window. That session has a context limit. As work accumulates — inbound signals, board events, result reads, pane captures — the orchestrator window will eventually approach that limit and need to be restarted with a fresh context.

**This is expected. The journal is the recovery mechanism.**

When a fresh orchestrator instance is started (user restarts tmux mode, or opens a new Claude Code session in the orchestrator window), it must be able to reconstruct full situational awareness by reading:

1. `.tmux/journal.md` — what has happened and what decisions were made
2. `.tmux/lanes.yaml` — current lane topology
3. `.tmux/*/status.yaml` — live state of each lane
4. `.tmux/shared_board.yaml` — open cross-lane questions

**Write to the journal proactively**, not only on completion. Each significant orchestrator action should be logged immediately — before the context that motivated it is gone.

If the orchestrator detects it is running low on context (responses becoming slower, context window warnings, or user notices degraded behavior), it should:

1. Flush a summary entry to `.tmux/journal.md` covering current state
2. Write a `resume_hint` field into `.tmux/runtime.yaml` with a one-line summary of what to do next
3. Inform the user: "Orchestrator context is filling up. Journal and state are flushed. You can restart tmux mode to resume."

On restart, the new orchestrator instance reads the journal and runtime.yaml resume hint before doing anything else.

---

# Journaling protocol

## Orchestrator journal

File: `.tmux/journal.md`

The orchestrator appends to this file throughout its session. Entries are freeform markdown, prefixed with a timestamp and a category tag.

### Format

```markdown
## [2026-03-31T10:25:00Z] [dispatch] task-004 → pay|doc|lg|settlement
Dispatched settlement mismatch investigation to pay|doc|lg|settlement.
Task file: .tmux/pay-doc-lg-settlement/inbox/task-004.yaml

## [2026-03-31T10:30:00Z] [board] q-001 routed pay|code|md|api → pay|doc|lg|settlement
Question: "Does the settlement cutoff apply in gateway local time or UTC?"
Marked routed in shared_board.yaml.

## [2026-03-31T10:45:00Z] [complete] task-004 done
Result: .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml
Summary: Mismatch caused by UTC cutoff drift. Next: validate against 3 historical days.

## [2026-03-31T11:00:00Z] [escalation] pay|doc|lg|settlement → insufficient_runtime
Lane flagged insufficient_runtime. Decided: create new `pay-doc-xl-settlement` lane for a harder planning pass.
```

### Category tags

```text
[dispatch]    — task sent to a lane
[complete]    — task result received
[board]       — cross-lane board event (post, route, answer, ack, self-resolved)
[escalation]  — runtime upgrade or new lane created from escalation signal
[repair]      — window recreated or lane reset
[decision]    — non-obvious routing or topology choice
[context]     — context delta merged into a lane
[resume]      — orchestrator restarted and reading state
[flush]       — context limit approaching, state summary flushed
```

Write an entry for every category tag event. Do not batch — write immediately after the event.

## Lane journal

File: `.tmux/<lane_key>/logs/journal.md`

Each lane maintains its own running log. The lane agent is responsible for writing to it. The orchestrator does not write to lane journals.

### Format

```markdown
## [2026-03-31T10:25:00Z] task-004 received
Goal: Investigate payout mismatch between gateway reports and internal ledger totals.
Starting with internal/settlement and internal/ledger.

## [2026-03-31T10:28:00Z] found candidate: UTC cutoff drift
gateway batch date differs from posting date across timezone boundary.
Posting to board for UTC confirmation — q-001.

## [2026-03-31T10:35:00Z] q-001 answered: use UTC
Continuing with UTC assumption. Validating against 3 sample days.

## [2026-03-31T10:44:00Z] task-004 complete
Written result to outbox/task-004.result.yaml.
Context delta written to context/last_delta.yaml.
```

Lanes should append an entry:
- when a task is received
- when a significant finding is made
- when a board question is posted or answered
- when the task is complete or blocked

---

# Workdir and naming behavior

When provisioning a tmux window:

1. compute `dir_abbrev` = short abbreviation of `basename(workdir)` (e.g. `payments` → `pay`, `frontend` → `fe`, `infrastructure` → `inf`)
2. compute `lane_key = <dir_abbrev>-<doc_or_code>-<size>-<lane>` (internal identity, stored in metadata)
3. compute `window_name = <dir_abbrev>|<doc_or_code>|<size>|<lane>` (e.g. `pay|doc|lg|settlement`)
4. create the window with `WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "$window_name")"` and persist both `tmux_window_name` and `tmux_window_id`

If the window already exists but has the wrong name, rename it to match the rule.

Human tmux navigation (Oh My Tmux tabs) should always reflect:

* repo/workdir (abbreviated)
* phase (`doc` or `code`)
* reasoning tier (`sm`, `md`, `lg`, `xl`)
* lane label

---

# Suggested helper scripts

Use the reusable helper layer shipped in this repo's `scripts/` directory. When installed for regular use, that path is typically `~/skills/tmux_mode/scripts/`.

```text
scripts/
  tmux_runtime.sh
  spawn_delta.sh
  spawn_beta.sh
  spawn_gamma.sh

repo-local scripts/
  discover_context.sh
  score_lanes.sh
  ensure_window.sh
  dispatch_task.sh
  poll_window.sh
  collect_result.sh
  reconcile_lanes.sh
  merge_context_delta.sh
  cleanup_lane.sh
  post_board_question.sh
  route_board_question.sh
  deliver_board_answer.sh
```

## Recommended shell adapter API

Do not keep re-implementing raw `tmux send-keys` sequences inline. Put the repeated tmux interaction into a small shell adapter layer and call that from orchestration scripts.

Use the installed helper scripts with a stable API such as:

```bash
WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "commands here"
~/skills/tmux_mode/scripts/tmux_runtime.sh capture-pane "$WINDOW_ID"
~/skills/tmux_mode/scripts/tmux_runtime.sh kill-window "$WINDOW_ID"
~/skills/tmux_mode/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.4" "high"
~/skills/tmux_mode/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
~/skills/tmux_mode/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "xhigh"
```

The abstraction goal is:

* the orchestrator chooses the target window, runtime, model, and reasoning
* the adapter handles `tmux send-keys`, sleeps, Enter, pane capture, retries, selector exits, and verification
* the installed helpers default to a 3-second timeout and should fail fast when the required runtime state does not appear; Beta/Codex uses a 5-second default because cold start is slower in practice
* failures return non-zero and print a specific error message that says what check failed

Subcommands available via `~/skills/tmux_mode/scripts/tmux_runtime.sh <subcommand>`:

* `create-window WINDOW_NAME` — create a detached window, rename it, and print the live `window_id`
* `kill-window WINDOW_ID` — kill a window by id
* `rename-window OLD NEW` — rename a window
* `list-windows` — list all tmux windows
* `send-commands WINDOW_ID "text"` — send text, sleep, then send `Enter`
* `send-key WINDOW_ID KEY` — send a single special key such as `Enter` or `C-t`
* `capture-pane WINDOW_ID` — full pane capture for diagnostics
* `capture-screen WINDOW_ID` — capture the full visible pane for runtime verification
* `wait-screen WINDOW_ID REGEX` — poll until the visible pane matches the required runtime state

Recommended provider adapters:

* `spawn_beta WINDOW_ID MODEL REASONING`
* `spawn_gamma WINDOW_ID MODE`
* `spawn_delta WINDOW_ID MODEL_LABEL REASONING_LABEL`

These adapters should be the only place that knows provider-specific quirks. They are also the canonical implementation for Phase 1 runtime provisioning above.

## Responsibilities

### `~/skills/tmux_mode/scripts/tmux_runtime.sh`

* centralize low-level `tmux send-keys`, sleeps, Enter, pane capture, and retry helpers
* expose stable shell helpers such as `send_commands`, `send_key`, `capture_screen`, and `wait_for_screen`
* emit consistent failure messages and non-zero exit codes

### `~/skills/tmux_mode/scripts/spawn_delta.sh`

* launch `opencode` in the designated tmux window
* wait for the main screen state, not arbitrary pane text
* send `/models`, select the exact picker label, and exit `Select variant` with `Enter` when needed
* use whole-screen verification on the `Build ...` line
* cycle `C-t` one step at a time until the requested reasoning label is visible
* fail clearly if the required screen state never appears, the selected model does not stick, or the requested reasoning cannot be reached

### `~/skills/tmux_mode/scripts/spawn_beta.sh`

* launch `codex --sandbox danger-full-access` in the designated tmux window
* select the requested model and reasoning using Codex-specific controls
* verify the selected runtime before returning success
* fail clearly if the model picker or reasoning selection does not complete

### `~/skills/tmux_mode/scripts/spawn_gamma.sh`

* launch `amp` in the designated tmux window
* verify the active mode before switching
* switch only when needed
* fail clearly if the mode cannot be verified or changed

### `discover_context.sh`

* inspect task, repo, docs, existing lane summaries, hotspots, and recent outputs
* emit a context profile

### `score_lanes.sh`

* compare the context profile against existing lanes
* return ranked candidates

### `ensure_window.sh`

* compute `lane_key = <dir_abbrev>-<doc_or_code>-<size>-<lane>` and `window_name = <dir_abbrev>|<doc_or_code>|<size>|<lane>`
* create or repair tmux window using a captured `WINDOW_ID`, not a bare rename
* call `spawn_beta.sh`, `spawn_delta.sh`, or `spawn_gamma.sh` for provider-specific launch, selection, and verification instead of re-implementing raw picker keystrokes inline
* warm the lane with discovered context
* write metadata including refreshed `tmux_window_id`

### `dispatch_task.sh`

* write task file to inbox (including `orchestrator_window` field set to `"orchestrator"`)
* set `status.yaml` to running
* inject keystrokes instructing the worker to read the task file, write outputs, and signal the orchestrator window when done

### `poll_window.sh`

* capture pane text (`tmux capture-pane -p -t "$WINDOW_ID"`)
* update heartbeat
* detect stuck states, errors, or input requests
* write `logs/pane.latest.txt`

### `collect_result.sh`

* wait for or read outbox result files
* parse structured result
* return it to the orchestrator

### `reconcile_lanes.sh`

* walk `.tmux/*/`
* run `tmux list-windows` to get live window state
* compare desired lanes to live tmux windows
* repair drift
* recreate missing windows
* mark stale lanes

### `merge_context_delta.sh`

* inspect `context/last_delta.yaml`
* merge useful knowledge into persistent lane context files

---

# Operational guidance

1. Always use windows, not separate sessions. Operate within the current tmux session.
2. Always do a survey + discovery pass before spawning any window.
3. Treat lanes as warm context containers, not rigid categories.
4. Use file-based output as the canonical handoff.
5. Keep keystroke prompts minimal — put real detail in files.
6. Use provider-specific model/mode/reasoning selection logic.
7. Reuse warm lanes whenever the context match is strong.
8. Reset stale or contaminated lanes when needed.
9. Avoid unnecessarily long tmux window names beyond what remains readable.
10. Prefer separate git worktrees if multiple coding agents may edit concurrently.
11. Resolve runtime from the lane's `phase + size` mapping; gamma is only valid for `doc-sm`, `doc-md`, and `doc-lg`, and delta is currently valid for all `doc-*` lanes and all `code-*` lanes.
12. Use `tmux_window_id` for all live tmux commands. Use `tmux_window_name` for human identity, journaling, and recovery.

---

# Orchestrator onboarding

When "tmux mode" activates, the orchestrator must check whether `.tmux/` exists before doing anything else. This determines whether this is a fresh start or a resume.

**Orchestrator journaling directive:** You maintain `.tmux/journal.md`. Append a timestamped markdown entry with a category tag on every significant event: `[dispatch]` task sent, `[complete]` result received, `[board]` cross-lane question routed/answered/acked, `[escalation]` runtime upgrade, `[decision]` non-obvious routing or topology choice, `[repair]` window recreated or lane reset, `[resume]` orchestrator restarted, `[flush]` context limit approaching. Write immediately after each event — not in batches. This journal is the primary recovery mechanism if your session ends.

## Fresh start (`.tmux/` does not exist)

1. Create `.tmux/` directory
2. Create `.tmux/journal.md` (empty)
3. Create `.tmux/shared_board.yaml` as `[]`
4. Create `.tmux/runtime.yaml` from the template
5. Proceed to survey + task decomposition

## Resume (`.tmux/` exists)

Read the following files to reconstruct full situational awareness:

1. `.tmux/journal.md` — what the previous orchestrator did, in order
2. `.tmux/runtime.yaml` — check `resume_hint` for what to do next
3. `.tmux/lanes.yaml` — current lane topology
4. `.tmux/*/status.yaml` — state of each lane (idle, running, done, needs_input, failed)
5. `.tmux/*/meta.yaml` — scope keywords and identity of each lane
6. `.tmux/shared_board.yaml` — any open cross-lane questions
7. `tmux list-windows` — which windows are still alive

After reading, build a situational summary:
- Which lanes exist and their states
- Any interrupted tasks (status = running)
- Any open board questions (status != ack)
- What the resume_hint says (if set)
- Which tmux windows are alive vs. which lanes have lost their window

Append a `[resume]` entry to `.tmux/journal.md` with this summary.

Then **present the summary to the user** and ask:
> "Resuming tmux mode. Here's the current state: [summary]. Do you have any questions or want to adjust anything before I continue?"

Wait for the user's response before proceeding. The user may want to:
- Ask about a specific lane's work
- Cancel or redirect a task
- Kill stale lanes
- Provide new context or priorities

After the user confirms, proceed to the orchestrator loop (either resume interrupted work or start new survey).

## Resume decision matrix

Task ids are immutable and orchestrator-minted. On resume, never create a new task id for unfinished work.

For each lane with `task_id != null`:

* `state = running` and live window exists and no result file exists → do not redispatch; keep monitoring or ping the lane
* `state = running` and live window is missing and no result file exists → start a replacement subagent with Template B and continue the existing task file
* `state = running` and result file already exists → collect the result and mark the task done
* `state = needs_input` → surface the blocking question; do not auto-restart the task

---

# Expected orchestrator loop

```text
1.  user says "tmux mode"
2.  rename current window to "orchestrator" (tmux rename-window "orchestrator")
3.  run orchestrator onboarding (see "Orchestrator onboarding" section):
    - if .tmux/ does not exist → fresh start: create directory, journal, board, runtime
    - if .tmux/ exists → resume: read all state files, summarize, ask user before proceeding
4.  survey the work (tree, gh pr list, ticket list, file list — whatever fits)
5.  identify natural boundaries and produce task split plan
    → append [decision] entry to journal with the task split rationale
6.  for each sub-task: run discovery against task + repo + existing lane context
7.  build a context profile per sub-task
8.  score existing lanes for reuse
9.  reuse the best matching warm lane or create a new one
10. resolve `phase`, `size`, and provider/runtime per lane
11. compute `lane_key = <dir_abbrev>-<doc_or_code>-<size>-<lane>` and `window_name = <dir_abbrev>|<doc_or_code>|<size>|<lane>`
12. reconcile lane directory and live tmux windows (tmux list-windows)
13. provision or reuse the window using a captured `WINDOW_ID`, then persist `tmux_window_id` in metadata
14. warm the lane using Template A (new lane) or Template B (replacement subagent) from "Phase 2: discovered-context warmup"
15. write task file to inbox (with `orchestrator_window: "orchestrator"`)
16. inject keystrokes telling the worker to read the task file and signal back when done
    → append [dispatch] entry to journal
17. **wait for inbound signals** — do NOT sleep-poll or loop-capture-pane to check progress; the lane will signal you when it is done, blocked, or has a board request

On any inbound signal from a worker (task done, board request, needs input):
18. read the signal to determine type:
    - "Task <id> complete"     → collect result from outbox, optionally merge context delta, decide next action
                                 → append [complete] entry to journal
    - "Board request posted"   → read the lane-local request file, update shared_board.yaml and lanes.yaml as needed, route or escalate
                                 → append [board] entry to journal
    - "Board answer posted"    → read the answer request file, update shared_board.yaml, deliver answer to questioner window
                                 → append [board] entry to journal
    - "Board ack posted"       → read the ack request file, update shared_board.yaml, confirm resolved
                                 → append [board] entry to journal
19. after handling the signal, return to monitoring state

If context limit is approaching:
20. append [flush] entry to journal summarizing current state (active lanes, open tasks, open board questions)
21. write resume_hint to .tmux/runtime.yaml
22. inform the user
```

---

# Success criteria

This skill is working correctly when:

* saying `tmux mode` activates orchestration behavior
* survey + discovery runs before any window is spawned
* windows are provisioned and named consistently, visible as Oh My Tmux tabs
* `.tmux/<lane_key>/` fully reflects window reality
* live tmux commands target `tmux_window_id`, not a fragile implicit current window
* model/mode/reasoning selection is verified
* lane warmup uses Template A (new lane) or Template B (replacement subagent) — includes scope_keywords, file ownership rules, journaling, and board protocol inline
* tasks are injected by keystrokes
* results are returned as files
* warm lanes are reused when context match is strong
* tmux remains human-navigable by repo/phase/size/lane
* escalation and repair are handled by the orchestrator
* agents check `scope_keywords` before asking — no blind broadcasts
* lanes write lane-local request files; orchestrator updates `shared_board.yaml` and `lanes.yaml`
* cross-lane questions flow through `shared_board.yaml` via orchestrator keystrokes
* self-resolving agents update their scope before and after digging
* the chain reaction (post → route → answer → deliver → ack) completes without timer-based polling — the orchestrator never sleep-polls for lane completion
* provider launch always uses `spawn_beta.sh`, `spawn_delta.sh`, or `spawn_gamma.sh` — never inline `tmux send-keys` with raw provider keystrokes
* orchestrator appends to `.tmux/journal.md` on every significant event — dispatch, complete, board, escalation, decision
* each lane maintains its own `.tmux/<lane_key>/logs/journal.md` independently
* a fresh orchestrator instance can reconstruct full state from `.tmux/journal.md` + `lanes.yaml` + `status.yaml` files
* if context limit approaches, orchestrator flushes a summary to journal and writes `resume_hint` to `runtime.yaml` before informing the user

---

# Minimal default decision table

Use these defaults when the task has not yet been decomposed further:

| Situation | Allowed runtimes | Notes |
|---|---|---|
| decision work with stronger reasoning needs | `Amp smart / gpt-5.4` | use `gpt-5.4 extra_high` for the hardest decisions; OpenAI fallback can be `beta` or `delta` |
| lightweight decision work with strong guardrails | `Amp rush / gpt-5.4-mini` | keep prompts specific, bounded, and structured; OpenAI fallback can be `beta` or `delta` |
| coding work | `gpt-5.3-codex` | planning must already be decided; provider can be `beta` or `delta` |

---

# Minimal tmux command cheatsheet

All tmux operations go through `~/skills/tmux_mode/scripts/tmux_runtime.sh`. Provider launch uses `spawn_beta.sh`, `spawn_delta.sh`, and `spawn_gamma.sh`. **Never use raw `tmux` commands directly.**

## Create window

```bash
WINDOW_ID="$(~/skills/tmux_mode/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
```

## Send command

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "command"
```

## Capture output

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh capture-pane "$WINDOW_ID"
```

## List windows

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh list-windows
```

## Kill window

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh kill-window "$WINDOW_ID"
```

## Rename window

```bash
~/skills/tmux_mode/scripts/tmux_runtime.sh rename-window "old" "new"
```

---

# Final directive

When the user says **"tmux mode"**, switch into discovery-first orchestrator behavior:

* immediately rename the current tmux window to `orchestrator`:

  ```bash
  ~/skills/tmux_mode/scripts/tmux_runtime.sh rename-window "$(tmux display-message -p '#{window_id}')" "orchestrator"
  ```

* check if `.tmux/` exists — if yes, run the resume protocol: read journal + state files, summarize to the user, ask if they have questions before continuing
* if `.tmux/` does not exist, create the directory and bootstrap files
* survey the work first — understand shape before splitting
* run discovery to build a context profile per sub-task
* reuse or create the best warm lane
* run each lane as a tmux window in the current session
* keep outputs file-based
* keep inputs keystroke-based
* preserve warm context through lane-managed context files
* keep everything visible in Oh My Tmux tabs
