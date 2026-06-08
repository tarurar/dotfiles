# Claude Code Baseten Models

## Purpose

`~/.local/share/claude/providers.zsh` defines short shell functions for running Claude Code through Baseten-hosted Anthropic-compatible models.

Baseten mode uses the local compatibility proxy documented in `docs/baseten-claude-code-proxy.md`.

## Required Configuration

Set a Baseten API key in `~/.local_env`:

```bash
export BASETEN_API_KEY="..."
```

Reload the shell:

```bash
source ~/.zshrc
```

## Functions

| Function | Provider | Claude Code model string | Provider model |
| --- | --- | --- | --- |
| `ccbki` | Baseten | `moonshotai/Kimi-K2.6[1m]` | `moonshotai/Kimi-K2.6` |
| `ccbg` | Baseten | `zai-org/GLM-5.1[1m]` | `zai-org/GLM-5.1` |

## Usage

Start Claude Code with Baseten Kimi K2.6:

```bash
ccbki
```

Start Claude Code with Baseten GLM 5.1:

```bash
ccbg
```

Pass normal Claude Code arguments after the function name:

```bash
ccbki --permission-mode plan
ccbg -p "summarize this repo"
```

## Proxy Lifecycle

`ccbki` and `ccbg` start the local Baseten proxy on demand and leave it running after Claude Code exits.

Check proxy status:

```bash
ccb-proxy-status
```

Show recent proxy logs:

```bash
ccb-proxy-logs
```

Follow proxy logs:

```bash
ccb-proxy-logs -f
```

Stop the proxy manually:

```bash
ccb-proxy-stop
```

## Runtime Environment

Each Baseten wrapper sets:

```bash
ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
ANTHROPIC_AUTH_TOKEN="$BASETEN_API_KEY"
ANTHROPIC_MODEL="<selected-baseten-model>[1m]"
ANTHROPIC_DEFAULT_OPUS_MODEL="<selected-baseten-model>[1m]"
ANTHROPIC_DEFAULT_SONNET_MODEL="<selected-baseten-model>[1m]"
ANTHROPIC_DEFAULT_HAIKU_MODEL="<selected-baseten-model>[1m]"
CLAUDE_CODE_SUBAGENT_MODEL="<selected-baseten-model>[1m]"
CLAUDE_CODE_AUTO_COMPACT_WINDOW="<real-model-context-window>"
CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
```

The `[1m]` suffix is a Claude Code CLI context-accounting workaround for custom
models. It should be present in every model variable. The real provider model
slug remains the same because Claude Code strips the suffix before sending the
request. See `docs/claude-code-custom-model-context.md`.

The local proxy forwards requests to `https://inference.baseten.co`, injects the Baseten authorization header, and rewrites Claude Code system messages into the top-level Anthropic `system` field.

## Related Document

See `docs/baseten-claude-code-proxy.md` for proxy deployment, service, and troubleshooting details.
