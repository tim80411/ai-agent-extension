#!/usr/bin/env bash
set -euo pipefail

# Deploy to Google Drive
# Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]
# Cross-platform: macOS (python3 + zip + pbcopy) / Windows (PowerShell + clip)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/gdrive-deploy"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"
SOURCE_FOLDER="${1:?Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]}"
PROJECT_NAME="${2:?Usage: deploy.sh <source_folder> <project_name> [parent_folder_id]}"
PARENT_FOLDER_ID="${3:-}"

# --- Detect platform ---
IS_WINDOWS=false
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    IS_WINDOWS=true
fi

# --- Helper: read JSON value by key ---
# Usage: json_read <file> <key>
json_read() {
    local file="$1" key="$2"
    if $IS_WINDOWS; then
        powershell -NoProfile -Command "
            \$d = Get-Content -Raw '$file' | ConvertFrom-Json
            if (\$d.PSObject.Properties['$key']) { Write-Host -NoNewline \$d.'$key' }
        " 2>/dev/null || true
    else
        python3 -c "
import json
try:
    with open('$file') as f:
        print(json.load(f).get('$key', ''), end='')
except: pass
" 2>/dev/null || true
    fi
}

# --- Helper: get and increment serial ---
# Usage: get_serial <project_name>
get_serial() {
    local project="$1"
    local serial_file="$CONFIG_DIR/serial.json"
    local today
    today=$(date +%Y%m%d)
    local key="${project}_${today}"

    if $IS_WINDOWS; then
        powershell -NoProfile -Command "
            \$f = '$serial_file'
            \$key = '$key'
            \$data = @{}
            if (Test-Path \$f) {
                try { \$data = Get-Content -Raw \$f | ConvertFrom-Json -AsHashtable } catch { \$data = @{} }
            }
            \$serial = 0
            if (\$data.ContainsKey(\$key)) { \$serial = [int]\$data[\$key] }
            \$serial++
            \$data[\$key] = \$serial
            \$data | ConvertTo-Json | Set-Content -Encoding UTF8 \$f
            Write-Host -NoNewline \$serial
        " 2>/dev/null
    else
        python3 "$SCRIPT_DIR/get-serial.py" "$project"
    fi
}

# --- Check prerequisites ---
if ! command -v gdrive &>/dev/null; then
    echo "ERROR: gdrive not installed." >&2
    if $IS_WINDOWS; then
        echo "Install from: https://github.com/glotlabs/gdrive/releases" >&2
    else
        echo "Run: brew install gdrive" >&2
    fi
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
    PARENT_FOLDER_ID=$(json_read "$CONFIG_FILE" "default_parent_folder_id")
fi

# --- Get serial number ---
SERIAL=$(get_serial "$PROJECT_NAME")
TODAY=$(date +%Y%m%d)
FILENAME="${PROJECT_NAME}_${TODAY}_${SERIAL}"

# --- Package ---
PARENT_DIR="$(dirname "$SOURCE_FOLDER")"
FOLDER_NAME="$(basename "$SOURCE_FOLDER")"

if $IS_WINDOWS; then
    ZIP_PATH="$(cygpath -w "$TEMP")\\${FILENAME}.zip"
    ZIP_PATH_UNIX="$TEMP/${FILENAME}.zip"
else
    ZIP_PATH="/tmp/${FILENAME}.zip"
    ZIP_PATH_UNIX="$ZIP_PATH"
fi

echo "📦 Packaging: $SOURCE_FOLDER -> ${FILENAME}.zip"

if $IS_WINDOWS; then
    PS_SCRIPT="$TEMP/deploy_zip_$$.ps1"
    cat > "$PS_SCRIPT" << 'PSEOF'
param([string]$source, [string]$dest, [string]$tempStaging)
if (Test-Path $tempStaging) { Remove-Item $tempStaging -Recurse -Force }
if (Test-Path $dest) { Remove-Item $dest -Force }
robocopy $source $tempStaging /E /XD .vscode node_modules .git __pycache__ /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
Compress-Archive -Path (Join-Path $tempStaging '*') -DestinationPath $dest -Force
Remove-Item $tempStaging -Recurse -Force
PSEOF
    STAGING_DIR="$(cygpath -w "$TEMP")\\deploy_staging_$$"
    SRC_WIN="$(cygpath -w "$SOURCE_FOLDER")"
    powershell -ExecutionPolicy Bypass -File "$(cygpath -w "$PS_SCRIPT")" \
        -source "$SRC_WIN" -dest "$ZIP_PATH" -tempStaging "$STAGING_DIR"
    rm -f "$PS_SCRIPT"
else
    (cd "$PARENT_DIR" && zip -r "$ZIP_PATH" "$FOLDER_NAME" \
        -x "*/.vscode/*" \
        -x "*/.DS_Store" \
        -x "*/node_modules/*" \
        -x "*/.git/*" \
        -x "*/__pycache__/*" \
        -x "*/.env" \
        -x "*/.env.*" \
    )
fi

# --- Archive old files in parent folder ---
if [ -n "$PARENT_FOLDER_ID" ]; then
    echo "📂 Archiving old files matching '$PROJECT_NAME'..."

    OLD_FOLDER_ID=$(gdrive files list --skip-header \
        --query "'$PARENT_FOLDER_ID' in parents and name = 'old' and mimeType = 'application/vnd.google-apps.folder' and trashed = false" \
        2>/dev/null | head -1 | cut -f1)

    if [ -z "$OLD_FOLDER_ID" ]; then
        echo "   Creating 'old' folder..."
        OLD_FOLDER_ID=$(gdrive files mkdir --print-only-id --parent "$PARENT_FOLDER_ID" "old")
    fi

    if [ -n "$OLD_FOLDER_ID" ]; then
        OLD_FILES=$(gdrive files list --skip-header \
            --query "'$PARENT_FOLDER_ID' in parents and name contains '$PROJECT_NAME' and trashed = false" \
            2>/dev/null || true)

        if [ -n "$OLD_FILES" ]; then
            echo "$OLD_FILES" | while read -r line; do
                fid=$(echo "$line" | awk '{print $1}')
                [ -z "$fid" ] && continue
                echo "   Moving: $fid -> old/"
                gdrive files move "$fid" "$OLD_FOLDER_ID" 2>/dev/null || echo "   ⚠️  Failed to move: $fid"
            done
        else
            echo "   No old files to archive."
        fi
    else
        echo "⚠️  Could not create/find 'old' folder, skipping archive" >&2
    fi
fi

# --- Upload ---
echo "☁️  Uploading to Google Drive..."
if [ -n "$PARENT_FOLDER_ID" ]; then
    FILE_ID=$(gdrive files upload --print-only-id --parent "$PARENT_FOLDER_ID" "$ZIP_PATH_UNIX")
else
    FILE_ID=$(gdrive files upload --print-only-id "$ZIP_PATH_UNIX")
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

# --- Copy to clipboard ---
if $IS_WINDOWS; then
    echo -n "$SHARE_LINK" | clip
elif command -v pbcopy &>/dev/null; then
    echo -n "$SHARE_LINK" | pbcopy
fi

echo ""
echo "✅ 部署完成！"
echo ""
echo "📦 檔案名稱: ${FILENAME}.zip"
echo "📁 來源資料夾: $SOURCE_FOLDER"
echo "🔗 Google Drive 連結: $SHARE_LINK"
echo "🔢 序列號: $SERIAL"
echo "🆔 File ID: $FILE_ID"
echo "📋 連結已複製到剪貼簿"

# --- Cleanup ---
rm -f "$ZIP_PATH_UNIX"
echo ""
echo "🧹 已清理暫存檔案"
