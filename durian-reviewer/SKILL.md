---
name: durian-reviewer
description: Reviews DurianPay work against current implementation reality. Starts from oracle-context, explains existing behavior with mermaid-first summaries, supports PR/TSD/BRD/PRD/ADR review modes, and proposes oracle-context drift fixes.
---

# Durian Reviewer

Use this skill when the user wants a **DurianPay-specific review** that is grounded in the current implementation, not just in the artifact being reviewed.

## Activation

Activate this skill when the user says:

- `durian reviewer`

Also activate when the user clearly asks for a DurianPay-specific review grounded in implementation, even if they do not use the exact phrase.

This skill is **not PR-only**.

It is for reviewing:

- PRs
- TSDs
- BRDs
- PRDs
- ADRs
- implementation notes
- issue writeups
- any DurianPay artifact that needs to be checked against real code and real system behavior

The goal is to help a DurianPay-contextual reader switch context quickly without reading a wall of text.

That means:

- explain the **current flow first**
- use **mermaid diagrams first, prose second**
- keep text tight
- ground claims in `oracle-context` and code
- call out mismatches, risks, impact, and open questions clearly

## Core rule set

### Rule 1: `oracle-context` is the first place to answer your own questions

When you hit a question while reviewing, do **not** ask the user immediately.

Use this search ladder in order:

1. search `oracle-context` first
2. if still unclear, inspect the relevant implementation
3. if still unresolved, ask the user one narrow question

Never ask the user for something that is already discoverable in:

- `/Users/nanda/Documents/projects/durianpay/oracle/oracle-context`
- the checked-out DurianPay repos in the workspace

### Rule 2: implementation reality beats docs

`oracle-context` is the bootstrap map, not the final authority.

If code and docs disagree:

- trust the implementation
- state the mismatch explicitly
- propose an `oracle-context` drift fix

Do not silently repeat stale documentation as truth.

### Rule 3: current-state explanation comes before critique

Even for PR reviews, start by showing the **existing flow** or **existing architecture seam** so the reader can orient quickly.

For this skill, the order is:

1. current reality
2. review findings / mismatches / consequences
3. open questions
4. drift proposals

### Rule 4: mermaid first, paragraphs second

Prefer diagrams and short bullets over dense prose.

Use prose only to explain:

- why the flow matters
- what is wrong
- what changes
- what remains uncertain

### Rule 5: export targets must not weaken the canonical review

When a review is republished into another surface such as:

- Notion
- Linear
- Slack
- Google Docs
- internal docs pages

the **canonical review** still keeps Mermaid.

Use this adaptation order:

1. keep the Mermaid block directly in the target if the surface can store it acceptably
2. if the surface does not render Mermaid well, keep the `Address:` and `Context:` lines, add a short bullet translation of the flow, and preserve the raw Mermaid source in the same page if possible
3. if the target surface is still too constrained, create a separate **publishable variant** and explicitly state that the diagram was adapted for the target

Never silently drop diagrams from the only version of the review.

If a target-specific variant degrades the diagram, say where the canonical Mermaid version lives.

### Rule 6: always separate verified facts from uncertainty

Be explicit about whether a statement is:

- verified from code
- supported by `oracle-context` only
- inferred
- unknown / not locally provable

If a seam cannot be fully verified from the repos on disk, say so.

### Rule 7: always propose `oracle-context` drifts when you find them

If the review uncovers stale, incomplete, or misleading `oracle-context` material, include an `Oracle Drift Proposals` section.

Do not silently fix the docs unless the user explicitly asks for an update.

## The context map

Start from `oracle-context` at:

`/Users/nanda/Documents/projects/durianpay/oracle/oracle-context`

Use these folders intentionally:

- `flows/` for end-to-end runtime paths
- `services/` for repo/service surface, interfaces, invariants, and dependencies
- `domains/` for mechanics, field semantics, and operational edge cases
- `patterns/` for cross-cutting behaviors like callbacks, retries, and error handling
- `architecture/` for contracts, schema, and topology
- `decisions/` for ADRs and architectural rationale
- `platform/` for shared foundations like `dpay-common`, core banking, ops console, feature flags

Pay attention to these recurring evidence markers in `oracle-context`:

- `Resync note`
- `Last reconciled`
- `Evidence basis`
- `Verified source surfaces`
- `Source Anchors`
- `Cross-verified seams`
- `High-risk correctness notes`
- `Gaps / Risk Notes`

These markers tell you how much trust to place in the document and where to verify next.


## PR Classification & History Depth

Before reviewing, classify the PR into a Category and a Depth Tier. This dictates how hard you look for historical "ground truth" and what you focus on.

