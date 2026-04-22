# Provider Matrix

Quick reference for provider/model/reasoning selection.

## Spawn Commands

```bash
# Alpha (Claude)
~/skills/grand-orchestrator/scripts/spawn_alpha.sh "$WINDOW_ID" "sonnet"
# Models: haiku, sonnet, opus

# Beta (Codex)
~/skills/grand-orchestrator/scripts/spawn_beta.sh "$WINDOW_ID" "gpt-5.3-codex-spark" "medium"
# Models: gpt-5.4, gpt-5.4-mini, gpt-5.3-codex, gpt-5.3-codex-spark
# Reasoning: low, medium, high, extra_high

# Gamma (Amp)
~/skills/grand-orchestrator/scripts/spawn_gamma.sh "$WINDOW_ID" "smart"
# Modes: smart, rush
# Max 2 active windows (orchestrator policy)

# Delta (OpenCode)
~/skills/grand-orchestrator/scripts/spawn_delta.sh "$WINDOW_ID" "GPT-5.4 OpenAI" "high"
# GPT labels: "GPT-5.4 OpenAI", "GPT-5.4 mini OpenAI", "GPT-5.3 Codex OpenAI"
# GPT reasoning: low, medium, high, xhigh (store xhigh as extra_high in metadata)
# Gemini label: "Gemini 3.1 Pro Preview Google"
# Gemini reasoning: low, medium, high
```

## Phase + Size to Runtime

| Lane | Allowed Runtimes |
|------|------------------|
| doc-sm | gamma:rush, alpha:haiku, beta:gpt-5.4-mini:low, delta:gpt-5.4-mini:low |
| doc-md | gamma:smart, alpha:sonnet, beta:gpt-5.4:medium, delta:gpt-5.4:medium |
| doc-lg | gamma:smart, alpha:sonnet/opus, beta:gpt-5.4:high, delta:gpt-5.4:high |
| doc-xl | alpha:opus, beta:gpt-5.4:extra_high, delta:gpt-5.4:extra_high |
| code-sm | alpha:haiku, beta:gpt-5.3-codex-spark:medium, delta:gpt-5.3-codex:medium |
| code-md | alpha:sonnet, beta:gpt-5.3-codex-spark:high, delta:gpt-5.3-codex:high |
| code-lg | alpha:sonnet/opus, beta:gpt-5.3-codex-spark:extra_high, delta:gpt-5.3-codex:high |
| code-xl | alpha:opus, beta:gpt-5.3-codex:extra_high, delta:gpt-5.3-codex:extra_high |

Gemini 3.1 Pro is allowed at all levels via delta with matching reasoning (max high for xl).
Use Gemini on delta as the backup runtime when GPT token limits block the preferred GPT lane contract.

### Lane-level runtime defaults

- `doc-*` uses mostly non-Codex defaults.
- `code-sm/md/lg` default Codex runtime is `gpt-5.3-codex-spark` when beta is selected.
- `code-xl` defaults to `gpt-5.3-codex` on beta only.
- For explicit code-lane contracts in `task` files, always apply the contract first, then check tie-breaks.

## Runtime Equivalence

| Tier | Equivalents |
|------|-------------|
| Lightweight | gamma:rush, alpha:haiku, gpt-5.4-mini, gemini:low |
| Balanced | gamma:smart, alpha:sonnet, gpt-5.4:medium-high, gemini:medium-high |
| Maximum | alpha:opus, gpt-5.4:extra_high |
| Coding-fast | alpha:haiku/sonnet, gpt-5.3-codex-spark:medium |
| Coding-balanced | alpha:sonnet/opus, gpt-5.3-codex-spark:high |
| Coding-deep | alpha:opus, gpt-5.3-codex:extra_high |
| GPT limit fallback | delta:gemini:low-high, matched to the closest lane size |

## Tie-Break Rules

1. Reuse a strong warm lane first
2. If no warm lane, prefer Amp while under 2 active windows
3. If Amp cap full, fall back to alpha/beta/delta
4. If the preferred GPT runtime hits token limits, keep the lane on delta and switch to Gemini with the closest matching reasoning level
5. For decision work with no warmth difference, default to alpha
6. For coding work with no warmth difference, default to alpha

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
- Model must be verified against task contract before dispatch (`provider`, `model`, `reasoning`).
- If runtime does not match contract, launch is failed, not degraded.
- For coding tasks, use Codex-family defaults on beta:
  - `code-sm`: `gpt-5.3-codex-spark` + `medium`
  - `code-md`: `gpt-5.3-codex-spark` + `high`
  - `code-lg`: `gpt-5.3-codex-spark` + `extra_high`
  - `code-xl`: `gpt-5.3-codex` + `extra_high` only when required by task contract

### Gamma (Amp)
- Readiness: line containing `──smart──` or `──rush──`
- Switch via `/smart` or `/rush`
- Timeout: 10s

### Delta (OpenCode)
- `/models` then exact picker label selection
- `Select variant` screen may appear - exit with Enter
- Runtime contract is model-family specific:
  - GPT labels support `low | medium | high | xhigh`
  - Gemini supports `low | medium | high`
- `C-t` cycles reasoning through the current model family's allowed levels
- Verify via `Build ...` line
- Timeout: 10s
