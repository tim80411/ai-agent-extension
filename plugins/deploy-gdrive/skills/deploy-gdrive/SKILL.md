---
name: deploy-gdrive
description: Package static website project into a zip and upload to Google Drive, returning a share link. Use when the user mentions "deploy", "上傳 Google Drive", "打包上傳", "gdrive deploy", "交付", "打包交付", "上傳到雲端硬碟", or wants to package and deliver project files via Google Drive.
---

# Deploy to Google Drive

Package a static website project and upload it to Google Drive with a shareable link.

## Prerequisites

- `gdrive` CLI v3 (macOS: `brew install gdrive` / Windows: [GitHub Releases](https://github.com/glotlabs/gdrive/releases))
- `gdrive` authenticated (`gdrive account add`)
- macOS: `python3` (system default), `zip`, `pbcopy`
- Windows: `PowerShell` (system default), `robocopy`, `clip`

## Quick Workflow

1. **Check**: Verify `gdrive version` and `gdrive account list`
2. **Detect**: Find folder with `index.html` (the deployable static site)
3. **Analyze & Confirm Name**: Gather product name clues from project files, synthesize a name, and confirm with the user
4. **Name**: `{project_name}_{YYYYMMDD}_{serial}.zip`
5. **Package**: Zip the folder (exclude `.vscode`, `node_modules`, `.DS_Store`, `.git`)
6. **Archive Old Files**: Move same-project files (matching `{project_name}` prefix) in the parent folder to an `old` subfolder (auto-created if needed)
7. **Upload**: `gdrive files upload` → `gdrive permissions share`
8. **Report**: Present Google Drive share link and copy it to clipboard

## Naming Convention

- **Project name**: Analyze the project to determine the product name — do NOT simply use the folder name. Follow this process:
  1. **Gather clues** from these sources (check whichever exist):
     - `package.json` → `name` field
     - `index.html` → `<title>` tag content
     - `README.md` / `README` → first heading
     - Workspace root folder name (as a reference, often contains part of the product name)
  2. **Synthesize**: Based on the gathered information, determine a concise, descriptive product name in snake_case (e.g. `my_landing_page`, `cool_widget`)
  3. **Confirm with the user**: Present the proposed product name and ask the user to confirm or modify before proceeding
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
📋 連結已複製到剪貼簿
```
