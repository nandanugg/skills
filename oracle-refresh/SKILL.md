---
name: oracle-refresh
description: Refresh `durian-oracle` by pulling the latest docs and service repos, updating service docs first, and then validating downstream docs through the `grand-orchestrator` runtime. Use when the user asks for an `oracle refresh` or wants the oracle documentation reconciled against the latest code.
---

# Oracle Refresh

Use this skill to refresh `durian-oracle` in a fixed order: sync sources, refresh services first, update downstream docs from that baseline, then run service-led validation.

This skill depends on `grand-orchestrator` for execution and on [references/durian-oracle-map.md](references/durian-oracle-map.md) for service groupings and downstream area allocation.

## Workflow

1. Confirm `grand-orchestrator` exists and the relevant repos are present locally.
2. Check `git status --short` in `durian-oracle`. If dirty, stop and ask the user instead of auto-stashing.
3. Pull `durian-oracle` and then pull the relevant service repos.
4. Inspect the diff and score the services update as `small` or `large`.
5. Refresh `services/` first through orchestrated lanes.
6. Refresh downstream docs from the updated service baseline.
7. Run a service-led validation loop, then add final references back into service docs.
8. Checkpoint after each phase. Commit only if the user explicitly asks.

## Rules

- Do not refresh downstream areas before the service phase stabilizes.
- Validation is adversarial, not ceremonial. Service lanes should challenge ownership, sequencing, terminology, and unsupported claims.
- Optimize docs for recall: front-load important identifiers, keep headings searchable, and include implementation anchors.
- Prefer stable doc links and implementation anchors over vague prose.
- Report failures to pull or missing repos explicitly instead of silently continuing as if the source of truth is complete.

## Common Requests

- `Use oracle refresh to sync durian-oracle.`
- `Use oracle refresh after recent service merges.`
- `Use oracle refresh and keep services ahead of downstream docs.`

## Output Contract

When this skill is active, report:

1. pull results for `durian-oracle` and service repos
2. the initial diff summary and update score
3. service completion status before downstream work
4. downstream lane allocation and validation rounds
5. checkpoint results and unresolved gaps
