#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write) — deterministically formats the file that was
# just edited, so lint/format round-trips never reach the model.
# Silent on success; never blocks (always exits 0).
#
# ADAPT: one case branch per file type THIS project formats, calling the formatter the
# project actually installs. Guard every call so a cold clone or CI box degrades to a
# no-op instead of erroring.
set -uo pipefail

INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE" ] || [ ! -f "$FILE" ] && exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$FILE" in
  # *.go)
  #   gofmt -w "$FILE" 2>/dev/null || true
  #   command -v goimports >/dev/null 2>&1 && goimports -w "$FILE" 2>/dev/null || true
  #   ;;
  # *.ts|*.tsx|*.js|*.vue)
  #   [ -x "$ROOT/node_modules/.bin/prettier" ] && \
  #     "$ROOT/node_modules/.bin/prettier" --write "$FILE" >/dev/null 2>&1 || true
  #   ;;
  # *.py)
  #   command -v ruff >/dev/null 2>&1 && ruff format "$FILE" >/dev/null 2>&1 || true
  #   ;;
  *) ;;
esac

exit 0