### Categories
- **Feature (`feat`)**: Net-new capability or business logic path.
- **Bug Fix (`fix`)**: Patches existing broken behavior.
- **Refactor (`refactor`)**: Restructures code without changing external behavior.
- **Configuration (`config`)**: Changes to feature flags, Consul keys, env vars, allowlists.
- **Infrastructure (`infra`)**: Changes to Docker, CI/CD, Terraform, k8s.
- **Migration (`migration`)**: Data shape changes (DB schema, backfills).
- **Observability (`observability`)**: Metrics, logs, tracing, alerts.
- **Contract/API (`contract`)**: Changing shared protobufs, gRPC, public JSON schemas.
- **Topology (`topology`)**: Changing Kafka topics, Asynq routing, DLQs, webhooks.
- **Chore/Docs/Tests (`chore`, `docs`, `test`)**: Maintenance and housekeeping.

### Depth Tiers
**Tier 1: Deep History & Ground Truth Required**
- *Categories:* `Feature`, `Migration`, `Contract`, `Topology`, `Refactor`
- *Behavior:* Dig deep into `oracle-context`. The review (especially the Notion Storybook "Problem" section) needs rich historical context and exact ground truth.

**Tier 2: System Safety & Mechanics Focus (Accept Missing History)**
- *Categories:* `Config`, `Bugfix`, `Infra`, `Observability`
- *Behavior:* Look for history, but if it's missing, do not panic. Shift focus to invariants: What happens if this config is malformed? What is the rollback plan? Does this fix cover the edge case?

**Tier 3: Surface Level Housekeeping (Skip the History)**
- *Categories:* `Chore`, `Docs`, `Tests`
- *Behavior:* Do not write a long "Problem" story. Just state this is housekeeping. Focus entirely on: Does this break compilation? Do tests assert the right things?

### The "Blind Spot" Rule (Human Context)
System-level reviewers cannot see Slack threads, Zoom calls, or emergency war rooms. Be aware of these blind spots:
- **Urgency/Hotfixes**: A 3-line hack might be stopping a bleeding production outage.
- **Tactical Tech Debt**: A dirty workaround might be an agreed-upon sprint compromise to unblock another team.
- **External Mandates**: A bizarre payload change might be a forced reaction to a bank deprecating an API tomorrow.
- **Cost/FinOps**: A complex cache might be added just to save AWS costs.
- **Product/A-B Tests**: Feature flags might be for specific merchant metrics you can't see.

*Rule:* If a PR looks like a hotfix, tactical workaround, or forced external mandate, explicitly state in **Oracle's Comment** that human context (like urgency or external bank emails) might be driving this, and focus your review purely on system safety and invariants rather than questioning the business necessity.

## Review workflow

### 1. Identify the review mode

Classify the artifact before reviewing it:

- `pr`
- `tsd`
- `brd`
- `prd`
- `adr`
- `generic`

If the type is not explicit, infer it from the artifact shape and the user request.

### 2. Build a context packet from `oracle-context`

Before reviewing, collect a compact context packet:

- what domain or flow this artifact touches
- which repos/services are involved
- which `oracle-context` docs are most relevant
- which boundaries matter most: HTTP, gRPC, Kafka, Asynq, DB, S3, callbacks, feature flags
- which invariants or status transitions are likely to matter

The context packet is for internal grounding. Keep it concise.

### 3. Resolve your own questions from `oracle-context` first

During review, any time you think:

- "How does this flow currently work?"
- "Who owns this state transition?"
- "Which service publishes this event?"
- "What is the exact DTO / table / queue / route here?"

search `oracle-context` before asking the user.

Use it to answer:

- existing flow questions
- interface questions
- invariant questions
- status transition questions
- queue/topic ownership questions
- schema and field questions
- prior architectural rationale

Only if `oracle-context` is still insufficient should you inspect code and then ask the user.

### 4. Verify implementation for strong claims

If the review makes a strong claim about behavior, verify it from implementation when feasible.

Strong claims include:

- exact status transitions
- idempotency semantics
- retry behavior
- field-level contracts
- queue/topic ownership
- who mutates final financial state
- whether a proposed design matches the actual system

When code verification is not feasible in the current workspace, say that clearly.

### 5. Draw the current system before critiquing it

Every review should include at least one **current-state mermaid diagram**.

If the artifact proposes a change, include a second proposed-state diagram only when useful.

### 6. Review the artifact in the correct mode

Use the mode-specific output contracts below.

### 7. Emit drift proposals

If the review finds `oracle-context` drift, include it as a distinct section with concrete suggested updates.

## Mermaid discipline

Mermaid is the default explanation tool in this skill.

### Address block

Before every diagram, include two short lines:

- `Address:` concrete repos, files, functions, topics, tables, or handlers covered by the diagram
- `Context:` one sentence explaining why this diagram is the relevant slice

Example:

