#!/usr/bin/env bash
set -euo pipefail

# Deploy to Google Drive
# Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/gdrive-deploy"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"
SOURCE_FOLDER="${1:?Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]}"
PROJECT_NAME="${2:?Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]}"
PARENT_FOLDER_ID="${3:-}"

# --- Check prerequisites ---
if ! command -v gdrive &>/dev/null; then
    echo "ERROR: gdrive not installed. Run: brew install gdrive" >&2
    exit 1
fi

if ! gdrive account list &>/dev/null || [ -z "$(gdrive account list 2>/dev/null)" ]; then
    echo "ERROR: No gdrive account. Run: gdrive account add" >&2
    exit 1
fi

if [ ! -d "$SOURCE_FOLDER" ]; then
    echo "ERROR: Source folder not found: $SOURCE_FOLDER" >&2
    exit 1
fi

# --- Resolve parent folder from config if not provided ---
if [ -z "$PARENT_FOLDER_ID" ] && [ -f "$CONFIG_FILE" ]; then
    PARENT_FOLDER_ID=$(python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE') as f:
        print(json.load(f).get('default_parent_folder_id', ''))
except: pass
" 2>/dev/null || true)
fi

# --- Get serial number ---
SERIAL=$(python3 "$SCRIPT_DIR/get-serial.py" "$PROJECT_NAME")
TODAY=$(date +%Y%m%d)
FILENAME="${PROJECT_NAME}_${TODAY}_${SERIAL}"

# --- Package ---
PARENT_DIR="$(dirname "$SOURCE_FOLDER")"
FOLDER_NAME="$(basename "$SOURCE_FOLDER")"
ZIP_PATH="/tmp/${FILENAME}.zip"

echo "📦 Packaging: $SOURCE_FOLDER -> $ZIP_PATH"
(cd "$PARENT_DIR" && zip -r "$ZIP_PATH" "$FOLDER_NAME" \
    -x "*/.vscode/*" \
    -x "*/.DS_Store" \
    -x "*/node_modules/*" \
    -x "*/.git/*" \
    -x "*/__pycache__/*" \
    -x "*/.env" \
    -x "*/.env.*" \
)

# --- Upload ---
echo "☁️  Uploading to Google Drive..."
if [ -n "$PARENT_FOLDER_ID" ]; then
    FILE_ID=$(gdrive files upload --print-only-id --parent "$PARENT_FOLDER_ID" "$ZIP_PATH")
else
    FILE_ID=$(gdrive files upload --print-only-id "$ZIP_PATH")
fi

if [ -z "$FILE_ID" ]; then
    echo "ERROR: Upload failed - no file ID returned" >&2
    exit 1
fi

# --- Share ---
echo "🔗 Setting share permissions..."
gdrive permissions share "$FILE_ID" >/dev/null 2>&1

# --- Report ---
SHARE_LINK="https://drive.google.com/file/d/${FILE_ID}/view?usp=sharing"

echo ""
echo "✅ 部署完成！"
echo ""
echo "📦 檔案名稱: ${FILENAME}.zip"
echo "📁 來源資料夾: $SOURCE_FOLDER"
echo "🔗 Google Drive 連結: $SHARE_LINK"
echo "🔢 序列號: $SERIAL"
echo "🆔 File ID: $FILE_ID"

# --- Cleanup ---
rm -f "$ZIP_PATH"
echo ""
echo "🧹 已清理暫存檔案"
