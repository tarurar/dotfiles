# Claude Code Custom Model Context Windows

## Purpose

`~/.local/share/claude/providers.zsh` runs Claude Code against custom
Anthropic-compatible providers and models. These custom models can have context
windows that are different from Claude Code's standard 200K default.

Claude Code does not reliably infer the real context window for every custom
model behind OpenRouter, Baseten, or a direct Anthropic-compatible endpoint. If
Claude Code treats the model as a standard 200K model, `/context` reports a
200K denominator and auto-compaction can trigger too early.

## The `[1m]` Suffix

Claude Code supports a `[1m]` suffix on model aliases and full model names for
extended-context models. In this setup the suffix is used as a Claude Code CLI
workaround, not as a provider model name.

The wrapper sets model variables such as:

```bash
ANTHROPIC_MODEL="moonshotai/kimi-k2.6[1m]"
ANTHROPIC_DEFAULT_OPUS_MODEL="moonshotai/kimi-k2.6[1m]"
ANTHROPIC_DEFAULT_SONNET_MODEL="moonshotai/kimi-k2.6[1m]"
ANTHROPIC_DEFAULT_HAIKU_MODEL="moonshotai/kimi-k2.6[1m]"
CLAUDE_CODE_SUBAGENT_MODEL="moonshotai/kimi-k2.6[1m]"
```

This makes Claude Code treat the session as an extended-context session instead
of falling back to its 200K custom-model default. Claude Code strips the suffix
before sending the model ID to the provider, so the provider still receives the
real provider model ID, for example `moonshotai/kimi-k2.6`.

Set the suffix on every model variable that should use extended-context
accounting. Claude Code reads the suffix per variable; a plain model ID in one
variable can make that path use 200K accounting even if another variable for the
same model includes `[1m]`. Do not add the suffix to a model whose provider route
is really 200K.

## Auto-Compaction Window

The `[1m]` suffix only changes Claude Code's internal model context accounting.
It does not mean every provider model really supports 1M tokens.

The real provider-safe compaction point is controlled separately:

```bash
CLAUDE_CODE_AUTO_COMPACT_WINDOW="<real-model-context-window>"
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
```

`CLAUDE_CODE_AUTO_COMPACT_WINDOW` sets the token capacity used for
auto-compaction calculations. `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` applies as a
percentage of that value.

`ccoa` is the exception in this repo. It routes Claude Code's own Anthropic
family aliases through OpenRouter and does not set `CLAUDE_CODE_AUTO_COMPACT_WINDOW`.
Fable, Opus, and Sonnet use `[1m]`; Haiku stays on the standard 200K route.

In this setup:

| Model | Real context window | Auto-compact threshold |
| --- | ---: | ---: |
| OpenRouter Anthropic Fable latest | `1000000` | Claude Code 1M default |
| OpenRouter Anthropic Opus latest | `1000000` | Claude Code 1M default |
| OpenRouter Anthropic Sonnet latest | `1000000` | Claude Code 1M default |
| OpenRouter Anthropic Haiku latest | `200000` | Claude Code 200K default |
| Kimi K2.6 | `262144` | about `235930` tokens |
| DeepSeek V4 Pro | `1048576` | about `943718` tokens |
| GLM 5.1 | `202752` | about `182477` tokens |

The expected behavior is:

1. `/context` should stop showing a 200K denominator for these custom models.
2. Auto-compaction should trigger at 90% of `CLAUDE_CODE_AUTO_COMPACT_WINDOW`,
   not at 90-95% of Claude Code's 200K fallback, for wrappers that set that
   variable.
3. The provider should still receive the model ID without `[1m]`.

## Current Aliases

| Alias | Provider | Claude Code model string | Real provider model |
| --- | --- | --- | --- |
| `ccoa` | OpenRouter Anthropic 1P | `~anthropic/claude-fable-latest[1m]`, `~anthropic/claude-opus-latest[1m]`, `~anthropic/claude-sonnet-latest[1m]`, `~anthropic/claude-haiku-latest` | `~anthropic/claude-*-latest` |
| `ccoki` | OpenRouter | `moonshotai/kimi-k2.6[1m]` | `moonshotai/kimi-k2.6` |
| `ccods` | OpenRouter | `deepseek/deepseek-v4-pro[1m]` | `deepseek/deepseek-v4-pro` |
| `ccog` | OpenRouter | `z-ai/glm-5.1[1m]` | `z-ai/glm-5.1` |
| `ccbki` | Baseten | `moonshotai/Kimi-K2.6[1m]` | `moonshotai/Kimi-K2.6` |
| `ccbg` | Baseten | `zai-org/GLM-5.1[1m]` | `zai-org/GLM-5.1` |
| `ccks` | Kimi direct | `kimi-for-coding[1m]` | `kimi-for-coding` |

## Verification

Start one of the aliases and run:

```text
/context
```

The denominator should reflect extended-context accounting rather than 200K.
For Kimi and GLM, the denominator may be larger than the model's real usable
window because `[1m]` is intentionally forcing Claude Code out of the 200K
fallback path. The actual compaction limit remains the explicit
`CLAUDE_CODE_AUTO_COMPACT_WINDOW` value.

Also run:

```text
/status
```

Confirm that the session is using the intended provider endpoint and token
source.

## References

- Claude Code model configuration: `https://code.claude.com/docs/en/model-config`
- Claude Code environment variables: `https://code.claude.com/docs/en/env-vars`
- OpenRouter model metadata: `https://openrouter.ai/api/v1/models`
