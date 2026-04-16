#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: convert.sh <md-file-1> [md-file-2] ..." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR="/tmp/md2pdf-$(date +%s)"
IMGS_DIR="$TMPDIR/imgs"
mkdir -p "$IMGS_DIR"

HAS_FAILURE=0

for md_file in "$@"; do
  md_file="$(cd "$(dirname "$md_file")" && pwd)/$(basename "$md_file")"
  base="$(basename "$md_file")"
  name="${base%.md}"
  orig_dir="$(dirname "$md_file")"

  # Phase 2: Preprocess Mermaid
  node "$SCRIPT_DIR/preprocess.cjs" "$md_file" "$TMPDIR/$base" "$IMGS_DIR"

  # Phase 3: Render Mermaid PNGs
  mmd_count=0
  for mmd in "$IMGS_DIR"/mmd-"$name"-*.mmd; do
    [ -f "$mmd" ] || continue
    mmd_count=$((mmd_count + 1))
    png="${mmd%.mmd}.png"
    if ! npx --yes -p @mermaid-js/mermaid-cli mmdc -i "$mmd" -o "$png" -b white -w 1400 2>/tmp/md2pdf-mmdc-err.log; then
      echo "FAIL: $md_file - mmdc error: $(cat /tmp/md2pdf-mmdc-err.log)" >&2
      HAS_FAILURE=1
      continue 2
    fi
  done

  # Phase 4: Convert to PDF
  if ! (cd "$TMPDIR" && npx --yes md-to-pdf "$base" 2>/tmp/md2pdf-pdf-err.log); then
    echo "FAIL: $md_file - md-to-pdf error: $(cat /tmp/md2pdf-pdf-err.log)" >&2
    HAS_FAILURE=1
    continue
  fi

  # Move PDF back to original directory
  pdf_file="$TMPDIR/$name.pdf"
  if [ -f "$pdf_file" ]; then
    mv "$pdf_file" "$orig_dir/$name.pdf"
    echo "OK: $orig_dir/$name.pdf"
  else
    echo "FAIL: $md_file - PDF not generated" >&2
    HAS_FAILURE=1
  fi
done

# Phase 5: Cleanup
rm -rf "$TMPDIR"
rm -f /tmp/md2pdf-mmdc-err.log /tmp/md2pdf-pdf-err.log

exit $HAS_FAILURE
