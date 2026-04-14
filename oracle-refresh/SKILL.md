---
name: oracle-refresh
description: "Refresh `durian-oracle` documentation by using the `grand orchestrator` skill as the execution runtime. Use when the user says `oracle refresh` or clearly asks to update `durian-oracle` by pulling the latest changes, pulling the service source repos to get the latest code, sizing the `services` update from `git diff`, refreshing `services` first, refreshing downstream non-service areas from that baseline, then running a service-led validation loop and final reference pass before the refresh is considered complete."
---

# Oracle Refresh

Refresh the `durian-oracle` repo in a fixed sequence with a built-in service-to-downstream feedback loop. Always use `grand orchestrator` as the runtime. If `~/skills/grand-orchestrator/SKILL.md` does not exist, reject the request instead of improvising a parallel workflow.

Read [references/durian-oracle-map.md](references/durian-oracle-map.md) before starting so the section meanings stay consistent while updating documents.

## Preconditions

1. Confirm `~/skills/grand-orchestrator/SKILL.md` exists. If it does not, stop and tell the user this skill cannot run because the dependency is missing.
2. Confirm the working tree contains `durian-oracle/`. If not, stop and ask for the correct repo or path.
3. Treat `durian-oracle/` as its own git repo. Work from that directory for pull, diff, and checkpoint steps.
4. Confirm that the service source repos documented by `durian-oracle` are accessible locally. If any are missing, report which ones and ask the user for the correct paths before proceeding.

## Pull Latest

### Pull `durian-oracle`

1. Run `git status --short` inside `durian-oracle/`.
2. If there are local changes, stop and ask the user whether to continue without pulling or to resolve the dirty state first. Do not stash or discard changes automatically.
3. If the tree is clean, run `git pull --ff-only` inside `durian-oracle/` before refreshing any documentation.
4. If pull fails because fast-forward is not possible or the branch is misconfigured, stop and report the exact git issue.

### Pull service source repos

5. After `durian-oracle` is pulled, identify the service source repos that `durian-oracle` documents. Use the `durian-oracle/services` directory to discover which repos are referenced.
6. For each service source repo, run `git pull --ff-only` from its local directory to bring it up to date.
7. If a service repo pull fails, log the failure and continue with the remaining repos. Report all failures at the end of the pull phase so the user can decide how to proceed.
8. Do not start the diff or any refresh work until both `durian-oracle` and the service source repos have been pulled.

### Post-pull diff

9. After all pulls succeed (or failures are acknowledged), run a `git diff` pass inside `durian-oracle/` to understand what changed before allocating any refresh work.

## Runtime

1. Open `~/skills/grand-orchestrator/SKILL.md`.
2. Follow the grand orchestrator workflow and helper rules. Do not use raw tmux commands.
3. Start with a git-diff discovery pass before assigning service work.
4. Run `services` first as the dependency-establishing and later reviewer phase.
5. After `services` is refreshed and checkpointed, choose the downstream lane shape from the size of the service update.
6. If the `services` update is small, keep downstream refresh in one lane.
7. If the `services` update is large, split downstream refresh into multiple lanes so the orchestrator can cover the affected areas efficiently without conflicting edits.
8. Keep the `services` lane warm after its own checkpoint. It must review downstream results, request fixes, and perform the final service-doc reference pass before the refresh is done.

## Refresh Plan

Refresh planning works in five phases:

1. Diff and size the update.
2. Refresh `durian-oracle/services`.
3. Refresh the remaining non-service areas using one lane or multiple lanes depending on the size of the `services` update.
4. Run a service-led validation loop on the non-service results until they match the implementation.
5. Update `services` docs with static and semantic references back into the validated non-service docs.

## Diff And Score

Before refreshing documentation:

1. Run `git diff` inside `durian-oracle/` to inspect the newest code and config changes that the docs should reflect.
2. Use that diff to identify which services changed and how concentrated or widespread the update is.
3. Score the update as either:
   - small: a narrow or tightly related change set
   - large: a broad change set spanning multiple services, cross-cutting behaviors, or many downstream docs
4. Use this score to guide the `services` refresh, the later downstream lane allocation, and the expected breadth of the service review loop.

After the `services` checkpoint passes, refresh these non-service areas based on the size of the `services` update and the dependencies discovered from the service update:

