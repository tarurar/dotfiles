# Claude Code — Provider Configuration
# Usage: ccb [claude-args...]

# Assumes provider API keys are already exported (e.g., from local_env)

_ccb_baseten_proxy_service="baseten-anthropic-proxy.service"
_ccb_baseten_proxy_url="http://127.0.0.1:4000"

_ccb_baseten_proxy_health() {
  command -v curl >/dev/null 2>&1 || return 127
  curl --fail --silent --max-time 1 \
    "$_ccb_baseten_proxy_url/health" >/dev/null
}

_ccb_ensure_baseten_proxy() {
  if [[ -z "${BASETEN_API_KEY:-}" ]]; then
    print -u2 "BASETEN_API_KEY is not set"
    return 1
  fi

  if ! command -v systemctl >/dev/null 2>&1; then
    print -u2 "systemctl is required to manage $_ccb_baseten_proxy_service"
    return 1
  fi

  if ! command -v curl >/dev/null 2>&1; then
    print -u2 "curl is required to health-check $_ccb_baseten_proxy_url"
    return 1
  fi

  systemctl --user import-environment BASETEN_API_KEY PATH || return

  if systemctl --user is-active --quiet "$_ccb_baseten_proxy_service"; then
    if _ccb_baseten_proxy_health; then
      return 0
    fi

    print -u2 "$_ccb_baseten_proxy_service is active but not healthy"
    systemctl --user --no-pager status "$_ccb_baseten_proxy_service"
    return 1
  fi

  systemctl --user start "$_ccb_baseten_proxy_service" || return

  local attempt
  for attempt in {1..20}; do
    if _ccb_baseten_proxy_health; then
      return 0
    fi
    sleep 0.25
  done

  print -u2 "$_ccb_baseten_proxy_service did not become healthy"
  systemctl --user --no-pager status "$_ccb_baseten_proxy_service"
  return 1
}

ccb-proxy-stop() {
  systemctl --user stop "$_ccb_baseten_proxy_service"
}

ccb-proxy-status() {
  systemctl --user --no-pager status "$_ccb_baseten_proxy_service"
  _ccb_baseten_proxy_health \
    && print "health: ok ($_ccb_baseten_proxy_url/health)" \
    || print "health: unavailable ($_ccb_baseten_proxy_url/health)"
}

