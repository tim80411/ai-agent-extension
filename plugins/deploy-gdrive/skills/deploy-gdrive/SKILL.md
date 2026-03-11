---
name: deploy-gdrive
description: Package static website project into a zip and upload to Google Drive, returning a share link. Use when the user mentions "deploy", "上傳 Google Drive", "打包上傳", "gdrive deploy", "交付", "打包交付", "上傳到雲端硬碟", or wants to package and deliver project files via Google Drive.
---

# Deploy to Google Drive

Package a static website project and upload it to Google Drive with a shareable link.

## Prerequisites

- `gdrive` CLI v3 (`brew install gdrive`)
- `gdrive` authenticated (`gdrive account add`)

## Quick Workflow

1. **Check**: Verify `gdrive version` and `gdrive account list`
2. **Detect**: Find folder with `index.html` (the deployable static site)
3. **Name**: `{project_name}_{YYYYMMDD}_{serial}.zip`
4. **Package**: Zip the folder (exclude `.vscode`, `node_modules`, `.DS_Store`, `.git`)
5. **Upload**: `gdrive files upload` → `gdrive permissions share`
6. **Report**: Present Google Drive share link to user

## Naming Convention

- **Project name**: Derive from workspace root folder name, cleaned up
- **Date**: Today in `YYYYMMDD`
- **Serial**: Auto-incremented per project+date combo

## Executing the Deploy

Locate the bundled scripts relative to this SKILL.md file under `scripts/`:

```bash
# Resolve the skill's script directory
SKILL_DIR="<directory containing this SKILL.md>"
bash "$SKILL_DIR/scripts/deploy.sh" "<source_folder>" "<project_name>" [parent_folder_id]
```

Or follow the step-by-step commands in [references/references.md](references/references.md).

## Configuration

All config lives in `~/.config/gdrive-deploy/`:

| File | Purpose |
|------|---------|
| `config.json` | `{"default_parent_folder_id": "FOLDER_ID"}` — default upload destination |
| `serial.json` | Auto-managed serial number tracking per project+date |

Create config if needed:
```bash
mkdir -p ~/.config/gdrive-deploy
echo '{"default_parent_folder_id": "YOUR_FOLDER_ID"}' > ~/.config/gdrive-deploy/config.json
```

## Output Format

```
✅ 部署完成！

📦 檔案名稱: {filename}.zip
📁 來源資料夾: {source_folder}
🔗 Google Drive 連結: https://drive.google.com/file/d/{file_id}/view?usp=sharing
🔢 序列號: {serial}
```
