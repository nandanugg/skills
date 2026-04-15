---
name: oracle-refresh
description: "Refresh `durian-oracle` documentation by using the `grand orchestrator` skill as the execution runtime. Use when the user says `oracle refresh` or clearly asks to update `durian-oracle` by pulling the latest changes, pulling the service source repos to get the latest code, sizing the `services` update from `git diff`, refreshing `services` first, refreshing downstream non-service areas from that baseline, then running a service-led validation loop and final reference pass before the refresh is considered complete."
---

# Oracle Refresh

Refresh `durian-oracle` docs using `grand orchestrator` as the runtime. Fixed sequence with service-to-downstream feedback loop.

## Core Principle: Docs Optimized for Recall

Every doc must be **findable AND memorable** — optimized for both search retrieval and mid-context attention (avoiding "Lost In The Middle").

### Recall Anchors and Markers

Structure every doc so key information survives attention decay:

- **Front-load keywords**: First paragraph must contain the implementation anchors someone would search for
- **Headers with terms**: Not "Overview" but "Settlement Retry Flow Overview" — keywords in every H2/H3
- **Repeat key identifiers**: Handler names, job names, tables, flags should appear in intro, in relevant sections, and in summary
- **First 5 lines = recall anchor**: Title + one-line summary + key implementation terms

### Static References (Explicit Links)

Explicit markdown links to doc paths and heading anchors:
```markdown
See [settlement retry flow](../flows/settlement.md#retry-logic) for the full sequence.
```

### Semantic References (Implementation Anchors)

Implementation identifiers near the prose — handler names, job names, queue/topic names, table names, flag names, API endpoints:
```markdown
The `ProcessSettlement` handler in `settlement-service` triggers `SettlementRetryJob` 
which reads from `settlement_events` table when `enable_settlement_retry` flag is on.
```

### Why All Three Matter

| Problem | Solution |
|---------|----------|
| Doc can't be found by search | Semantic references (implementation anchors) |
| Doc found but related docs missed | Static references (explicit links) |
| Doc found but key info forgotten mid-conversation | Recall anchors and markers (front-loaded keywords, repeated terms) |

An accurate doc that can't be found OR can't be recalled mid-context is useless.

## Reference Index

| When you need to... | Load this reference |
|---------------------|---------------------|
| **Check section meanings** (services, flows, architecture, shared, domains, platform, patterns) | [durian-oracle-map.md](references/durian-oracle-map.md) |
| **Check service lane groupings** (svc-core, svc-support, svc-platform) | [durian-oracle-map.md](references/durian-oracle-map.md) |
| **Check update order** or downstream lane allocation rule | [durian-oracle-map.md](references/durian-oracle-map.md) |
| **Spawn lanes, write YAML, warm context** | Load `grand-orchestrator` references (provider-matrix.md, file-schemas.md, templates.md) |
| **Structure doc output for recall** (anchors/markers, LITM prevention) | Load `grand-orchestrator` [templates.md](../grand-orchestrator/references/templates.md) — "Output Structure for Recall" section |

---

## Preconditions

1. Confirm `~/skills/grand-orchestrator/SKILL.md` exists. If not, stop — this skill cannot run without it.
2. Confirm `durian-oracle/` exists in the working tree.
3. Confirm service source repos are accessible locally. Report missing ones before proceeding.

---

## Phase 1: Pull Latest

### Pull durian-oracle

1. `git status --short` inside `durian-oracle/`
2. If dirty → stop and ask user (do not auto-stash)
3. If clean → `git pull --ff-only`
4. If pull fails → stop and report exact issue

### Pull service source repos

5. Identify repos from `durian-oracle/services` directory
6. `git pull --ff-only` each repo
7. Log failures, continue with others, report all failures at end
8. Do not start diff until all pulls complete (or failures acknowledged)

### Post-pull diff

9. `git diff` inside `durian-oracle/` to understand changes before allocating work

---

## Phase 2: Diff and Score

