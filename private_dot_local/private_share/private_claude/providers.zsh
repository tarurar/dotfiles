# Claude Code — Provider Configuration
# Shortcuts for running Claude Code through custom Anthropic-compatible providers.
# Assumes provider API keys are already exported (e.g., from local_env).

_cco_openrouter_model() {
  local model="$1"
  local compact_window="$2"
  local extra_body="$3"
  shift 3

  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    print -u2 "OPENROUTER_API_KEY is not set"
    return 1
  fi

  local -a claude_env=(
    "ANTHROPIC_BASE_URL=https://openrouter.ai/api"
    "ANTHROPIC_AUTH_TOKEN=$OPENROUTER_API_KEY"
    "ANTHROPIC_API_KEY="
    "ANTHROPIC_DEFAULT_OPUS_MODEL=$model"
    "ANTHROPIC_DEFAULT_SONNET_MODEL=$model"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL=$model"
    "ANTHROPIC_MODEL=$model"
    "CLAUDE_CODE_SUBAGENT_MODEL=$model"
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW=$compact_window"
    "CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=90"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1"
  )

  if [[ -n "$extra_body" ]]; then
    claude_env+=("CLAUDE_CODE_EXTRA_BODY=$extra_body")
  fi

  env "${claude_env[@]}" claude "$@"
}

ccoa() {
  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    print -u2 "OPENROUTER_API_KEY is not set"
    return 1
  fi

  local -a claude_env=(
    "ANTHROPIC_BASE_URL=https://openrouter.ai/api"
    "ANTHROPIC_AUTH_TOKEN=$OPENROUTER_API_KEY"
    "ANTHROPIC_API_KEY="
    "ANTHROPIC_DEFAULT_FABLE_MODEL=anthropic/claude-fable-5[1m]"
    "ANTHROPIC_DEFAULT_OPUS_MODEL=anthropic/claude-opus-4.5[1m]"
    "ANTHROPIC_DEFAULT_SONNET_MODEL=anthropic/claude-sonnet-4.6[1m]"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL=anthropic/claude-haiku-4.5"
    "ANTHROPIC_DEFAULT_FABLE_MODEL_NAME=Fable via OpenRouter"
    "ANTHROPIC_DEFAULT_OPUS_MODEL_NAME=Opus via OpenRouter"
    "ANTHROPIC_DEFAULT_SONNET_MODEL_NAME=Sonnet via OpenRouter"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME=Haiku via OpenRouter"
    "ANTHROPIC_DEFAULT_FABLE_MODEL_DESCRIPTION=Claude Fable 5 through Anthropic 1P"
    "ANTHROPIC_DEFAULT_OPUS_MODEL_DESCRIPTION=Claude Opus 4.5 through Anthropic 1P"
    "ANTHROPIC_DEFAULT_SONNET_MODEL_DESCRIPTION=Claude Sonnet 4.6 through Anthropic 1P"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL_DESCRIPTION=Claude Haiku 4.5 through Anthropic 1P"
    "ANTHROPIC_MODEL=sonnet"
    "CLAUDE_CODE_SUBAGENT_MODEL=anthropic/claude-sonnet-4.6[1m]"
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    "CLAUDE_CODE_SKIP_FAST_MODE_ORG_CHECK=1"
    'CLAUDE_CODE_EXTRA_BODY={"provider":{"order":["anthropic"],"allow_fallbacks":true}}'
  )

  env "${claude_env[@]}" claude "$@"
}

ccoki() {
  _cco_openrouter_model \
    "moonshotai/kimi-k2.6[1m]" \
    "262144" \
    '{"provider":{"sort":"throughput","allow_fallbacks":true}}' \
    "$@"
}

ccods() {
  _cco_openrouter_model \
    "deepseek/deepseek-v4-pro[1m]" \
    "1048576" \
    '{"provider":{"sort":"price","allow_fallbacks":true}}' \
    "$@"
}

ccog() {
  _cco_openrouter_model \
    "z-ai/glm-5.2[1m]" \
    "1048576" \
    '{"provider":{"sort":"throughput","allow_fallbacks":true}}' \
    "$@"
}

ccks() {
  local -a claude_env=(
    "ANTHROPIC_BASE_URL=https://api.kimi.com/coding/"
    "ANTHROPIC_AUTH_TOKEN=$KIMI_API_KEY"
    "ANTHROPIC_DEFAULT_OPUS_MODEL=kimi-for-coding"
    "ANTHROPIC_DEFAULT_SONNET_MODEL=kimi-for-coding"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL=kimi-for-coding"
    "ANTHROPIC_MODEL=kimi-for-coding"
    "CLAUDE_CODE_SUBAGENT_MODEL=kimi-for-coding"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1"
  )

  env "${claude_env[@]}" claude "$@"
}

ccz() {
  if [[ -z "${ZAI_API_KEY:-}" ]]; then
    print -u2 "ZAI_API_KEY is not set"
    return 1
  fi

  local -a claude_env=(
    "ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic"
    "ANTHROPIC_AUTH_TOKEN=$ZAI_API_KEY"
    "ANTHROPIC_API_KEY="
    "ANTHROPIC_DEFAULT_OPUS_MODEL=glm-5.2[1m]"
    "ANTHROPIC_DEFAULT_SONNET_MODEL=glm-5.2[1m]"
    "ANTHROPIC_DEFAULT_HAIKU_MODEL=glm-4.5-air"
    "ANTHROPIC_MODEL=sonnet"
    "CLAUDE_CODE_SUBAGENT_MODEL=glm-5.2[1m]"
    "CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000"
    "API_TIMEOUT_MS=3000000"
    "CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1"
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1"
  )

  env "${claude_env[@]}" claude "$@"
}
