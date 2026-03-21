#!/usr/bin/env bash
# spec-frontmatter.sh — 讀取、比較 spec story 的 frontmatter
#
# Usage:
#   spec-frontmatter.sh read <file>              # 讀取單一檔案 frontmatter (JSON)
#   spec-frontmatter.sh list <dir>               # 列出目錄下所有 story 的 frontmatter
#   spec-frontmatter.sh stale <dir>              # 列出需要同步的 stories (無 tracker_id 或 synced_at 較舊)
#   spec-frontmatter.sh unsynced <dir>           # 列出尚未同步到 tracker 的 stories
#   spec-frontmatter.sh compare <file> <updated_at>  # 比較本地 synced_at 與 tracker updated_at
#   spec-frontmatter.sh update <file> <field> <value> # 更新單一 frontmatter 欄位
#   spec-frontmatter.sh init <dir>               # 批次檢查目錄下所有 stories 的同步狀態摘要

set -euo pipefail

# --- 解析單一檔案 frontmatter 為 key=value ---
parse_frontmatter() {
  local file="$1"
  if [[ ! -f "$file" ]]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  # 檢查是否以 --- 開頭
  local first_line
  first_line=$(head -1 "$file")
  if [[ "$first_line" != "---" ]]; then
    echo "ERROR: No frontmatter found in $file" >&2
    return 1
  fi

  # 擷取 --- 之間的 YAML
  awk 'BEGIN{found=0} /^---$/{found++; next} found==1{print} found>=2{exit}' "$file"
}

# --- 讀取單一欄位 ---
get_field() {
  local file="$1"
  local field="$2"
  parse_frontmatter "$file" 2>/dev/null | grep "^${field}:" | sed "s/^${field}: *//" | sed 's/^"//' | sed 's/"$//'
}

# --- 命令: read ---
cmd_read() {
  local file="$1"
  local story_id title type priority tracker_type tracker_id synced_at

  story_id=$(get_field "$file" "story_id")
  title=$(get_field "$file" "title")
  type=$(get_field "$file" "type")
  priority=$(get_field "$file" "priority")
  tracker_type=$(get_field "$file" "tracker_type")
  tracker_id=$(get_field "$file" "tracker_id")
  synced_at=$(get_field "$file" "synced_at")

  cat <<EOF
{
  "file": "$file",
  "story_id": "${story_id:-null}",
  "title": "${title:-null}",
  "type": "${type:-null}",
  "priority": "${priority:-null}",
  "tracker_type": "${tracker_type:-null}",
  "tracker_id": "${tracker_id:-null}",
  "synced_at": "${synced_at:-null}"
}
EOF
}

# --- 命令: list ---
cmd_list() {
  local dir="$1"
  local first=true

  echo "["
  for f in "$dir"/story-*.md "$dir"/spike-*.md; do
    [[ -f "$f" ]] || continue
    if [[ "$first" == true ]]; then
      first=false
    else
      echo ","
    fi
    cmd_read "$f"
  done
  echo "]"
}

# --- 命令: stale ---
cmd_stale() {
  local dir="$1"
  local count=0

  printf "%-12s %-10s %-40s %s\n" "STORY_ID" "TRACKER" "TITLE" "STATUS"
  printf "%-12s %-10s %-40s %s\n" "--------" "-------" "-----" "------"

  for f in "$dir"/story-*.md "$dir"/spike-*.md; do
    [[ -f "$f" ]] || continue

    local story_id tracker_id synced_at title
    story_id=$(get_field "$f" "story_id")
    tracker_id=$(get_field "$f" "tracker_id")
    synced_at=$(get_field "$f" "synced_at")
    title=$(get_field "$f" "title")

    if [[ -z "$tracker_id" || "$tracker_id" == "＿＿" ]]; then
      printf "%-12s %-10s %-40s %s\n" "Story $story_id" "-" "$title" "NOT_SYNCED"
      count=$((count + 1))
    elif [[ -z "$synced_at" || "$synced_at" == "＿＿" ]]; then
      printf "%-12s %-10s %-40s %s\n" "Story $story_id" "$tracker_id" "$title" "NO_TIMESTAMP"
      count=$((count + 1))
    fi
  done

  echo ""
  echo "Total: $count stories need attention"
}