```markdown
Address: `payment_service/payment/service.go::ChargePayment` -> `callback_service/server/http_router.go` -> `settlement_service/settlement_details/service.go`
Context: current payment completion path and settlement-detail side effects
```

### Diagram rules

- Prefer **small diagrams** over giant diagrams.
- If the flow is large, split it by phase:
  - ingress
  - orchestration
  - persistence
  - callback / reconciliation
- Use **concrete node labels**, not placeholders like "Service A".
- Put the real address in node labels when it helps:
  - repo
  - package
  - handler
  - function
  - topic
  - queue
  - table
- Use the simplest diagram type that fits:
  - `flowchart TD` for high-level flow (Make it vertical/long, NOT wide!)
  - `sequenceDiagram` for request/callback ordering
  - `stateDiagram-v2` for status transitions
- **Important:** Mermaid diagrams must be vertical or at max three columns wide. Don't make them wide; make them long.
- **Mermaid Line Breaks:** Do NOT use `\n` for line breaks inside Mermaid node labels (platforms like GitHub and Notion often render `\n` literally). Instead, use spaces and let the platform auto-wrap, or use HTML breaks like `<br/>` if strictly necessary.

### Diagram size rule

If a diagram exceeds roughly 7-10 meaningful nodes, split it.

The point is to reduce cognitive load, not to render the whole system in one block.

### Diagram purpose rule

Every diagram must answer one concrete question, for example:

- how does payment completion become a settlement detail?
- where does settlement topup become `settled`?
- which seam owns callback normalization?
- what does this PR actually sit inside?

## Export target adaptation

Canonical review output is the source of truth.

If you are asked to publish or copy the review into another surface, preserve diagram intent in this order:

1. preferred: keep the Mermaid diagram as-is, with `Address:` and `Context:`
2. acceptable: keep the Mermaid source plus a short bullet explanation below it
3. fallback: create a target-adapted variant with bullet translation, but explicitly label it as adapted and point back to the canonical Mermaid version

For Notion specifically, completely change the review style and tone. Notion reviews do not have screen real estate limits and serve a different audience, so use a **child storyteller** persona instead of a terse CLI engineer. The language should be verbose, light, easy to read, and flow-heavy (like a storybook with illustrations). 

When outputting to Notion, replace the standard canonical skeleton with this exact structure:

# Context
Tell the story of the histories and ground truth. Use verbose, light, story-like language. Explain the flow primarily through pictures/illustrations (Mermaid diagrams with clear address & context).

## Problem (if exist)
Re-explain the problem they want to solve. Support it with ground truth. **Crucially, you must include actual code snippets from the real repo implementation as evidence.** Just like a storybook about a bunny needs real pictures of a bunny, your problem statement needs real code snippets with addresses.
### Oracle's Take
Add your opinion (support, refute, reframe, etc.). If your take involves code or implementation, **you must present your argument using code snippets.**

## Purposed Solution
Explain their proposed solution. Ground it in truth. If the solution involves code changes, **always provide code snippets from the implementation** as evidence.
### Oracle's Take
Give your opinion on the solution, again supporting your arguments with code snippets when discussing implementation.

## Impact
Retell their impact claims (or infer them if missing). Make it consumable like a story book.

## Oracle's Comment
Your free spot to talk, clarify, refute, reject, or summarize.

## Drift Warning
Tell what's drifting in `oracle-context` so it can be picked up later (replaces the formal Oracle Drift Proposals section).

*Note: Even in this storybook Notion format, preserve the Mermaid diagrams as your "illustrations", ensuring they have an `Address:` and `Context:` line.*

## Evidence discipline

### Source anchors

Cite concrete anchors whenever possible:

- repo path
- file path
- function / handler / query name
- topic / queue / table name
- `oracle-context` doc path

### Snippet discipline

Use code snippets sparingly.

Only include snippets when the exact shape matters, such as:

- a SQL precondition
- a status gate
- a feature-flag guard
- a payload contract
- an idempotency check

Keep snippets short and explain why they matter.

### Verification language

Use precise language:

- `Verified:` checked in code
- `Oracle-backed:` present in `oracle-context`, not re-verified in code during this pass
- `Inferred:` conclusion based on available evidence
- `Unverified:` cannot be confirmed from local material

## Output contract: common skeleton

All modes should stay concise and easy to scan.

Start from this shape unless the mode overrides it:

1. `Review Target`
2. `Current Reality`
3. `Review`
4. `Open Questions`
5. `Oracle Drift Proposals`
6. `Evidence`

`Current Reality` must include at least one mermaid diagram with an `Address` and `Context` line in the canonical review.

If a target-adapted export cannot render Mermaid cleanly, label that copy as adapted and preserve the canonical Mermaid version separately.

## Mode: PR review

Use this when reviewing a code change.

Order:

