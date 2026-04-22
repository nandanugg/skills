# Lane Warmup Templates

Use these templates when injecting the initial prompt into a lane window via `tmux_runtime.sh send-commands`.

## Output Structure for Recall (LITM Prevention)

Every output (result files, context files, journal entries) must be structured to survive mid-conversation attention decay. Front-load recall anchors:

### Result Files (`outbox/*.result.yaml`)

```yaml
# First 3 fields = recall anchors (always present, always first)
task_id: task-004
lane_key: pay-doc-lg-settlement
summary: "Settlement retry: ProcessSettlement handler → SettlementRetryJob → settlement_events table"

# Implementation anchors in summary (searchable terms)
# - Handler: ProcessSettlement
# - Job: SettlementRetryJob  
# - Table: settlement_events
# - Flag: enable_settlement_retry

artifacts: [...]
```

### Journal Entries

```markdown
## [2026-03-31T10:25:00Z] [dispatch] task-004 | pay-doc-lg-settlement | settlement retry investigation
Keywords: ProcessSettlement, SettlementRetryJob, settlement_events, retry_count

Started investigating settlement retry flow...
```

Format: `[timestamp] [tag] task_id | lane_key | one-line with keywords`

### Context Files

- **Headers with keywords**: Not "Overview" but "Settlement Retry Flow Overview"
- **First paragraph**: Include implementation anchors (handler, job, table, flag names)
- **Cross-references explicit**: `See task-003 result` or `Related: pay-code-md-api lane`

### Why This Matters

Long conversations suffer from "Lost In The Middle" (LITM) — content in the middle gets less attention. By front-loading identifiers and repeating keywords in headers, the content stays findable even as context grows.

## Template A: New Lane, New Subagent

Use when creating a brand new lane.

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

Journaling: maintain logs/journal.md. Append a timestamped markdown entry when you receive a task, make a significant finding, post or receive a board question, or complete/block. Format: `[timestamp] [tag] task_id | lane_key | one-line with keywords`.

Output structure for recall: Front-load every output with recall anchors. First 3 lines of any result: task_id, lane_key, summary with implementation keywords (handler names, job names, tables, flags). This prevents "Lost In The Middle" attention decay.

Board protocol: before asking a cross-lane question, read all `.tmux/*/meta.yaml` `scope_keywords`. If exactly one other lane owns the topic, write a request file in `requests/` and signal the orchestrator with `tmux_runtime.sh send-commands`. If no lane owns it, expand your own `scope_keywords`, self-resolve, and signal the orchestrator the same way so it can mirror the update into global files. If more than one lane matches, write a request file and escalate — do not pick a winner yourself.

Task handling protocol: When you receive a task in `inbox/<task_id>.yaml`, it contains:
- `task_id`: unique identifier
- `task_class`: code | doc | ops | triage
- `interaction_mode`: edit | review | diagnose
- `goal`: what to accomplish
- `required_runtime`: required runtime contract for this task
- `constraints`: guidelines to follow
- `output_path`: where to write your result file
- `callback_cmd`: **a bash command you must execute when done**

The `callback_cmd` is critical — it signals the orchestrator that your task is complete. When you finish:
1. Write your result to `output_path`
2. Update `status.yaml` state to `done`
3. **Execute `callback_cmd` as a bash command** (run it via Bash tool, not just echo it)

The callback routes through tmux to notify the orchestrator window. Without executing it, the orchestrator never knows you finished.

Await your first task in inbox/.
```

## Template B: Existing Lane, Replacement Subagent

Use when a lane already has context files but needs a fresh subagent (prior one hit context limits or session died).

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

Journaling: maintain logs/journal.md. Append a timestamped markdown entry when you receive a task, make a significant finding, post or receive a board question, or complete/block. Start now with a [resumed] entry. Format: `[timestamp] [tag] task_id | lane_key | one-line with keywords`.

Output structure for recall: Front-load every output with recall anchors. First 3 lines of any result: task_id, lane_key, summary with implementation keywords (handler names, job names, tables, flags). This prevents "Lost In The Middle" attention decay.

Board protocol: before asking a cross-lane question, read all `.tmux/*/meta.yaml` `scope_keywords`. If exactly one other lane owns the topic, write a request file in `requests/` and signal the orchestrator with `tmux_runtime.sh send-commands`. If no lane owns it, expand your own `scope_keywords`, self-resolve, and signal the orchestrator the same way so it can mirror the update into global files. If more than one lane matches, write a request file and escalate — do not pick a winner yourself.

Task handling protocol: When you receive a task in `inbox/<task_id>.yaml`, it contains:
- `task_id`: unique identifier
- `task_class`: code | doc | ops | triage
- `interaction_mode`: edit | review | diagnose
- `goal`: what to accomplish
- `required_runtime`: required runtime contract for this task
- `constraints`: guidelines to follow
- `output_path`: where to write your result file
- `callback_cmd`: **a bash command you must execute when done**

The `callback_cmd` is critical — it signals the orchestrator that your task is complete. When you finish:
1. Write your result to `output_path`
2. Update `status.yaml` state to `done`
3. **Execute `callback_cmd` as a bash command** (run it via Bash tool, not just echo it)

The callback routes through tmux to notify the orchestrator window. Without executing it, the orchestrator never knows you finished.

If an interrupted task exists, continue it. Otherwise, set status.yaml state to idle and await dispatch.
```

## Context File Skeletons

Agents create these when initializing a lane.

### context/summary.md

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

### context/glossary.md

```markdown
# Glossary: <lane_label>

| Term | Definition |
|------|-----------|
| <term> | <short definition> |
```

### context/assumptions.md

```markdown
# Assumptions: <lane_label>

- **<assumption>** — <basis or source> (confidence: high/medium/low)
```

### context/hotspots.md

```markdown
# Hotspots: <lane_label>

## Files
- `<path/to/file>` — <why it matters>

## Directories
- `<path/to/dir/>` — <what lives here>

## Docs
- `<path/to/doc>` — <relevance>
```

### context/recent_findings.md

```markdown
# Recent findings: <lane_label>

## [<ISO-timestamp>] <short title>
<1-3 sentences: what was learned and why it matters for future tasks>
```

Keep all context files concise. Prune `recent_findings.md` to the 5-10 most relevant entries.
