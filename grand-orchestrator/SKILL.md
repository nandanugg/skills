---
name: grand-orchestrator
description: Activates when the user says "grand orchestrator". Runs a discovery-first, window-based tmux orchestrator inside the current tmux session. Each subagent is a tmux window (tab) visible in Oh My Tmux. Uses context lanes instead of rigid categories, file-based outputs, and keystroke-based inputs across Claude (alpha), Codex (beta), Amp (gamma), and OpenCode (delta).
---

# Grand Orchestrator

Trigger: user says **"grand orchestrator"**

This skill turns tmux into a persistent multi-agent runtime optimized for Oh My Tmux tabs and warm context reuse.

## Reference Index — Load When Needed

| When you need to... | Load this reference |
|---------------------|---------------------|
| **Spawn a provider** (alpha/beta/gamma/delta), choose model/reasoning, or map phase+size to runtime | [provider-matrix.md](references/provider-matrix.md) — spawn commands, model args, full phase/size table, tie-break rules |
| **Warm up a lane** with Template A (new) or Template B (replacement), or create context file skeletons | [templates.md](references/templates.md) — full injectable prompts, context/*.md skeletons, **output structure for recall** |
| **Write or read YAML files** (meta.yaml, status.yaml, task, result, board, request), check file ownership, or understand lane states | [file-schemas.md](references/file-schemas.md) — all YAML schemas, ownership table, state machine, journal tags |
| **Bootstrap .tmux/runtime.yaml** on fresh start | [runtime-config.yaml](references/runtime-config.yaml) — full example to copy |
| **Structure outputs for mid-conversation recall** (LITM prevention) | [templates.md](references/templates.md) — "Output Structure for Recall" section |

---

# Three Hard Rules

### Rule 0 — Rename window immediately

**FIRST action** when activated:

```bash
~/skills/grand-orchestrator/scripts/tmux_runtime.sh rename-window "$(tmux display-message -p '#{window_id}')" "orchestrator"
```

### Rule 1 — Use helpers, never raw tmux

**NEVER** use raw `tmux send-keys`, `tmux new-window`, `tmux kill-window`, etc. Always use:

```bash
# Window management
WINDOW_ID="$(~/skills/grand-orchestrator/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
~/skills/grand-orchestrator/scripts/tmux_runtime.sh send-commands "$WINDOW_ID" "prompt text"
~/skills/grand-orchestrator/scripts/tmux_runtime.sh capture-pane "$WINDOW_ID"
~/skills/grand-orchestrator/scripts/tmux_runtime.sh kill-window "$WINDOW_ID"
~/skills/grand-orchestrator/scripts/tmux_runtime.sh list-windows

# Provider launch (NEVER replay raw /model, C-t, etc.)
~/skills/grand-orchestrator/scripts/spawn_alpha.sh "$WINDOW_ID" "sonnet"
~/skills/grand-orchestrator/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.4" "high"
~/skills/grand-orchestrator/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
~/skills/grand-orchestrator/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "high"
```

### Rule 2 — Wait for callbacks, never sleep-poll

**NEVER** use `sleep` loops or capture-pane polling. Architecture is callback-driven:
- Lane finishes → signals via `tmux_runtime.sh send-commands "orchestrator" "..."`
- Orchestrator processes signals as they arrive

---

# Context Anchoring (LITM Prevention)

Long conversations suffer from "Lost In The Middle" — content in the middle gets less attention. Structure all outputs for recall:

**Every output must front-load recall anchors:**
- First 3 lines: task_id, lane_key, summary with implementation keywords
- Implementation anchors: handler names, job names, table names, flag names, API endpoints
- Headers with keywords: Not "Overview" but "Settlement Retry Flow Overview"
- Cross-references explicit: `See task-003` or `Related: pay-code-md-api`

**Journal entries format:** `[timestamp] [tag] task_id | lane_key | one-line with keywords`

**When dispatching tasks:** Remind lanes to structure outputs for recall. The templates include this instruction, but reinforce it for complex tasks.

**For full output structure guidance:** Load [templates.md](references/templates.md) — see "Output Structure for Recall" section.

---

# Core Design

## Flow

```text
task → survey → discovery → context profile → reuse/create lane → dispatch → wait for callback
```

## Lane Identity

Internal key: `<dir_abbrev>-<doc_or_code>-<size>-<lane>` (e.g., `pay-doc-lg-settlement`)
Window name: `<dir_abbrev>|<doc_or_code>|<size>|<lane>` (e.g., `pay|doc|lg|settlement`)

- `dir_abbrev`: short workdir name (payments → pay)
- `doc_or_code`: phase marker
- `size`: reasoning tier (sm/md/lg/xl)
- `lane`: discovered label (settlement, api, refactor)

## Runtime Selection (Quick Reference)

| Lane | Default Runtimes |
|------|------------------|
| doc-sm | haiku, rush, mini |
| doc-md/lg | sonnet, smart, gpt-5.4 |
| doc-xl | opus, extra_high |
| code-* | sonnet/opus, gpt-5.3-codex |

**Before spawning:** Load [provider-matrix.md](references/provider-matrix.md) for exact spawn commands, model arguments, reasoning levels, and tie-break rules when multiple runtimes are allowed.

---

# Orchestrator Onboarding

## Fresh Start (`.tmux/` does not exist)

1. Create `.tmux/` directory
2. Create `.tmux/journal.md`, `.tmux/shared_board.yaml` (as `[]`), `.tmux/lanes.yaml`
3. **Copy [runtime-config.yaml](references/runtime-config.yaml) to `.tmux/runtime.yaml`**
4. Proceed to survey + task decomposition

## Resume (`.tmux/` exists)

Read to reconstruct state:
1. `.tmux/journal.md` — what happened
2. `.tmux/runtime.yaml` — check `resume_hint`
3. `.tmux/lanes.yaml` — lane topology
4. `.tmux/*/status.yaml` — lane states
5. `.tmux/shared_board.yaml` — open questions
6. `tmux_runtime.sh list-windows` — live windows

**Present summary to user and ask before continuing.**

---

# Discovery-First Workflow

## Survey Step

Before routing, understand work shape:
- Codebase → `tree -L 3`
- PR batch → `gh pr list`
- Tickets → enumerate and check dependencies

## Discovery Step

Inspect: task text, workdir, repo structure, `README`, `docs/`, existing `.tmux/*/context/summary.md` and `hotspots.md`.

Output a context profile:

```yaml
domain: payments settlement flow
task_shape: investigation
hotspots: [internal/settlement, internal/ledger]
needs_code_changes: false
phase: doc
size: lg
suggested_lane: settlement
```

## Lane Reuse

Score existing lanes on: context overlap, same workdir, task shape, recency, runtime suitability.

Reuse if similarity > 0.72 and runtime suitable. Otherwise create new lane.

---

# Window Provisioning

## Phase 1: Runtime

```bash
WINDOW_ID="$(~/skills/grand-orchestrator/scripts/tmux_runtime.sh create-window "pay|doc|lg|settlement")"
~/skills/grand-orchestrator/scripts/spawn_alpha.sh "$WINDOW_ID" "sonnet"  # or spawn_beta/gamma/delta
```

Persist both `tmux_window_name` (durable identity) and `tmux_window_id` (live handle) in `meta.yaml`.

**For meta.yaml and status.yaml structure:** Load [file-schemas.md](references/file-schemas.md) — contains full field list (provider, model, reasoning, phase, size, scope_keywords, state, task_id, etc.).

## Phase 2: Context Warmup

Inject warmup prompt via `send-commands`:
- **New lane:** Use Template A (includes bootstrap instructions, file ownership, board protocol)
- **Replacement subagent:** Use Template B (includes state reconstruction, resume instructions)

**Before warming:** Load [templates.md](references/templates.md) for full injectable prompts and context/*.md skeleton formats (summary, glossary, assumptions, hotspots, recent_findings).

---

# Input/Output Contracts

## Input (Task Dispatch)

1. Write task file to `inbox/<task_id>.yaml` with `callback_cmd`
2. Inject keystrokes telling agent to read task, write result, run `callback_cmd`

```yaml
task_id: task-004
goal: Investigate payout mismatch
output_path: .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml
callback_cmd: ~/skills/grand-orchestrator/scripts/tmux_runtime.sh send-commands "orchestrator" "Task task-004 complete..."
```

## Output (Result)

Lane writes to `outbox/<task_id>.result.yaml`:

```yaml
task_id: task-004
agent: pay-doc-lg-settlement
summary: Found mismatch caused by UTC cutoff drift.
insufficient_runtime: false
```

**Before writing/reading YAML:** Load [file-schemas.md](references/file-schemas.md) for complete schemas (meta.yaml, status.yaml, task, result, context_delta, shared_board, request), file ownership rules, and lane state machine.

---

# Cross-Lane Questions (Shared Board)

Lanes do not write `.tmux/shared_board.yaml` directly. They write to `requests/` and signal orchestrator.

**For board/request YAML formats:** Load [file-schemas.md](references/file-schemas.md) — contains shared_board.yaml entry schema, lane-local request schema, and status values (pending, routed, answered, ack, self-resolved, ambiguous).

## Flow

```text
lane posts question → signals orchestrator
  → orchestrator routes to target → marks routed
    → target answers → signals orchestrator
      → orchestrator delivers answer
        → questioner acks → signals orchestrator
          → orchestrator confirms resolved
```

## Lane Protocol

Before asking:
1. Read all `.tmux/*/meta.yaml` `scope_keywords`
2. If exactly one lane matches → write request, signal orchestrator
3. If no lane matches → self-resolve, expand own `scope_keywords`, signal orchestrator
4. If multiple match → escalate to orchestrator (ambiguous ownership)

---

# Journaling

## Orchestrator Journal (`.tmux/journal.md`)

Append immediately on every event:

```markdown
## [2026-03-31T10:25:00Z] [dispatch] task-004 → pay|doc|lg|settlement
Dispatched settlement investigation.

