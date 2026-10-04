#!/usr/bin/env bash
# PreToolUse hook for Read: blocks a whole-file read of a large text file and points the
# model at the bulk-reader agent. Ranged reads (offset or limit) always pass, because edits
# need exact lines and bulk-reader itself reads in ranges.
# Threshold: BULK_READ_MIN_LINES, default 350.

input=$(cat)
min=${BULK_READ_MIN_LINES:-350}

read -r path offset limit < <(jq -r '[.tool_input.file_path // "", .tool_input.offset // "", .tool_input.limit // ""] | map(tostring) | map(if . == "" then "-" else . end) | join(" ")' <<<"$input")

[[ "$offset" != "-" || "$limit" != "-" ]] && exit 0
[[ -f "$path" ]] || exit 0
# Images, PDFs and notebooks are not line-based text.
case "$(tr '[:upper:]' '[:lower:]' <<<"$path")" in
  *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.pdf|*.ipynb) exit 0 ;;
esac
grep -Iq . "$path" 2>/dev/null || exit 0

lines=$(wc -l <"$path" | tr -d ' ')
(( lines < min )) && exit 0

reason="$path has $lines lines (limit $min). Delegate to the avonae-agents:bulk-reader agent with a specific question, or read only the range you need with offset and limit."
jq -n --arg r "$reason" '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $r}}'
