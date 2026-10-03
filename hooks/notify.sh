#!/usr/bin/env bash
# Desktop notification for Claude Code hooks, titled with the session name.
# Stays silent while subagents of the session still run: the work is not finished.
# Usage: notify.sh agent-start|agent-stop|task-note|stop|notification   (hook JSON on stdin)

input=$(cat)
field() { jq -r ".$1 // empty" <<<"$input"; }
# IDs become file names; the task-note ID comes from prompt text, so drop anything like "../".
safe_id() { tr -cd 'A-Za-z0-9_-' <<<"$1"; }

session_id=$(safe_id "$(field session_id)")
agent_id=$(safe_id "$(field agent_id)")
root="${XDG_RUNTIME_DIR:-/tmp}/claude-notify"
state="$root/${session_id:-unknown}"
log() { [[ -n "$CLAUDE_NOTIFY_DEBUG" ]] && echo "$(date +%T) $session_id $*" >>"$root/debug.log"; }
mkdir -p -m 700 "$root"

case "$1" in
  agent-start)
    [[ -n "$agent_id" ]] && mkdir -p "$state" && touch "$state/$agent_id"
    log "agent-start $agent_id"
    exit 0
    ;;
  agent-stop)
    [[ -n "$agent_id" ]] && rm -f "$state/$agent_id"
    log "agent-stop $agent_id"
    exit 0
    ;;
  task-note)
    # SubagentStop also fires when an agent pauses to wait for its own background work.
    # The session then gets a task notification saying so; put the agent back on the list.
    prompt=$(field prompt)
    if [[ "$prompt" == *"<task-notification>"* && "$prompt" == *"background work of its own still running"* ]]; then
      id=$(safe_id "$(sed -n 's:.*<task-id>\([^<]*\)</task-id>.*:\1:p' <<<"$prompt" | head -1)")
      [[ -n "$id" ]] && mkdir -p "$state" && touch "$state/$id"
      log "task-note waiting $id"
    fi
    exit 0
    ;;
esac

# Entries older than 6h are leftovers from agents that never reported SubagentStop.
find "$state" -type f -mmin +360 -delete 2>/dev/null
running=$(ls -A "$state" 2>/dev/null)

if [[ "$1" == "notification" ]]; then
  type=$(field notification_type)
  if [[ "$type" == "agent_completed" || ("$type" == "idle_prompt" && -n "$running") ]]; then
    log "skip notification $type"
    exit 0
  fi
  body=$(field message)
  body=${body:-Нужно твоё внимание}
elif [[ -n "$running" ]]; then
  log "skip stop, running: $(echo $running)"
  exit 0
else
  body='Готово, жду ответа'
fi

# A /rename title wins over the auto-generated one; the last entry is the current one.
transcript=$(field transcript_path)
name=""
if [[ -f "$transcript" ]]; then
  name=$(grep -h '"type":"custom-title"' "$transcript" | tail -1 | jq -r '.customTitle // empty')
  [[ -z "$name" ]] && name=$(grep -h '"type":"ai-title"' "$transcript" | tail -1 | jq -r '.aiTitle // empty')
fi
cwd=$(field cwd)
[[ -z "$name" ]] && name=$(basename "${cwd:-Claude Code}")

log "notify $1: $body"
notify-send -a 'Claude Code' "Claude: $name" "$body"