## [2026-03-31T10:45:00Z] [complete] task-004 done
Summary: Mismatch caused by UTC cutoff drift.
```

Tags: `[dispatch]`, `[complete]`, `[board]`, `[escalation]`, `[repair]`, `[decision]`, `[resume]`, `[flush]`

## Lane Journal (`.tmux/<lane>/logs/journal.md`)

Lane maintains own log: task received, findings, board events, complete/blocked.

---

# Session Limits and Recovery

When context limit approaches:
1. Flush summary to `.tmux/journal.md` with `[flush]` tag
2. Write `resume_hint` to `.tmux/runtime.yaml`
3. Inform user

New orchestrator instance reconstructs from journal + state files.

---

# Escalation

Lanes do not spawn stronger lanes. If insufficient runtime:

```yaml
insufficient_runtime: true
recommended_size: xl
reason: Task requires harder planning decision.
```

Orchestrator decides: upgrade, create new lane, or continue.

---

# Operational Guidance

1. Always windows, not sessions
2. Always survey + discovery before spawning
3. Treat lanes as warm context containers
4. File-based output, keystroke-based input
5. Reuse warm lanes when context match is strong
6. Use `tmux_window_id` for live commands, `tmux_window_name` for identity
7. Gamma max 2 active windows

---

# Expected Loop

```text
1. "grand orchestrator" → rename window to orchestrator
2. Onboarding: fresh start or resume
3. Survey work shape
4. Discovery → context profile per sub-task
5. Score lanes → reuse or create
6. Provision window, warm context
7. Dispatch task (write inbox, inject keystrokes)
8. Wait for callbacks (NEVER poll)
9. On signal: collect result, handle board, continue
```

---

# Success Criteria

- Survey + discovery runs before any window spawn
- Windows named consistently, visible as Oh My Tmux tabs
- `.tmux/<lane>/` reflects window reality
- Provider launch uses spawn_*.sh, never raw keystrokes
- Callbacks drive flow, never sleep-polling
- Journal updated on every significant event
- Fresh orchestrator can reconstruct from journal + state files