ccb-proxy-logs() {
  if (( $# == 0 )); then
    journalctl --user -u "$_ccb_baseten_proxy_service" -n 100 --no-pager
  else
    journalctl --user -u "$_ccb_baseten_proxy_service" "$@"
  fi
}

ccbki() {
  _ccb_ensure_baseten_proxy || return

  local ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
  # local ANTHROPIC_BASE_URL="https://inference.baseten.co"
  local ANTHROPIC_AUTH_TOKEN="$BASETEN_API_KEY"
  local ANTHROPIC_DEFAULT_OPUS_MODEL="moonshotai/Kimi-K2.6"
  local ANTHROPIC_DEFAULT_SONNET_MODEL="moonshotai/Kimi-K2.6"
  local ANTHROPIC_DEFAULT_HAIKU_MODEL="moonshotai/Kimi-K2.6"
  local CLAUDE_CODE_SUBAGENT_MODEL="moonshotai/Kimi-K2.6"
  local CLAUDE_CODE_AUTO_COMPACT_WINDOW="262144"
  local CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
  local CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
  local CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
  local CLAUDE_CODE_EXTRA_BODY='{"chat_template_args": {"enable_thinking": true}}'

  # Launch Claude Code with these vars scoped to this invocation only
  ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_DEFAULT_SONNET_MODEL" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
  ANTHROPIC_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
  CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_CODE_SUBAGENT_MODEL" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="$CLAUDE_CODE_AUTO_COMPACT_WINDOW" \
  CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="$CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="$CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" \
  CLAUDE_CODE_EXTRA_BODY="$CLAUDE_CODE_EXTRA_BODY" \
    claude "$@"
}

_cco_openrouter_model() {
  local model="$1"
  local compact_window="$2"
  local extra_body="$3"
  shift 3

  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    print -u2 "OPENROUTER_API_KEY is not set"
    return 1
  fi

  local ANTHROPIC_BASE_URL="https://openrouter.ai/api"
  local ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
  local ANTHROPIC_DEFAULT_OPUS_MODEL="$model"
  local ANTHROPIC_DEFAULT_SONNET_MODEL="$model"
  local ANTHROPIC_DEFAULT_HAIKU_MODEL="$model"
  local CLAUDE_CODE_SUBAGENT_MODEL="$model"
  local CLAUDE_CODE_AUTO_COMPACT_WINDOW="$compact_window"
  local CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
  local CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
  local CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
  local -a claude_env=(
    "ANTHROPIC_BASE_URL=$ANTHROPIC_BASE_URL"
    "ANTHROPIC_AUTH_TOKEN=$ANTHROPIC_AUTH_TOKEN"
    "ANTHROPIC_API_KEY="
    "ANTHROPIC_DEFAULT_OPUS_MODEL=$ANTHROPIC_DEFAULT_OPUS_MODEL"
    "ANTHROPIC_DEFAULT_SONNET_MODEL=$ANTHROPIC_DEFAULT_SONNET_MODEL"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL=$ANTHROPIC_DEFAULT_HAIKU_MODEL"
    "ANTHROPIC_MODEL=$ANTHROPIC_DEFAULT_OPUS_MODEL"
    "CLAUDE_CODE_SUBAGENT_MODEL=$CLAUDE_CODE_SUBAGENT_MODEL"
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW=$CLAUDE_CODE_AUTO_COMPACT_WINDOW"
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=$CLAUDE_AUTOCOMPACT_PCT_OVERRIDE"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=$CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS"
  )

  if [[ -n "$extra_body" ]]; then
    claude_env+=("CLAUDE_CODE_EXTRA_BODY=$extra_body")
  fi

  env "${claude_env[@]}" claude "$@"
}

ccoki() {
  _cco_openrouter_model \
    "moonshotai/kimi-k2.6" \
    "262144" \
    '{"provider":{"sort":"throughput","allow_fallbacks":true}}' \
    "$@"
}

ccods() {
  _cco_openrouter_model \
    "deepseek/deepseek-v4-pro" \
    "1048576" \
    '{"provider":{"sort":"price","allow_fallbacks":true}}' \
    "$@"
}

ccog() {
  _cco_openrouter_model \
    "z-ai/glm-5.1" \
    "202800" \
    '{"provider":{"sort":"throughput","allow_fallbacks":true}}' \
    "$@"
}

ccbg() {
  _ccb_ensure_baseten_proxy || return

  local ANTHROPIC_BASE_URL="http://127.0.0.1:4000"
  # local ANTHROPIC_BASE_URL="https://inference.baseten.co"
  local ANTHROPIC_AUTH_TOKEN="$BASETEN_API_KEY"
  local ANTHROPIC_DEFAULT_OPUS_MODEL="zai-org/GLM-5.1"
  local ANTHROPIC_DEFAULT_SONNET_MODEL="zai-org/GLM-5.1"
  local ANTHROPIC_DEFAULT_HAIKU_MODEL="zai-org/GLM-5.1"
  local CLAUDE_CODE_SUBAGENT_MODEL="zai-org/GLM-5.1"
  local CLAUDE_CODE_AUTO_COMPACT_WINDOW="202800"
  local CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
  local CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
  local CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
  local CLAUDE_CODE_EXTRA_BODY='{"chat_template_args": {"enable_thinking": true}, "thinking": {"type": "enabled", "clear_thinking": false}}'

  ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_DEFAULT_SONNET_MODEL" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
  ANTHROPIC_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
  CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_CODE_SUBAGENT_MODEL" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="$CLAUDE_CODE_AUTO_COMPACT_WINDOW" \
  CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="$CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
  CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="$CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS" \
  CLAUDE_CODE_EXTRA_BODY="$CLAUDE_CODE_EXTRA_BODY" \
    claude "$@"
}

ccks() {
  local ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
  local ANTHROPIC_AUTH_TOKEN="$KIMI_API_KEY"
  local ANTHROPIC_DEFAULT_OPUS_MODEL="kimi-for-coding"
  local ANTHROPIC_DEFAULT_SONNET_MODEL="kimi-for-coding"
  local ANTHROPIC_DEFAULT_HAIKU_MODEL="kimi-for-coding"
  local CLAUDE_CODE_SUBAGENT_MODEL="kimi-for-coding"
  local CLAUDE_CODE_AUTO_COMPACT_WINDOW="262144"
  local CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="90"
  local CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
  local CLAUDE_CODE_EXTRA_BODY='{"thinking": {"type": "enabled", "keep": "all"}}'

  ANTHROPIC_BASE_URL="$ANTHROPIC_BASE_URL" \
  ANTHROPIC_AUTH_TOKEN="$ANTHROPIC_AUTH_TOKEN" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_DEFAULT_OPUS_MODEL" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_DEFAULT_SONNET_MODEL" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_DEFAULT_HAIKU_MODEL" \
  CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_CODE_SUBAGENT_MODEL" \
  CLAUDE_CODE_AUTO_COMPACT_WINDOW="$CLAUDE_CODE_AUTO_COMPACT_WINDOW" \
  CLAUDE_AUTOCOMPACT_PCT_OVERRIDE="$CLAUDE_AUTOCOMPACT_PCT_OVERRIDE" \
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="$CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC" \
  CLAUDE_CODE_EXTRA_BODY="$CLAUDE_CODE_EXTRA_BODY" \
    claude "$@"
}
