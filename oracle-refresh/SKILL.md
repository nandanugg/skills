---
name: oracle-refresh
description: "Refresh `oracle-context` documentation by using the `grand orchestrator` skill as the execution runtime. Use when the user says `oracle refresh` or clearly asks to update `oracle-context` by pulling the latest changes, refreshing `services` first, and then refreshing `flows`, `architecture`, `shared`, `domains`, `platform`, and `patterns` in parallel based on the updated service context, with a checkpoint after each area."
---

# Oracle Refresh

Refresh the `oracle-context` repo in a fixed sequence. Always use `grand orchestrator` as the runtime. If `~/skills/grand_orchestrator/SKILL.md` does not exist, reject the request instead of improvising a parallel workflow.

Read [references/oracle-context-map.md](references/oracle-context-map.md) before starting so the section meanings stay consistent while updating documents.

## Preconditions

1. Confirm `~/skills/grand_orchestrator/SKILL.md` exists. If it does not, stop and tell the user this skill cannot run because the dependency is missing.
2. Confirm the working tree contains `oracle-context/`. If not, stop and ask for the correct repo or path.
3. Treat `oracle-context/` as its own git repo. Work from that directory for pull, diff, and checkpoint steps.

## Pull Latest

1. Run `git status --short` inside `oracle-context/`.
2. If there are local changes, stop and ask the user whether to continue without pulling or to resolve the dirty state first. Do not stash or discard changes automatically.
3. If the tree is clean, run `git pull --ff-only` inside `oracle-context/` before refreshing any documentation.
4. If pull fails because fast-forward is not possible or the branch is misconfigured, stop and report the exact git issue.

## Runtime

1. Open `~/skills/grand_orchestrator/SKILL.md`.
2. Follow the grand orchestrator workflow and helper rules. Do not use raw tmux commands.
3. Run `services` first as the dependency-establishing phase.
4. After `services` is refreshed and checkpointed, use the orchestrator to fan out the remaining areas in parallel when that improves speed and does not create conflicting edits.
5. Prefer one doc lane per area or a clearly reused doc lane, with `services` completed before any downstream area begins.

## Refresh Plan

Refresh `oracle-context/services` first.

After the `services` checkpoint passes, refresh these areas in parallel or in whatever order best matches the discovered dependencies from the services update:

1. `oracle-context/flows`
2. `oracle-context/architecture`
3. `oracle-context/shared`
4. `oracle-context/domains`
5. `oracle-context/platform`
6. `oracle-context/patterns`

For each area:

1. Rebuild context from code, configs, tests, and the existing docs.
2. For non-`services` areas, treat the refreshed `services` docs as an input source and align downstream docs to those service boundaries and responsibilities.
3. Update the docs in that directory only.
4. Keep terminology aligned with the section definition in [references/oracle-context-map.md](references/oracle-context-map.md).
5. Avoid overlapping edits between parallel lanes. If a downstream area requires changing another downstream area, stop, record the dependency, and coordinate at checkpoint time.

## Checkpoint Rule

After each area, do a checkpoint before moving on.

A checkpoint must include:

1. `git status --short` and `git diff --stat` from `oracle-context/`.
2. A quick review that the edits are limited to the current area, or an explicit note explaining any spillover files.
3. A short summary of what changed, what remains uncertain, and what the next area depends on.
4. A pause for user review when the work is ambiguous, high impact, blocked, or requires re-routing work across parallel lanes.

Checkpoint does not mean auto-commit. Only create git commits if the user explicitly asks for commits.

## Quality Bar

1. Prefer concrete facts over summaries copied from old docs.
2. Reconcile contradictions instead of layering new text over stale text.
3. Call out unknowns explicitly when the repo does not support a stronger claim.
4. Keep cross-links and naming consistent across areas.

## Output

At the end, report:

1. Whether pull succeeded.
2. Whether `services` completed before downstream work started.
3. Which downstream areas ran in parallel and which were kept sequential because of conflicts or dependencies.
4. The checkpoint result for each area.
5. Any unresolved gaps that still need human confirmation.
