# Baseten Claude Code Proxy

## Purpose

`ccbki` and `ccbg` run Claude Code against Baseten-hosted Anthropic-compatible models:

- `ccbki`: `moonshotai/Kimi-K2.6`
- `ccbg`: `zai-org/GLM-5.1`

Claude Code currently needs a local compatibility proxy for these Baseten calls. The proxy injects the `Authorization` header and rewrites `system` role messages from `messages[]` to the top-level Anthropic `system` field.

## Managed Files

All files are managed from the chezmoi source repo:

- `~/.local/bin/baseten-anthropic-fix.py`
  - Source: `private_dot_local/bin/executable_baseten-anthropic-fix.py`
- `~/.config/systemd/user/baseten-anthropic-proxy.service`
  - Source: `private_dot_config/systemd/user/baseten-anthropic-proxy.service`
- `~/.local/share/claude/providers.zsh`
  - Source: `private_dot_local/private_share/private_claude/providers.zsh`
- This document
  - Source: `docs/baseten-claude-code-proxy.md`

Apply changes with:

```bash
chezmoi apply ~/.local/bin/baseten-anthropic-fix.py
chezmoi apply ~/.config/systemd/user/baseten-anthropic-proxy.service
chezmoi apply ~/.local/share/claude/providers.zsh
systemctl --user daemon-reload
```

## Runtime Model

The proxy is a user-level systemd service. It is not enabled at login.

When `ccbki` or `ccbg` runs, the wrapper:

1. Requires `BASETEN_API_KEY` to be present in the shell.
2. Imports `BASETEN_API_KEY` and `PATH` into the systemd user manager.
3. Starts `baseten-anthropic-proxy.service` if the service is not active.
4. Waits for `http://127.0.0.1:4000/health`.
5. Launches `claude` with the selected model variables.

The proxy remains running after Claude Code exits. Stop it manually when it is no longer needed.

The wrappers require the systemd service to own the proxy process. If an old manually started proxy is already bound to port 4000, stop it before using `ccbki` or `ccbg`.

## Commands

Start Claude Code with Kimi K2.6:

```bash
ccbki
```

Start Claude Code with GLM-5.1:

```bash
ccbg
```

Stop the proxy:

```bash
ccb-proxy-stop
```

Check proxy status and health:

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

## Notes

- `BASETEN_API_KEY` is expected to come from `~/.local_env`, which is sourced by `.zshrc`.
- `PATH` is imported so the service uses the same Python toolchain as the shell, including the Python that provides `aiohttp`.
- If `BASETEN_API_KEY` changes, run `ccb-proxy-stop` before the next `ccbki` or `ccbg` invocation so the service restarts with the new value.
- The service intentionally has no `[Install]` section. It should be started on demand, not enabled at login.
