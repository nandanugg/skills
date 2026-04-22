---
name: durian-worker
description: Work on DurianPay code and architecture with oracle-first grounding. Use when the user asks about DurianPay systems, services, payment flows, settlement, disbursement, callbacks, or code changes that should be grounded in `durian-oracle`, recent PR activity, and the current implementation.
---

# Durian Worker

Use this skill for DurianPay engineering work that should be grounded in both documentation and live repository state.

The default operating loop is `Assess -> Plan -> Do`. Start from `durian-oracle`, map the request to the right repos and domains, then cross-check important claims in code.

## Workflow

1. Classify the request: question, code task, review, debug, documentation, architecture, investigation, or operational.
2. Read the most relevant `durian-oracle` documents before forming an answer.
3. If the question touches current behavior, scan recent PRs for the affected repo and use a `/tmp/durian-worker/{repo}` worktree when freshness matters.
4. Ask a narrow clarifying question only when the request is broad or the workspace cannot answer it safely.
5. Produce a small plan, then execute. For code tasks, modify files and verify results instead of stopping at analysis.

## Core Inputs

- Oracle root: `/Users/nanda/Documents/projects/durianpay/durian-oracle`
- Repo root pattern: `/Users/nanda/Documents/projects/durianpay/{repo_name}`
- Optional index: [oracle-index.md](oracle-index.md)

## Rules

- Oracle first, code second, user questions third.
- Treat implementation as the final authority when code and docs disagree.
- For broad questions, clarify the intended slice instead of answering an arbitrary subset.
- For operational requests, state clearly that you can inspect code and docs but not live runtime state unless tooling for that is available.
- For code tasks and investigations, check whether recent or open PRs already overlap the requested area.
- If local repos may be stale, read from `/tmp/durian-worker/{repo_name}` after fetching and adding a detached worktree.
- Keep the answer scoped to the user request. Do not dump the whole oracle when only one flow matters.

## Mapping Heuristic

Use these common starting points:

- payments: `flows/payment-in.md`, `flows/payment-out.md`, `services/payment_service.md`
- settlement: `flows/settlement.md`, settlement domain docs, settlement service docs
- refunds: `flows/refund.md`, `services/refund_service.md`
- callbacks and idempotency: `patterns/callback-and-idempotency.md`, `services/callback_service.md`
- auth or onboarding: auth and merchant flow docs plus the relevant service docs
- cross-service questions: `references/oracle-context-map.md` before narrowing further

## Delivery Rules

- For questions: explain the flow clearly and cite the evidence source type.
- For code tasks: implement, run the most relevant checks you can, and state any unverified risk.
- For reviews: identify findings first, then summarize.
- For debug and investigations: separate confirmed causes from plausible hypotheses.
- For documentation tasks: write from implementation reality, not from stale summaries.

## Common Requests

- `Use durian worker to trace the settlement flow.`
- `Use durian worker to fix this bug in payment_service.`
- `Use durian worker to review whether this proposal matches current architecture.`
- `Use durian worker to explain how callbacks are handled today.`

## Response Pattern

When this skill is active, answer with:

1. the task classification
2. the oracle and repo surfaces you used
3. the short plan or execution path
4. the result, findings, or code changes
5. verification status and remaining uncertainty