# --- 命令: unsynced ---
cmd_unsynced() {
  local dir="$1"

  for f in "$dir"/story-*.md "$dir"/spike-*.md; do
    [[ -f "$f" ]] || continue

    local tracker_id
    tracker_id=$(get_field "$f" "tracker_id")

    if [[ -z "$tracker_id" || "$tracker_id" == "＿＿" ]]; then
      echo "$f"
    fi
  done
}

# --- 命令: compare ---
cmd_compare() {
  local file="$1"
  local tracker_updated_at="$2"

  local synced_at
  synced_at=$(get_field "$file" "synced_at")
  local tracker_id
  tracker_id=$(get_field "$file" "tracker_id")
  local story_id
  story_id=$(get_field "$file" "story_id")

  if [[ -z "$synced_at" || "$synced_at" == "＿＿" ]]; then
    echo "NEEDS_PULL  Story $story_id ($tracker_id): no local synced_at"
    return 0
  fi

  # 將 ISO-8601 轉為 epoch 秒做比較
  local local_epoch tracker_epoch

  if command -v gdate &>/dev/null; then
    # macOS with coreutils
    local_epoch=$(gdate -d "$synced_at" +%s 2>/dev/null || echo 0)
    tracker_epoch=$(gdate -d "$tracker_updated_at" +%s 2>/dev/null || echo 0)
  elif date --version &>/dev/null 2>&1; then
    # GNU date (Linux)
    local_epoch=$(date -d "$synced_at" +%s 2>/dev/null || echo 0)
    tracker_epoch=$(date -d "$tracker_updated_at" +%s 2>/dev/null || echo 0)
  else
    # macOS built-in date (limited ISO support)
    # Fallback: string comparison
    if [[ "$synced_at" < "$tracker_updated_at" ]]; then
      echo "NEEDS_PULL  Story $story_id ($tracker_id): tracker is newer ($tracker_updated_at > $synced_at)"
    elif [[ "$synced_at" > "$tracker_updated_at" ]]; then
      echo "UP_TO_DATE  Story $story_id ($tracker_id): local is newer or equal"
    else
      echo "UP_TO_DATE  Story $story_id ($tracker_id): in sync"
    fi
    return 0
  fi

  if [[ "$tracker_epoch" -gt "$local_epoch" ]]; then
    echo "NEEDS_PULL  Story $story_id ($tracker_id): tracker is newer ($tracker_updated_at > $synced_at)"
  else
    echo "UP_TO_DATE  Story $story_id ($tracker_id): in sync"
  fi
}

