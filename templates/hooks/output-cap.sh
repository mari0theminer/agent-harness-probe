#!/usr/bin/env bash
# PreToolUse hook (matcher: Bash) — caps the output of known-noisy test/build commands
# BEFORE they run, so multi-thousand-line logs never enter the model context.
# Rewrites the command to pipe through `tail -n N` while preserving the original exit
# code via pipefail. Failure summaries print at the end of most test runners, so the
# tail keeps exactly the part that matters.
#
# Skipped when the command already limits its own output (tail/head/grep/wc/jq) or
# redirects, so deliberate filtering is never double-wrapped.
#
# ADAPT: put THIS project's noisy commands in NOISY, verified against its Makefile /
# package scripts. Do not list commands the project does not have.
#
# NOISY ships as a {{placeholder}} and in that state matches NOTHING — the braces are
# literal to grep -E, so the hook silently caps nothing at all. Replace it before
# wiring the hook, and test with a real command from this project.
set -euo pipefail

NOISY='{{go test|npm test|pytest|cargo test|make (check|test)}}'
KEEP_LINES=250

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$CMD" ] && exit 0

# Only touch the known offenders.
if ! printf '%s' "$CMD" | grep -qE "$NOISY"; then
  exit 0
fi

# Already filtered or redirected — leave it alone.
if printf '%s' "$CMD" | grep -qE '\| *(tail|head|grep|wc|jq)|>[> ]'; then
  exit 0
fi

WRAPPED="set -o pipefail; { $CMD ; } 2>&1 | tail -n $KEEP_LINES"

jq -cn --arg cmd "$WRAPPED" --arg n "$KEEP_LINES" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    permissionDecisionReason: ("auto-capped noisy test output (tail -n " + $n + ")"),
    updatedInput: { command: $cmd }
  }
}'
