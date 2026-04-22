---
name: grand-orchestrator
description: Run a discovery-first tmux orchestration workflow for multi-agent work. Use when the user says `grand orchestrator` or wants a persistent tmux runtime with reusable lanes, callback-driven completion, strict runtime contracts, and file-based task handoff across providers.
---

# Grand Orchestrator

Use this skill to turn tmux into a persistent multi-agent runtime with warm lanes, file-based coordination, and explicit runtime contracts.

Load references only when needed. This skill should stay lean while the detailed schemas, templates, and provider rules live in `references/` and `scripts/`.

## Workflow

1. Rename the current tmux window to `orchestrator` immediately.
2. Survey the task and build a context profile before creating lanes.
3. Reuse a compatible lane when possible; otherwise create one and warm it with the correct template.
4. Dispatch work through inbox files plus callback commands.
5. Wait for callbacks. Do not sleep-poll or watch panes in a loop.
6. Journal important events and keep shared questions on the board.

## Load These References As Needed

- [references/provider-matrix.md](references/provider-matrix.md) for provider choice, model choice, and runtime tie-breaks
- [references/templates.md](references/templates.md) for warmup prompts and recall-oriented output structure
- [references/file-schemas.md](references/file-schemas.md) for `meta.yaml`, `status.yaml`, task, result, and board formats
- [references/runtime-config.yaml](references/runtime-config.yaml) for bootstrapping `.tmux/runtime.yaml`

## Hard Rules

- Use `scripts/tmux_runtime.sh` and the `spawn_*.sh` helpers. Never fall back to raw `tmux send-keys`, `new-window`, or similar commands.
- Completion is callback-driven. Never use sleep loops or pane polling as the control plane.
- Keep warm lanes alive. Do not kill idle lanes just to conserve resources.
- A beta lane is valid only when `provider`, `model`, and `reasoning` match the task contract exactly.
- For resumed sessions, reconstruct state from `.tmux/` and present a summary before continuing.
- Structure outputs for recall: front-load task id, lane key, and implementation anchors.

## Lane Contract

Every dispatched task should make these explicit:

- task id
- goal
- task class and interaction mode
- required runtime
- output path
- callback command

Persist lane identity and runtime facts in `meta.yaml` and `status.yaml`.

## Common Requests

- `Use grand orchestrator for this repo-wide change.`
- `Use grand orchestrator to split this work into tmux lanes.`
- `Use grand orchestrator to resume the current .tmux session.`
- `Use grand orchestrator to run a multi-agent doc refresh.`

## Response Pattern

When this skill is active, answer with:

1. the discovered work shape
2. the lane reuse or creation decision
3. the runtime contract per lane
4. callback or board state that matters
5. the current completion state and open escalations