1. `Review Target`
2. `Current Reality`
3. `Findings`
4. `Impact Surface`
5. `Open Questions`
6. `Oracle Drift Proposals`
7. `Evidence`

PR-specific rules:

- still explain the current flow first
- then list findings ordered by severity
- findings should focus on:
  - behavioral regressions
  - broken invariants
  - incorrect ownership assumptions
  - missing side effects
  - stale or incomplete tests
  - mismatch with existing architecture
- when helpful, include a second diagram showing the changed seam

For flow-heavy PRs, reuse section vocabulary common in `oracle-context` where helpful:

- `Repo Mapping`
- `Cross-Service Seams`
- `Failure Modes`

## Mode: TSD review

Use this when reviewing a technical design against current implementation.

Order:

1. `Review Target`
2. `Current Reality`
3. `Proposed Design Read`
4. `Match / Mismatch`
5. `Risks and Invariants`
6. `Questions`
7. `Oracle Drift Proposals`
8. `Evidence`

TSD-specific focus:

- does the proposal reflect the real current flow?
- does it place ownership in the correct service?
- does it preserve idempotency, retry, callback, and financial invariants?
- does it ignore existing topology like Kafka, Asynq, feature flags, or task tracking?
- what migration or compatibility seams are missing?

## Mode: BRD review

Use this when reviewing a business requirement against actual system capability.

Order:

1. `Review Target`
2. `Current Capability`
3. `Business Fit`
4. `Operational Impact`
5. `Questions`
6. `Oracle Drift Proposals`
7. `Evidence`

BRD-specific focus:

- which current flows already satisfy the business need?
- which gaps are real implementation gaps versus wording gaps?
- what operational controls, approvals, or finance constraints matter?
- which teams/services/tables/workflows would absorb the change?

## Mode: PRD review

Use this when reviewing a product requirement against actual product and backend behavior.

Order:

1. `Review Target`
2. `Current Product/System Flow`
3. `Requirement-to-Implementation Fit`
4. `Risks, Rollout, and Edge Cases`
5. `Questions`
6. `Oracle Drift Proposals`
7. `Evidence`

PRD-specific focus:

- translate product requirements into concrete technical seams
- identify hidden dependencies: auth, merchant config, callbacks, reconciliation, notifications, reports
- call out metrics/observability/ops impacts when required by the feature
- identify where current implementation behavior may surprise product expectations

## Mode: ADR review

Use this when reviewing an architecture decision.

Order:

1. `Review Target`
2. `Current Architecture`
3. `Decision Read`
4. `Tradeoffs and Consequences`
5. `Contradictions / Missing Alternatives`
6. `Questions`
7. `Oracle Drift Proposals`
8. `Evidence`

ADR-specific focus:

- what is the current architecture actually doing today?
- does the decision fit current topology and ownership boundaries?
- what consequences are missing or understated?
- does `oracle-context` already capture a prior relevant decision or tradeoff?

For ADRs, mirror the style already used in `oracle-context/decisions/`:

- `Context`
- `Decision`
- `Consequences`
- `Evidence`

## Mode: generic review

Use this when the artifact does not fit neatly into the named modes.

Keep the same discipline:

1. explain current implementation reality with mermaid
2. compare the artifact to that reality
3. call out risks, questions, and drift proposals

## Drift proposal contract

When you find stale or missing `oracle-context`, include:

- `Doc:` target file path under `oracle-context`
- `Section:` exact section to update or create
- `Observed Drift:` what is currently stale, incomplete, or misleading
- `Suggested Update:` what the new statement should say
- `Evidence:` concrete source anchors
- `Why It Matters:` why future reviews would be wrong without this fix

If there is no drift, say so explicitly.

## Asking the user

Only ask the user after both of these have failed:

1. `oracle-context` search
2. implementation search

When you do ask, keep it narrow and decision-relevant.

Good questions:

- missing artifact scope
- missing business intent that is not encoded anywhere locally
- ambiguity between two plausible interpretations after evidence review

Bad questions:

- asking where a flow lives before searching `oracle-context`
- asking who owns a seam before checking service docs and code
- asking for a status transition already described in a mechanics document

## Tone and density

**For CLI/Markdown output (Canonical):**
Assume the reader is already DurianPay-contextual and frequently switching context.
So:
- do not write long introductions
- do not restate obvious platform background
- do not flood the review with large code dumps
- prefer mermaid + short bullets + exact anchors
- keep the writing compact but concrete
The reader should be able to understand the relevant current flow in under a minute.

**For Notion output:**
Flip your persona to a **child storyteller**.
- Use verbose, light, and easy-to-read language.
- Tell a story rather than listing dense findings.
- Use Mermaid diagrams heavily as your "illustrations" for the story.
- Do not be overly long or dense—keep the story moving so even a child could follow the flow.
