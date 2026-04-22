---
name: durian-reviewer
description: Review DurianPay PRs, docs, and design artifacts against current implementation reality. Use when the user wants a DurianPay-specific review grounded in `oracle-context` and code, with current-state diagrams, explicit evidence labels, and drift proposals when docs disagree with implementation.
---

# Durian Reviewer

Use this skill for DurianPay reviews that must be grounded in the current system, not only in the artifact being reviewed.

Start from `oracle-context`, verify strong claims in code, explain the current flow before critique, and call out doc drift when implementation and documentation disagree.

## Workflow

1. Classify the artifact: `pr`, `tsd`, `brd`, `prd`, `adr`, or `generic`.
2. Build a small context packet from `/Users/nanda/Documents/projects/durianpay/oracle/oracle-context`.
3. Resolve review questions from `oracle-context` first, then inspect implementation for strong claims.
4. Show current reality first. Prefer Mermaid for flow or architecture-heavy reviews.
5. Present findings, open questions, and `oracle-context` drift proposals separately.

## Rules

- Search `oracle-context` before asking the user questions the workspace can already answer.
- Treat implementation as the final authority. If code and docs disagree, trust code and state the mismatch explicitly.
- Explain the existing flow or seam before critiquing the change.
- Prefer Mermaid-first summaries for runtime flow, ownership, sequencing, and architecture boundaries.
- Label claims clearly as `verified from code`, `supported by oracle-context`, `inferred`, or `unknown`.
- If a review is republished into Notion, Linear, Slack, or another surface, keep a canonical Mermaid version somewhere explicit.
- Do not silently update docs during review. Propose drift fixes unless the user asks for documentation edits.
- Keep the review tight. Use diagrams and short bullets before long prose.

## Mode Guidance

- `pr`: prioritize regressions, contract breaks, retries, idempotency, ownership changes, and missing tests.
- `tsd` or `adr`: check whether the proposal matches current seams, invariants, and existing ownership.
- `brd` or `prd`: challenge product assumptions that conflict with current system behavior or operational constraints.
- `generic`: still follow the same evidence ladder and current-state-first structure.

## Evidence Sources

Use these `oracle-context` areas intentionally:

- `flows/` for end-to-end runtime paths
- `services/` for service responsibilities, interfaces, and dependencies
- `domains/` for mechanics and business rules
- `patterns/` for callbacks, retries, idempotency, and error handling
- `architecture/` for contracts, schema, and topology
- `decisions/` for ADRs and historical rationale
- `platform/` for shared foundations

Pay attention to evidence markers such as `Last reconciled`, `Evidence basis`, `Source Anchors`, and `Gaps / Risk Notes` before deciding how much trust to place in a document.

## Output Contract

When this skill drives the review, structure the answer in this order:

1. `Current Reality`
2. `Findings`
3. `Open Questions`
4. `Oracle Drift Proposals`

For flow-heavy reviews, include:

- `Address:` one line on the surface being reviewed
- `Context:` one line on the touched services or boundaries
- a Mermaid block that explains the current flow or seam

Keep snippets short and use exact paths, identifiers, and interfaces when citing evidence.

## Common Requests

- `Use durian reviewer on this PR.`
- `Review this TSD against the current settlement flow.`
- `Check whether this BRD matches implementation reality.`
- `Explain the current callback flow first, then critique the proposal.`

## Response Pattern

When this skill is active, answer with:

1. the review mode you inferred
2. the current system view that frames the review
3. findings ordered by severity
4. any unknowns that are not locally provable
5. explicit doc drift follow-ups when relevant
