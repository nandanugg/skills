import os

filepath = "/Users/nanda/skills/durian-reviewer/SKILL.md"
with open(filepath, 'r') as f:
    content = f.read()

old_mermaid = """- Use the simplest diagram type that fits:
  - `flowchart LR` for high-level flow
  - `sequenceDiagram` for request/callback ordering
  - `stateDiagram-v2` for status transitions"""

new_mermaid = """- Use the simplest diagram type that fits:
  - `flowchart TD` for high-level flow (Make it vertical/long, NOT wide!)
  - `sequenceDiagram` for request/callback ordering
  - `stateDiagram-v2` for status transitions
- **Important:** Mermaid diagrams must be vertical or at max three columns wide. Don't make them wide; make them long."""

content = content.replace(old_mermaid, new_mermaid)

old_notion_sections = """## Problem (if exist)
Re-explain the problem they want to solve. Support it with ground truth (context, code snippets with addresses, Mermaid flows).
### Oracle's Take
Add your opinion (support, refute, reframe, etc.) as long as it's reasonable with the goal.

## Purposed Solution
Explain their proposed solution. Ground it in truth (context, code snippets, flows).
### Oracle's Take
Give your opinion on the solution."""

new_notion_sections = """## Problem (if exist)
Re-explain the problem they want to solve. Support it with ground truth. **Crucially, you must include actual code snippets from the real repo implementation as evidence.** Just like a storybook about a bunny needs real pictures of a bunny, your problem statement needs real code snippets with addresses.
### Oracle's Take
Add your opinion (support, refute, reframe, etc.). If your take involves code or implementation, **you must present your argument using code snippets.**

## Purposed Solution
Explain their proposed solution. Ground it in truth. If the solution involves code changes, **always provide code snippets from the implementation** as evidence.
### Oracle's Take
Give your opinion on the solution, again supporting your arguments with code snippets when discussing implementation."""

content = content.replace(old_notion_sections, new_notion_sections)

with open(filepath, 'w') as f:
    f.write(content)
