# Claude Code OpenRouter Models

## Purpose

`~/.local/share/claude/providers.zsh` defines short shell functions for running Claude Code through OpenRouter's Anthropic-compatible endpoint.

OpenRouter mode does not use the local Baseten proxy.

## Required Configuration

Set an OpenRouter API key in `~/.local_env`:

```bash
export OPENROUTER_API_KEY="sk-or-..."
```

Reload the shell:

```bash
source ~/.zshrc
```

If Claude Code was previously logged in with Anthropic, run `/logout` once inside Claude Code, quit, and relaunch with one of the OpenRouter functions.

## Functions

| Function | Provider | Claude Code model string | Provider model |
| --- | --- | --- | --- |
| `ccoa` | OpenRouter Anthropic 1P | `fable`, `opus`, `sonnet`, `haiku` aliases | pinned Anthropic Claude models |
| `ccoki` | OpenRouter | `moonshotai/kimi-k2.6[1m]` | `moonshotai/kimi-k2.6` |
| `ccods` | OpenRouter | `deepseek/deepseek-v4-pro[1m]` | `deepseek/deepseek-v4-pro` |
| `ccog` | OpenRouter | `z-ai/glm-5.1[1m]` | `z-ai/glm-5.1` |

## Usage

Start Claude Code with OpenRouter-routed Anthropic models:

```bash
ccoa
```

Inside that session, use `/model` to switch between Fable, Opus, Sonnet, and
Haiku. `ccoa` starts on the `sonnet` alias.

Start Claude Code with OpenRouter Kimi K2.6:

```bash
ccoki
```

Start Claude Code with OpenRouter DeepSeek V4 Pro:

```bash
ccods
```

Start Claude Code with OpenRouter GLM 5.1:

```bash
ccog
```

Pass normal Claude Code arguments after the function name:

```bash
ccoa --permission-mode plan
ccog --permission-mode plan
ccods -p "summarize this repo"
```

## Runtime Environment

Every OpenRouter wrapper sets:

```bash
ANTHROPIC_BASE_URL="https://openrouter.ai/api"
ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
ANTHROPIC_API_KEY=""
```

`ANTHROPIC_API_KEY` is explicitly empty to avoid Claude Code falling back to
Anthropic authentication.

### Anthropic Family Wrapper

`ccoa` maps Claude Code's built-in family aliases to OpenRouter Anthropic
first-party routes:

```bash
ANTHROPIC_DEFAULT_FABLE_MODEL="anthropic/claude-fable-5[1m]"
ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic/claude-opus-4.5[1m]"
ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic/claude-sonnet-4.6[1m]"
ANTHROPIC_DEFAULT_HAIKU_MODEL="anthropic/claude-haiku-4.5"
ANTHROPIC_MODEL="sonnet"
CLAUDE_CODE_SUBAGENT_MODEL="anthropic/claude-sonnet-4.6[1m]"
CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY="1"
CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK="1"
CLAUDE_CODE_EXTRA_BODY='{"provider":{"order":["anthropic"],"allow_fallbacks":true}}'
```

Fable, Opus, and Sonnet carry the `[1m]` suffix so Claude Code's `/context`
view uses extended-context accounting. Haiku intentionally has no suffix
because the OpenRouter `anthropic/claude-haiku-4.5` route is 200K.
`ccoa` does not set `CLAUDE_CODE_AUTO_COMPACT_WINDOW`; it relies on Claude
Code's native context handling for these Anthropic-family aliases.

`ccoa` also sets friendly `_NAME` and `_DESCRIPTION` environment variables so
the `/model` picker shows `Fable via OpenRouter`, `Opus via OpenRouter`,
`Sonnet via OpenRouter`, and `Haiku via OpenRouter`. The status line in
`~/.claude/settings.json` maps the raw OpenRouter model IDs to those same names.

### Single-Model Wrappers

`ccoki`, `ccods`, and `ccog` set:

```bash
ANTHROPIC_MODEL="<selected-openrouter-model>[1m]"
ANTHROPIC_DEFAULT_OPUS_MODEL="<selected-openrouter-model>[1m]"
ANTHROPIC_DEFAULT_SONNET_MODEL="<selected-openrouter-model>[1m]"
ANTHROPIC_DEFAULT_HAIKU_MODEL="<selected-openrouter-model>[1m]"
CLAUDE_CODE_SUBAGENT_MODEL="<selected-openrouter-model>[1m]"
CLAUDE_CODE_AUTO_COMPACT_WINDOW="<real-model-context-window>"
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
```

The `[1m]` suffix is a Claude Code CLI context-accounting workaround for these
custom models. It should be present in every model variable for the single-model
wrappers. The real provider model slug remains the same because Claude Code
strips the suffix before sending the request. See
`docs/claude-code-custom-model-context.md`.

`ccoki` and `ccog` also set:

```bash
CLAUDE_CODE_EXTRA_BODY='{"provider":{"sort":"throughput","allow_fallbacks":true}}'
```

This tells OpenRouter to prioritize the provider endpoint with the highest
current throughput and fall back if that endpoint is unavailable.

`ccods` instead sets:

```bash
CLAUDE_CODE_EXTRA_BODY='{"provider":{"sort":"price","allow_fallbacks":true}}'
```

This tells OpenRouter to prioritize the cheapest provider endpoint for DeepSeek
V4 Pro and fall back if that endpoint is unavailable.

## Verification

Inside Claude Code, run:

```text
/status
```

Expected values:

- Auth token: `ANTHROPIC_AUTH_TOKEN`
- Anthropic base URL: `https://openrouter.ai/api`

OpenRouter usage should also appear in the OpenRouter activity dashboard.

## Notes

- Use `https://openrouter.ai/api`, not `https://openrouter.ai/api/v1`. The `/api/v1` endpoint is for OpenAI-compatible clients.
- Claude Code is optimized for Anthropic models. Non-Anthropic OpenRouter models can work, but tool use, thinking blocks, and long agent loops may vary by model/provider.
- Context windows were verified against OpenRouter model metadata on 2026-06-11.
