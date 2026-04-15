# Provider Matrix

Quick reference for provider/model/reasoning selection.

## Spawn Commands

```bash
# Alpha (Claude)
~/skills/grand-orchestrator/scripts/spawn_alpha.sh "$WINDOW_ID" "sonnet"
# Models: haiku, sonnet, opus

# Beta (Codex)
~/skills/grand-orchestrator/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.4" "high"
# Models: gpt-5.4, gpt-5.4-mini, gpt-5.3-codex
# Reasoning: low, medium, high, extra_high

# Gamma (Amp)
~/skills/grand-orchestrator/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
# Modes: smart, rush
# Max 2 active windows (orchestrator policy)

# Delta (OpenCode)
~/skills/grand-orchestrator/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "high"
# Labels: "GPT-5.4 OpenAI", "GPT-5.4 mini OpenAI", "GPT-5.3 Codex OpenAI", "Gemini 3.1 Pro Preview Google"
# Reasoning: low, medium, high, xhigh (store as extra_high in metadata)
```

## Phase + Size to Runtime

| Lane | Allowed Runtimes |
|------|------------------|
| doc-sm | gamma:rush, alpha:haiku, beta:gpt-5.4-mini:low, delta:gpt-5.4-mini:low |
| doc-md | gamma:smart, alpha:sonnet, beta:gpt-5.4:medium, delta:gpt-5.4:medium |
| doc-lg | gamma:smart, alpha:sonnet/opus, beta:gpt-5.4:high, delta:gpt-5.4:high |
| doc-xl | alpha:opus, beta:gpt-5.4:extra_high, delta:gpt-5.4:extra_high |
| code-sm | alpha:haiku, beta:gpt-5.3-codex:low, delta:gpt-5.3-codex:low |
| code-md | alpha:sonnet, beta:gpt-5.3-codex:medium, delta:gpt-5.3-codex:medium |
| code-lg | alpha:sonnet/opus, beta:gpt-5.3-codex:high, delta:gpt-5.3-codex:high |
| code-xl | alpha:opus, beta:gpt-5.3-codex:extra_high, delta:gpt-5.3-codex:extra_high |

Gemini 3.1 Pro is allowed at all levels via delta with matching reasoning (max high for xl).

## Runtime Equivalence

| Tier | Equivalents |
|------|-------------|
| Lightweight | gamma:rush, alpha:haiku, gpt-5.4-mini, gemini:low |
| Balanced | gamma:smart, alpha:sonnet, gpt-5.4:medium-high, gemini:medium-high |
| Maximum | alpha:opus, gpt-5.4:extra_high |
| Coding | alpha:sonnet/opus, gpt-5.3-codex |

## Tie-Break Rules

1. Reuse a strong warm lane first
2. If no warm lane, prefer Amp while under 2 active windows
3. If Amp cap full, fall back to alpha/beta/delta
4. For decision work with no warmth difference, default to alpha
5. For coding work with no warmth difference, default to alpha

## Provider-Specific Notes

### Alpha (Claude)
- Model selected at launch via `--model=` flag
- No separate reasoning knob - model determines capability
- Timeout: 10s
- Wrong model exit: `/exit` then `C-c` fallback

### Beta (Codex)
- Opens `/model` picker repeatedly until `Select Model and Effort` appears
- Readiness: state line with `gpt-X.X reasoning · N% left`
- Timeout: 10s

### Gamma (Amp)
- Readiness: line containing `──smart──` or `──rush──`
- Switch via `/smart` or `/rush`
- Timeout: 10s

### Delta (OpenCode)
- `/models` then exact picker label selection
- `Select variant` screen may appear - exit with Enter
- `C-t` cycles reasoning: empty → none → low → medium → high → xhigh
- Never persist `empty`; `none` only allowed for Gemini
- Verify via `Build ...` line
- Timeout: 10s
