#!/usr/bin/env bash
# PreToolUse hook: auto-bump plugin patch version before git commit.
# Only triggers when Bash command is a git commit.
# Scans staged + unstaged changes for plugin files, and bumps version
# for each affected plugin whose plugin.json hasn't already been bumped.
# Uses hookSpecificOutput format for PreToolUse decision control.

set -eo pipefail

INPUT=$(cat)

# Extract the bash command
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{}'
  exit 0
fi

# Only trigger on git commit commands
if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|)git\s+commit\b'; then
  echo '{}'
  exit 0
fi

# Collect modified plugin directories
PLUGIN_DIRS=""
for FILE in $(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null); do
  if [[ "$FILE" == plugins/* ]]; then
    PLUGIN_NAME=$(echo "$FILE" | cut -d/ -f1-2)
    PLUGIN_DIRS="$PLUGIN_DIRS $PLUGIN_NAME"
  fi
done

# Deduplicate
PLUGIN_DIRS=$(echo "$PLUGIN_DIRS" | tr ' ' '\n' | sort -u | grep -v '^$')

if [ -z "$PLUGIN_DIRS" ]; then
  echo '{}'
  exit 0
fi

BUMPED=""

for PLUGIN_DIR in $PLUGIN_DIRS; do
  PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"

  if [ ! -f "$PLUGIN_JSON" ]; then
    continue
  fi

  # Skip if plugin.json already has uncommitted changes (already bumped)
  if git diff --name-only 2>/dev/null | grep -qF "$PLUGIN_JSON"; then
    continue
  fi
  if git diff --name-only --cached 2>/dev/null | grep -qF "$PLUGIN_JSON"; then
    continue
  fi

  # Bump patch version
  CURRENT_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
  MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
  MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
  PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
  NEW_VERSION="$MAJOR.$MINOR.$((PATCH + 1))"

  jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"

  if [ -n "$BUMPED" ]; then
    BUMPED="$BUMPED; "
  fi
  BUMPED="${BUMPED}${PLUGIN_DIR}: ${CURRENT_VERSION} -> ${NEW_VERSION}"
done

if [ -z "$BUMPED" ]; then
  echo '{}'
  exit 0
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Auto-bumped plugin versions: ${BUMPED}. Please stage the updated plugin.json file(s) and re-run the commit."
  }
}
EOF
