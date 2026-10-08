#!/usr/bin/env bash
# Reports how much of the context window the current session uses.
# Usage: context-tokens.sh statusline | hook   (Claude Code JSON on stdin)
# Context size = input + cache tokens of the last main-thread assistant message.

THRESHOLD=150000

command -v jq >/dev/null || exit 0

# macOS has no tac; BSD tail -r does the same.
if command -v tac >/dev/null; then reverse() { tac "$1"; }; else reverse() { tail -r "$1"; }; fi

input=$(cat)
transcript=$(jq -r '.transcript_path // empty' <<<"$input")

tokens=0
if [[ -n "$transcript" && -f "$transcript" ]]; then
  tokens=$(reverse "$transcript" | jq -r '
    select(.type == "assistant" and .message.usage != null and (.isSidechain | not))
    | .message.usage
    | (.input_tokens // 0) + (.cache_read_input_tokens // 0) + (.cache_creation_input_tokens // 0)
  ' 2>/dev/null | head -1)
  tokens=${tokens:-0}
fi

k=$((tokens / 1000))
pct=$((tokens * 100 / THRESHOLD))

case "$1" in
  statusline)
    model=$(jq -r '.model.display_name // empty' <<<"$input")
    if ((pct >= 100)); then color='\033[31m'
    elif ((pct >= 75)); then color='\033[33m'
    else color='\033[32m'
    fi
    printf "%s ${color}ctx %dk/%dk (%d%%)\033[0m\n" "$model" "$k" $((THRESHOLD / 1000)) "$pct"
    ;;
  hook)
    if ((tokens >= THRESHOLD)); then
      msg="Контекст ${k}k токенов (порог $((THRESHOLD / 1000))k). Пора начать новую сессию."
      # IDE extensions may not render systemMessage, so the model is also asked to relay it.
      jq -n --arg msg "$msg" '{
        systemMessage: $msg,
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: ("Start your reply with this warning, verbatim, on its own line: \"⚠️ " + $msg + "\"")
        }
      }'
    fi
    ;;
esac
