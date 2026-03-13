# Deploy to Google Drive — Reference

## Step-by-Step Commands

### 1. Verify Environment

```bash
gdrive version
gdrive account list
```

If no account: stop and ask user to run `gdrive account add`.

### 2. Detect Static Website Folder

Look for folders containing `index.html` in the workspace:
- Prefer shallower paths (direct children of workspace root)
- Exclude `node_modules`, `dist`, `build` if raw source also has `index.html`
- If multiple candidates, ask the user

### 3. Analyze Product Name

Do NOT just use the folder name. Run the following commands **from the workspace root** (or the detected static site folder) to gather clues:

```bash
# Check package.json name
python3 -c "import json; print(json.load(open('package.json')).get('name',''))" 2>/dev/null

# Check HTML title (adjust path to the detected index.html)
python3 -c "
import re
with open('index.html') as f:
    m = re.search(r'<title>(.*?)</title>', f.read(), re.IGNORECASE)
    if m: print(m.group(1))
" 2>/dev/null

# Check README first heading (supports both README.md and README)
head -5 README.md README 2>/dev/null | grep -m1 '^#' | sed 's/^#* *//'

# Folder name (as reference only)
basename "$(pwd)"
```

Synthesize a concise product name in snake_case from the gathered information, then **confirm with the user** before proceeding.

### 4. Get Serial Number

```bash
python3 "<SKILL_DIR>/scripts/get-serial.py" "<PROJECT_NAME>"
```

`<SKILL_DIR>` is the directory containing this skill's SKILL.md file.

Returns the next serial number. Auto-creates/updates `~/.config/gdrive-deploy/serial.json`.

### 5. Read Config (Optional)

```bash
cat ~/.config/gdrive-deploy/config.json 2>/dev/null
```

If `default_parent_folder_id` exists, use as upload destination.

### 6. Archive Old Files

If uploading to a parent folder, move existing files to an `old` subfolder first:

```bash
# Check if 'old' folder exists in parent
OLD_FOLDER_ID=$(gdrive files list --parent "<PARENT_FOLDER_ID>" --skip-header \
  --query "name = 'old' and mimeType = 'application/vnd.google-apps.folder' and trashed = false" \
  | head -1 | cut -f1)

# Create 'old' folder if not found
if [ -z "$OLD_FOLDER_ID" ]; then
  OLD_FOLDER_ID=$(gdrive files mkdir --print-only-id --parent "<PARENT_FOLDER_ID>" "old")
fi

# Move files matching the same project name into 'old'
gdrive files list --parent "<PARENT_FOLDER_ID>" --skip-header --full-name \
  --query "name contains '<PROJECT_NAME>' and trashed = false" \
  | while IFS=$'\t' read -r fid rest; do
      gdrive files move "$fid" "$OLD_FOLDER_ID"
    done
```

### 7. Package

```bash
cd "<PARENT_DIR_OF_TARGET>"
zip -r "/tmp/<FILENAME>.zip" "<TARGET_FOLDER_NAME>" \
  -x "*/.vscode/*" \
  -x "*/.DS_Store" \
  -x "*/node_modules/*" \
  -x "*/.git/*" \
  -x "*/__pycache__/*" \
  -x "*/.env" \
  -x "*/.env.*"
```

### 8. Upload & Share

```bash
# Without parent folder
FILE_ID=$(gdrive files upload --print-only-id "/tmp/<FILENAME>.zip")

# With parent folder
FILE_ID=$(gdrive files upload --print-only-id --parent "<FOLDER_ID>" "/tmp/<FILENAME>.zip")

# Share
gdrive permissions share "$FILE_ID"
```

### 9. Generate Link & Copy to Clipboard

```bash
SHARE_LINK="https://drive.google.com/file/d/<FILE_ID>/view?usp=sharing"
echo -n "$SHARE_LINK" | pbcopy
echo "📋 連結已複製到剪貼簿"
```

### 10. Cleanup

```bash
rm "/tmp/<FILENAME>.zip"
```

## Error Handling

| Error | Action |
|-------|--------|
| gdrive not installed | Tell user: `brew install gdrive` |
| No account | Tell user: `gdrive account add` |
| No index.html found | Ask user to specify the static web folder path |
| Upload fails | Check network, retry once, then report error |
| Multiple index.html candidates | Present options and ask user to choose |

## gdrive v3 Command Reference

| Command | Purpose |
|---------|---------|
| `gdrive files upload --print-only-id <path>` | Upload file, return only file ID |
| `gdrive files upload --parent <id> <path>` | Upload to specific folder |
| `gdrive permissions share <file_id>` | Share with anyone (reader) |
| `gdrive files info <file_id>` | Get file details |
| `gdrive files mkdir --parent <id> <name>` | Create subfolder in specific folder |
| `gdrive files move <file_id> <folder_id>` | Move file/folder to another folder |
| `gdrive account list` | List authenticated accounts |
| `gdrive account add` | Add new Google account |
