#!/usr/bin/env bash
# SessionStart hook: terminates the Claude Code session after CLAUDE_IDLE_LIMIT seconds
# (default 12h) without transcript changes. Checks every CLAUDE_IDLE_CHECK seconds.

IDLE_LIMIT=${CLAUDE_IDLE_LIMIT:-43200}
CHECK_INTERVAL=${CLAUDE_IDLE_CHECK:-600}

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1"; }

if [[ "$1" != "--watch" ]]; then
  transcript=$(jq -r '.transcript_path // empty')
  [[ -z "$transcript" ]] && exit 0

  # The hook runs in a shell spawned by the session, so the first non-shell
  # ancestor is the session. Matching the name "claude" instead fails: background
  # and Remote Control sessions are named after the version (e.g. 2.1.309), and the
  # first "claude" above them is the daemon or server that hosts every session.
  pid=$PPID
  while [[ "$pid" -gt 1 ]]; do
    case "$(basename -- "$(ps -o comm= -p "$pid")")" in
      sh | bash | dash | zsh | -sh | -bash | -zsh) ;;
      *) break ;;
    esac
    pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
  done
  [[ -z "$pid" || "$pid" -le 1 ]] && exit 0

  # Detach fully: the hook must not wait for the watcher's stdout.
  # macOS has no setsid; nohup keeps the watcher alive when the hook shell exits.
  if command -v setsid >/dev/null; then
    setsid "$0" --watch "$pid" "$transcript" </dev/null >/dev/null 2>&1 &
  else
    nohup "$0" --watch "$pid" "$transcript" </dev/null >/dev/null 2>&1 &
  fi
  exit 0
fi

pid=$2
transcript=$3

while kill -0 "$pid" 2>/dev/null; do
  sleep "$CHECK_INTERVAL"
  kill -0 "$pid" 2>/dev/null || exit 0
  # The transcript may not exist until the first message is written.
  [[ -f "$transcript" ]] || continue
  idle=$(( $(date +%s) - $(mtime "$transcript") ))
  if (( idle >= IDLE_LIMIT )); then
    kill -TERM "$pid"
    exit 0
  fi
done
