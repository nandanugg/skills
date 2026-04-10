import os

filepath = "/Users/nanda/skills/durian-reviewer/SKILL.md"
with open(filepath, 'r') as f:
    content = f.read()

new_classification_section = """
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
"""

# Insert before "## Review workflow"
content = content.replace("## Review workflow", new_classification_section + "\n## Review workflow")

with open(filepath, 'w') as f:
    f.write(content)