1. `durian-oracle/flows`
2. `durian-oracle/architecture`
3. `durian-oracle/shared`
4. `durian-oracle/domains`
5. `durian-oracle/platform`
6. `durian-oracle/patterns`

For each area:

1. Rebuild context from code, configs, tests, and the existing docs.
2. For non-`services` areas, treat the refreshed `services` docs as an input source and align downstream docs to those service boundaries and responsibilities.
3. Produce a first-pass draft in that directory only. Do not edit `services` during the downstream drafting phase.
4. When the draft is complete, route it back to the `services` lane for critical review against implementation reality and service ownership.
5. Keep terminology aligned with the section definition in [references/durian-oracle-map.md](references/durian-oracle-map.md).
6. Avoid overlapping edits between parallel lanes. If a downstream area requires changing another downstream area, stop, record the dependency, and coordinate at checkpoint time.

## Lane Allocation Rule

Use the size of the `services` update to allocate downstream work.

1. If the `services` update is small, run `flows`, `architecture`, `shared`, `domains`, `platform`, and `patterns` in one downstream lane.
2. If the `services` update is large, split downstream work into multiple lanes based on the affected areas and dependencies revealed by the diff and by the refreshed `services` docs.
3. Do not split work just because parallelism is available. Split only when the breadth of change justifies it.
4. Keep each lane scoped to a coherent set of downstream files to minimize merge friction.
5. Even when downstream work is split across multiple lanes, keep review ownership centralized in the `services` lane unless the service surface itself must be split.

## Service Validation Loop

The `services` lane is the authoritative reviewer for downstream docs because it carries the service-grounded view of the implementation.

After the downstream non-service draft phase, run this loop for every affected area:

1. The `services` lane reviews the downstream result critically against code, configs, tests, and the refreshed `services` docs.
2. The review must look for missing flows, misleading flow descriptions, wrong ownership, broken sequencing, missing handoffs, stale terminology, and claims that are not supported by implementation evidence.
3. The `services` lane must return concrete feedback with anchors whenever possible: repo path, file path, handler or job name, queue or topic name, table name, flag name, and the affected `durian-oracle` doc path or heading.
4. The downstream non-service lane updates its docs based on that feedback and reports back when the corrections are applied.
5. The `services` lane re-reviews the updated downstream docs. Repeat this loop until the `services` lane can state that the downstream docs are accurate to the implementation.
6. After sign-off, the `services` lane updates related `services` markdown to add static and semantic references into the validated downstream docs. Static references mean explicit markdown links to doc paths and heading anchors. Semantic references mean nearby implementation anchors such as handler names, jobs, topics, tables, events, APIs, or flags that explain why the downstream doc matters.
7. Do not mark the overall refresh complete until this review loop is closed for every affected downstream area.

## Checkpoint Rule

After the `services` refresh, after each downstream draft pass, and after each service sign-off pass, do a checkpoint before moving on.

A checkpoint must include:

1. `git status --short` and `git diff --stat` from `durian-oracle/`.
2. A quick review that the edits are limited to the current area, or an explicit note explaining any spillover files.
3. A short summary of what changed, what review feedback remains open, what remains uncertain, and what the next area depends on.
4. A pause for user review when the work is ambiguous, high impact, blocked, or requires re-routing work across parallel lanes.

Checkpoint does not mean auto-commit. Only create git commits if the user explicitly asks for commits.

## Quality Bar

1. Prefer concrete facts over summaries copied from old docs.
2. Reconcile contradictions instead of layering new text over stale text.
3. Call out unknowns explicitly when the repo does not support a stronger claim.
4. Keep cross-links and naming consistent across areas.
5. Treat the service review pass as adversarial verification, not as a rubber stamp.
6. When adding references, prefer stable doc paths, heading anchors, and implementation anchors over vague "see also" text.

## Output

At the end, report:

1. Whether `durian-oracle` pull succeeded.
2. Whether all service source repo pulls succeeded, and which ones failed if any.
3. What the initial `git diff` indicated.
4. How the `services` update was scored.
5. Whether `services` completed before downstream work started.
6. Whether downstream work used one lane or multiple lanes, and why.
7. How the service-led validation loop ran, including any rework rounds.
8. Which `services` docs received final static or semantic references into downstream docs.
9. The checkpoint result for each area.
10. Any unresolved gaps that still need human confirmation.
