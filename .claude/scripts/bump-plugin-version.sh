#!/usr/bin/env bash
# PreToolUse hook: auto-bump plugin version before git commit.
# Only triggers when Bash command is a git commit.
#
# Determines bump type from TWO signals (takes the higher one):
#   Signal 1 — Conventional Commit message:
#     BREAKING CHANGE / type!: → MAJOR | feat: → MINOR | others → PATCH
#   Signal 2 — Actual file diff per plugin:
#     Deleted skill/agent/command → MAJOR | New skill/agent/command → MINOR | others → PATCH

set -eo pipefail

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [ -z "$COMMAND" ]; then
  echo '{}'
  exit 0
fi

if ! echo "$COMMAND" | grep -qE '(^|\s|&&|\|)git\s+commit\b'; then
  echo '{}'
  exit 0
fi

# --- Utility: numeric rank for comparison ---
bump_rank() {
  case "$1" in
    major) echo 3 ;;
    minor) echo 2 ;;
    *)     echo 1 ;;
  esac
}

rank_to_name() {
  case "$1" in
    3) echo "major" ;;
    2) echo "minor" ;;
    *) echo "patch" ;;
  esac
}

# --- Signal 1: Conventional Commit message ---
bump_from_message() {
  local cmd="$1"

  if echo "$cmd" | grep -qE 'BREAKING[[:space:]]+CHANGE'; then
    echo "major"; return
  fi

  if echo "$cmd" | grep -qE '(feat|fix|chore|docs|style|refactor|perf|test|build|ci)!(\([^)]*\))?[[:space:]]*:'; then
    echo "major"; return
  fi

  if echo "$cmd" | grep -qE 'feat(\([^)]*\))?[[:space:]]*:'; then
    echo "minor"; return
  fi

  echo "patch"
}

# --- Signal 2: Diff analysis for a single plugin directory ---
bump_from_diff() {
  local plugin_dir="$1"
  local level="patch"

  # Deleted files (staged or vs HEAD)
  local deleted
  deleted=$(
    { git diff --diff-filter=D --name-only HEAD 2>/dev/null
      git diff --diff-filter=D --name-only --cached 2>/dev/null
    } | sort -u | grep "^${plugin_dir}/" || true
  )

  # MAJOR: a skill SKILL.md, agent .md, or command .md was deleted
  if echo "$deleted" | grep -qE "/${plugin_dir}/skills/[^/]+/SKILL\.md$"; then
    echo "major"; return
  fi
  if echo "$deleted" | grep -qE "/${plugin_dir}/agents/[^/]+\.md$"; then
    echo "major"; return
  fi
  if echo "$deleted" | grep -qE "/${plugin_dir}/commands/[^/]+\.md$"; then
    echo "major"; return
  fi

  # New files (staged adds + untracked)
  local added
  added=$(
    { git diff --diff-filter=A --name-only --cached 2>/dev/null
      git ls-files --others --exclude-standard 2>/dev/null
    } | sort -u | grep "^${plugin_dir}/" || true
  )

  # MINOR: a new skill directory, agent, or command was added
  if echo "$added" | grep -qE "^${plugin_dir}/skills/[^/]+/SKILL\.md$"; then
    echo "minor"; return
  fi
  if echo "$added" | grep -qE "^${plugin_dir}/agents/[^/]+\.md$"; then
    echo "minor"; return
  fi
  if echo "$added" | grep -qE "^${plugin_dir}/commands/[^/]+\.md$"; then
    echo "minor"; return
  fi

  echo "patch"
}

# --- Version arithmetic ---
bump_version() {
  local current="$1" type="$2"
  local major minor patch
  major=$(echo "$current" | cut -d. -f1)
  minor=$(echo "$current" | cut -d. -f2)
  patch=$(echo "$current" | cut -d. -f3)

  case "$type" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "$major.$((minor + 1)).0" ;;
    *)     echo "$major.$minor.$((patch + 1))" ;;
  esac
}

# --- Main logic ---

MSG_BUMP=$(bump_from_message "$COMMAND")

# Collect modified plugin directories
PLUGIN_DIRS=""
for FILE in $(git diff --name-only HEAD 2>/dev/null; git diff --name-only --cached 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null); do
  if [[ "$FILE" == plugins/* ]]; then
    PLUGIN_NAME=$(echo "$FILE" | cut -d/ -f1-2)
    PLUGIN_DIRS="$PLUGIN_DIRS $PLUGIN_NAME"
  fi
done

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

  if git diff --name-only 2>/dev/null | grep -qF "$PLUGIN_JSON"; then
    continue
  fi
  if git diff --name-only --cached 2>/dev/null | grep -qF "$PLUGIN_JSON"; then
    continue
  fi

  # Per-plugin diff signal
  DIFF_BUMP=$(bump_from_diff "$PLUGIN_DIR")

  # Take the higher of message vs diff
  MSG_RANK=$(bump_rank "$MSG_BUMP")
  DIFF_RANK=$(bump_rank "$DIFF_BUMP")
  if [ "$MSG_RANK" -ge "$DIFF_RANK" ]; then
    FINAL_BUMP="$MSG_BUMP"
  else
    FINAL_BUMP="$DIFF_BUMP"
  fi

  CURRENT_VERSION=$(jq -r '.version' "$PLUGIN_JSON")
  NEW_VERSION=$(bump_version "$CURRENT_VERSION" "$FINAL_BUMP")

  jq --arg v "$NEW_VERSION" '.version = $v' "$PLUGIN_JSON" > "$PLUGIN_JSON.tmp" && mv "$PLUGIN_JSON.tmp" "$PLUGIN_JSON"

  if [ -n "$BUMPED" ]; then
    BUMPED="$BUMPED; "
  fi
  BUMPED="${BUMPED}${PLUGIN_DIR}: ${CURRENT_VERSION} -> ${NEW_VERSION} (${FINAL_BUMP}, msg=${MSG_BUMP} diff=${DIFF_BUMP})"
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
