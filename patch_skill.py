import os

filepath = "/Users/nanda/skills/durian-reviewer/SKILL.md"
with open(filepath, 'r') as f:
    content = f.read()

old_notion = """For Notion specifically:

- prefer keeping the raw Mermaid fenced block in the page if the page remains readable
- if readability is poor, keep `Address:` and `Context:`, add a compact bullet translation, and retain the canonical Mermaid review elsewhere
- do not let the Notion page become the only surviving copy if Mermaid was removed"""

new_notion = """For Notion specifically, completely change the review style and tone. Notion reviews do not have screen real estate limits and serve a different audience, so use a **child storyteller** persona instead of a terse CLI engineer. The language should be verbose, light, easy to read, and flow-heavy (like a storybook with illustrations). 

When outputting to Notion, replace the standard canonical skeleton with this exact structure:

# Context
Tell the story of the histories and ground truth. Use verbose, light, story-like language. Explain the flow primarily through pictures/illustrations (Mermaid diagrams with clear address & context).

## Problem (if exist)
Re-explain the problem they want to solve. Support it with ground truth (context, code snippets with addresses, Mermaid flows).
### Oracle's Take
Add your opinion (support, refute, reframe, etc.) as long as it's reasonable with the goal.

## Purposed Solution
Explain their proposed solution. Ground it in truth (context, code snippets, flows).
### Oracle's Take
Give your opinion on the solution.

## Impact
Retell their impact claims (or infer them if missing). Make it consumable like a story book.

## Oracle's Comment
Your free spot to talk, clarify, refute, reject, or summarize.

## Drift Warning
Tell what's drifting in `oracle-context` so it can be picked up later (replaces the formal Oracle Drift Proposals section).

*Note: Even in this storybook Notion format, preserve the Mermaid diagrams as your "illustrations", ensuring they have an `Address:` and `Context:` line.*"""

content = content.replace(old_notion, new_notion)

old_tone = """## Tone and density

Assume the reader is already DurianPay-contextual and frequently switching context.

So:

- do not write long introductions
- do not restate obvious platform background
- do not flood the review with large code dumps
- prefer mermaid + short bullets + exact anchors
- keep the writing compact but concrete

The reader should be able to understand the relevant current flow in under a minute."""

new_tone = """## Tone and density

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
- Do not be overly long or dense—keep the story moving so even a child could follow the flow."""

content = content.replace(old_tone, new_tone)

with open(filepath, 'w') as f:
    f.write(content)
