# File Schemas and Ownership

## Directory Layout

```text
.tmux/
  runtime.yaml              # orchestrator config (see runtime-config.yaml)
  lanes.yaml                # lane registry index
  shared_board.yaml         # cross-lane questions
  journal.md                # orchestrator running log
  <lane_key>/
    meta.yaml               # lane identity and runtime
    status.yaml             # lane state
    context/
      summary.md
      glossary.md
      assumptions.md
      hotspots.md
      recent_findings.md
      last_delta.yaml
    inbox/                  # task files (orchestrator writes)
    outbox/                 # result files (lane writes)
    requests/               # lane-local requests for orchestrator
    logs/
      journal.md            # lane running log
      pane.latest.txt       # latest pane capture
```

## File Ownership

`O` = orchestrator, `L` = lane agent.

| File | Created | Updated | Notes |
|------|---------|---------|-------|
| `.tmux/runtime.yaml` | O | O | L never touches |
| `.tmux/lanes.yaml` | O | O | Orchestrator-owned topology |
| `.tmux/shared_board.yaml` | O | O | L writes requests/, O updates board |
| `.tmux/journal.md` | O | O | L never writes |
| `meta.yaml` | O | O + L | O: identity/runtime; L: `scope_keywords` only |
| `status.yaml` | O | O + L | O: dispatch fields; L: `state`, `needs_input`, `blocked_reason`, `last_heartbeat` |
| `context/*` | L | L | Lane-owned knowledge |
| `inbox/*.yaml` | O | O | L reads only |
| `outbox/*.result.yaml` | L | L | O reads, may delete/archive |
| `requests/*.yaml` | L | L | Lane-local requests |
| `logs/journal.md` | L | L | Lane running log |
| `logs/pane.latest.txt` | O | O | Written by poll |

## meta.yaml

```yaml
lane_key: pay-doc-lg-settlement
tmux_window_name: pay|doc|lg|settlement
tmux_window_id: "@12"
provider: beta                    # alpha, beta, gamma, delta
model: gpt-5.4                    # provider-specific
reasoning: high                   # beta/delta only
mode: smart                       # gamma only
phase: doc                        # doc or code
size: lg                          # sm, md, lg, xl
lane: settlement                  # discovered label
workdir: /repo/payments
workdir_name: payments
context_profile: normal
verified: true
created_at: "2026-03-31T10:00:00Z"
scope_keywords:
  - settlement
  - payout
  - reconciliation
```

## status.yaml

```yaml
state: idle                       # see Lane States below
task_id: null
needs_input: false
blocked_reason: null
last_heartbeat: "2026-03-31T10:20:00Z"
runtime_verified: true
context_initialized: true
```

## Lane States

```text
provisioning      — creating metadata and files
booting_cli       — runtime process launching
selecting_runtime — choosing provider model/mode
verifying_runtime — confirming selected runtime
warming_context   — injecting Template A or B
idle              — ready for work
running           — working on task_id
needs_input       — blocked on question
done              — result written, awaiting collection
failed            — needs repair or reset
stale             — should not reuse until refreshed
```

## lanes.yaml

```yaml
version: 1
lanes:
  pay-doc-lg-settlement:
    workdir: "/repo/payments"
    tmux_window_name: "pay|doc|lg|settlement"
    tmux_window_id: "@12"
    last_used_at: "2026-03-31T10:20:00Z"
    warmth_score: 0.91
    scope_keywords: [settlement, payout, reconciliation]
```

## Task File (inbox/)

```yaml
task_id: task-004
goal: Investigate payout mismatch between gateway reports and internal ledger.
constraints:
  - Preserve auditability
  - Call out assumptions explicitly
output_path: .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml
context_delta_path: .tmux/pay-doc-lg-settlement/context/last_delta.yaml
callback_cmd: ~/skills/grand-orchestrator/scripts/tmux_runtime.sh send-commands "orchestrator" "Task task-004 complete. Result at .tmux/pay-doc-lg-settlement/outbox/task-004.result.yaml"
```

## Result File (outbox/)

```yaml
task_id: task-004
agent: pay-doc-lg-settlement
summary: Found mismatch caused by UTC settlement cutoff drift.
artifacts:
  - docs/reconciliation-findings.md
recommended_next_step: Validate cutoff logic against three historical days.
insufficient_runtime: false
```

## Context Delta

```yaml
task_id: task-004
new_terms:
  - settlement cutoff drift
new_patterns:
  - gateway batch date differs from posting date across timezone boundary
new_assumptions:
  - settlement comparisons should default to UTC
hotspots:
  - internal/settlement
  - internal/ledger
confidence: 0.84
```

## shared_board.yaml

```yaml
- question_id: q-001
  asked_by_lane: pay-code-md-api
  asked_by_window_name: pay|code|md|api
  question: Does the settlement cutoff apply in gateway local time or UTC?
  target_lane: pay-doc-lg-settlement
  target_window_name: pay|doc|lg|settlement
  answer: null
  status: pending          # pending, routed, answered, ack, self-resolved, ambiguous
  asked_at: "2026-03-31T10:25:00Z"
  answered_at: null
  acked_at: null
```

## Lane-Local Request (requests/)

```yaml
request_type: question
local_request_id: question-001
from_lane: pay-code-md-api
from_window_name: pay|code|md|api
question: Does the settlement cutoff apply in gateway local time or UTC?
ownership_matches: 1              # 0 = self-resolve, 1 = route, >1 = ambiguous
candidate_target_lane: pay-doc-lg-settlement
self_resolved: false
answer: null
status: pending
```

## Journal Entry Tags

Orchestrator journal (`.tmux/journal.md`):
```text
[dispatch]    — task sent to lane
[complete]    — task result received
[board]       — cross-lane question event
[escalation]  — runtime upgrade or new lane
[repair]      — window recreated or lane reset
[decision]    — non-obvious routing choice
[context]     — context delta merged
[resume]      — orchestrator restarted
[flush]       — context limit approaching
```

Lane journal (`.tmux/<lane>/logs/journal.md`):
- Task received
- Significant finding
- Board question posted/answered
- Task complete/blocked
