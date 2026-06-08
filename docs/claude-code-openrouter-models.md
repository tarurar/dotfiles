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

| Function | Provider | Model |
| --- | --- | --- |
| `ccoki` | OpenRouter | `moonshotai/kimi-k2.6` |
| `ccods` | OpenRouter | `deepseek/deepseek-v4-pro` |
| `ccog` | OpenRouter | `z-ai/glm-5.1` |

## Usage

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
ccog --permission-mode plan
ccods -p "summarize this repo"
```

## Runtime Environment

Each OpenRouter wrapper sets:

```bash
ANTHROPIC_BASE_URL="https://openrouter.ai/api"
ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
ANTHROPIC_API_KEY=""
ANTHROPIC_MODEL="<selected-openrouter-model>"
ANTHROPIC_DEFAULT_OPUS_MODEL="<selected-openrouter-model>"
ANTHROPIC_DEFAULT_SONNET_MODEL="<selected-openrouter-model>"
ANTHROPIC_DEFAULT_HAIKU_MODEL="<selected-openrouter-model>"
CLAUDE_CODE_SUBAGENT_MODEL="<selected-openrouter-model>"
```

`ANTHROPIC_API_KEY` is explicitly empty to avoid Claude Code falling back to Anthropic authentication.

Each OpenRouter wrapper also sets:

```bash
CLAUDE_CODE_EXTRA_BODY='{"provider":{"sort":"throughput","allow_fallbacks":true}}'
```

This tells OpenRouter to prioritize the provider endpoint with the highest
current throughput and fall back if that endpoint is unavailable.

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
- The model slugs above were verified against OpenRouter model pages on 2026-06-07.