# --- 命令: update ---
cmd_update() {
  local file="$1"
  local field="$2"
  local value="$3"

  if [[ ! -f "$file" ]]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  local first_line
  first_line=$(head -1 "$file")
  if [[ "$first_line" != "---" ]]; then
    echo "ERROR: No frontmatter found in $file" >&2
    return 1
  fi

  # 檢查欄位是否已存在
  local existing
  existing=$(parse_frontmatter "$file" 2>/dev/null | grep "^${field}:" || true)

  if [[ -n "$existing" ]]; then
    # 欄位已存在 → 原地替換
    # 用 awk 精確替換 frontmatter 區塊內的欄位
    awk -v field="$field" -v value="$value" '
      BEGIN { in_fm=0; replaced=0 }
      /^---$/ { in_fm++; print; next }
      in_fm==1 && !replaced && $0 ~ "^"field":" {
        # 判斷是否需要加引號（含空格或特殊字元時）
        if (value ~ /[ :]/) {
          print field ": \"" value "\""
        } else {
          print field ": " value
        }
        replaced=1
        next
      }
      { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  else
    # 欄位不存在 → 在 frontmatter 結尾 (第二個 ---) 前插入
    awk -v field="$field" -v value="$value" '
      BEGIN { in_fm=0; inserted=0 }
      /^---$/ {
        in_fm++
        if (in_fm == 2 && !inserted) {
          if (value ~ /[ :]/) {
            print field ": \"" value "\""
          } else {
            print field ": " value
          }
          inserted=1
        }
        print
        next
      }
      { print }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"
  fi

  echo "Updated $file: $field = $value"
}

# --- 命令: init ---
cmd_init() {
  local dir="$1"
  local total=0 synced=0 unsynced=0 stale=0

  echo "=== Spec Sync Status: $dir ==="
  echo ""

  for f in "$dir"/story-*.md "$dir"/spike-*.md; do
    [[ -f "$f" ]] || continue
    total=$((total + 1))

    local story_id tracker_id synced_at title type priority
    story_id=$(get_field "$f" "story_id")
    tracker_id=$(get_field "$f" "tracker_id")
    synced_at=$(get_field "$f" "synced_at")
    title=$(get_field "$f" "title")
    type=$(get_field "$f" "type")
    priority=$(get_field "$f" "priority")

    local status_icon status_text
    if [[ -z "$tracker_id" || "$tracker_id" == "＿＿" ]]; then
      status_icon="○"
      status_text="NOT_SYNCED"
      unsynced=$((unsynced + 1))
    elif [[ -z "$synced_at" || "$synced_at" == "＿＿" ]]; then
      status_icon="△"
      status_text="NO_TIMESTAMP"
      stale=$((stale + 1))
    else
      status_icon="●"
      status_text="SYNCED ($tracker_id)"
      synced=$((synced + 1))
    fi

    printf "  %s %-4s [Story %s] %-40s %s\n" "$status_icon" "$priority" "$story_id" "$title" "$status_text"
  done

  echo ""
  echo "--- Summary ---"
  echo "  Total:      $total"
  echo "  Synced:     $synced  (●)"
  echo "  Unsynced:   $unsynced  (○)"
  echo "  Needs fix:  $stale  (△)"

  if [[ $unsynced -gt 0 ]]; then
    echo ""
    echo "Run 'spec-frontmatter.sh unsynced $dir' to get file paths for sync."
  fi
}

# --- Main ---
case "${1:-}" in
  read)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 read <file>" >&2; exit 1; }
    cmd_read "$2"
    ;;
  list)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 list <dir>" >&2; exit 1; }
    cmd_list "$2"
    ;;
  stale)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 stale <dir>" >&2; exit 1; }
    cmd_stale "$2"
    ;;
  unsynced)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 unsynced <dir>" >&2; exit 1; }
    cmd_unsynced "$2"
    ;;
  compare)
    [[ -z "${2:-}" || -z "${3:-}" ]] && { echo "Usage: $0 compare <file> <tracker_updated_at>" >&2; exit 1; }
    cmd_compare "$2" "$3"
    ;;
  update)
    [[ -z "${2:-}" || -z "${3:-}" || -z "${4:-}" ]] && { echo "Usage: $0 update <file> <field> <value>" >&2; exit 1; }
    cmd_update "$2" "$3" "$4"
    ;;
  init)
    [[ -z "${2:-}" ]] && { echo "Usage: $0 init <dir>" >&2; exit 1; }
    cmd_init "$2"
    ;;
  *)
    cat <<USAGE
spec-frontmatter.sh — Spec Story frontmatter 工具

Commands:
  read <file>                     讀取單一檔案 frontmatter (JSON)
  list <dir>                      列出目錄下所有 story 的 frontmatter (JSON array)
  stale <dir>                     列出需要注意的 stories (未同步或無時間戳)
  unsynced <dir>                  列出尚未同步到 tracker 的 story 檔案路徑
  compare <file> <updated_at>     比較本地 synced_at 與 tracker updated_at
  update <file> <field> <value>   更新單一 frontmatter 欄位
  init <dir>                      顯示目錄下所有 stories 的同步狀態摘要

Examples:
  $0 read .project/specs/lan-sharing/story-82-qr-code.md
  $0 list .project/specs/lan-sharing/
  $0 stale .project/specs/lan-sharing/
  $0 unsynced .project/specs/lan-sharing/
  $0 compare story-82-qr-code.md 2026-03-21T08:00:00Z
  $0 update story-82-qr-code.md tracker_id TIM-51
  $0 init .project/specs/lan-sharing/
USAGE
    exit 1
    ;;
esac