1. Run `git diff` to inspect changes
2. Identify which services changed
3. Score as **small** (narrow/related) or **large** (broad/cross-cutting)
4. This score drives lane allocation

---

## Phase 3: Runtime

**Load `~/skills/grand-orchestrator/SKILL.md`** and follow its workflow.

### Services Phase (Parallel)

**For service groupings:** Load [durian-oracle-map.md](references/durian-oracle-map.md) — lists svc-core, svc-support, svc-platform with their services.

1. Split into 3 parallel lanes: `svc-core`, `svc-support`, `svc-platform`
2. Each lane refreshes its assigned service docs
3. Each lane checkpoints independently
4. Keep all service lanes warm after checkpoint

### Downstream Phase

**For downstream areas and lane allocation:** Load [durian-oracle-map.md](references/durian-oracle-map.md) — lists flows, architecture, shared, domains, platform, patterns with meanings.

5. After all service lanes checkpoint, allocate downstream work:
   - **Small update** → one downstream lane
   - **Large update** → multiple lanes based on affected areas
6. Downstream lanes treat refreshed `services` docs as input
7. Route each downstream draft to relevant service lane(s) for review

---

## Phase 4: Service Validation Loop

Service lanes are authoritative reviewers (they carry implementation-grounded view).

For each downstream area:

1. Route to service lane(s) that own relevant services
2. Service lane reviews against code, configs, tests, refreshed service docs
3. Check for: missing flows, wrong ownership, broken sequencing, stale terminology, unsupported claims
4. Return concrete feedback with anchors (repo path, handler name, table, flag, doc heading)
5. Downstream lane applies corrections
6. Service lane re-reviews
7. Repeat until accurate

**After sign-off — Final Reference Pass (dispatch to service lanes):**

Orchestrator dispatches a final task to each service lane: "Add references back into your `services` docs for the downstream docs you just signed off. Optimize for recall anchors and markers."

Each service lane adds:
- **Static references**: Markdown links to validated downstream docs (e.g., link to `flows/settlement.md#retry-logic`)
- **Semantic references**: Implementation anchors near the links (handler names, job names, tables, flags, APIs that explain why the downstream doc matters)
- **Recall markers check**: Verify first 5 lines contain key terms; verify headers include keywords; verify implementation anchors appear in intro and summary

This ensures:
1. Someone searching for `ProcessSettlement` finds both the service doc AND the linked flow doc
2. The doc remains recallable mid-conversation (keywords front-loaded, repeated in headers)

---

## Phase 5: Checkpoint Rule

After each phase (services, downstream draft, sign-off), checkpoint:

1. `git status --short` and `git diff --stat` from `durian-oracle/`
2. Confirm edits limited to current area (or note spillover)
3. Summary: what changed, open feedback, uncertainties, next dependencies
4. Pause for user review if ambiguous, high-impact, or blocked

**Checkpoint ≠ commit.** Only commit if user explicitly asks.

---

## Quality Bar

1. Concrete facts over copied summaries
2. Reconcile contradictions, don't layer over stale text
3. Call out unknowns explicitly
4. Keep cross-links and naming consistent
5. Service review = adversarial verification, not rubber stamp
6. Prefer stable doc paths and implementation anchors over vague "see also"
7. **Recall anchors**: Front-load every doc with keywords in first 5 lines and headers
8. **Semantic density**: Every section must contain at least one implementation anchor (handler, job, table, flag, API)
9. **Search recall**: Write so that searching for any implementation term surfaces the relevant doc
7. **Optimize for search recall**: Every doc must contain the implementation anchors (handler names, job names, tables, flags, APIs) that someone would search for when trying to find that doc

---

## Output

Report at end:

1. Pull results (durian-oracle and service repos)
2. Initial diff summary
3. Services update score (small/large)
4. Whether services completed before downstream
5. Downstream lane allocation (one/multiple) and why
6. Validation loop rounds
7. Which services docs got final references
8. Checkpoint results per area
9. Unresolved gaps needing human confirmation
