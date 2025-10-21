#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/.legacy-docs-export"
mkdir -p "$OUT_DIR"

copy_if_exists() {
  local rel="$1"
  if [[ -e "$ROOT_DIR/$rel" ]]; then
    echo "+ $rel"
    mkdir -p "$OUT_DIR/$(dirname "$rel")"
    cp -a "$ROOT_DIR/$rel" "$OUT_DIR/$rel"
  fi
}

# Collect top-level legacy docs
copy_if_exists "VISION.md"
copy_if_exists "STATUS-AUDIT.md"
copy_if_exists "ScoreKit.txt"
for f in "$ROOT_DIR"/ScoreKit_*; do [[ -e "$f" ]] && cp -a "$f" "$OUT_DIR/"; done
for f in "$ROOT_DIR"/AudioTalk_*; do [[ -e "$f" ]] && cp -a "$f" "$OUT_DIR/"; done

cat > "$OUT_DIR/README.md" << EOF
# AudioTalk Legacy Docs (Export)

This directory is a ready-to-push export of legacy documentation from the AudioTalk monorepo.

Suggested remote repo name: Fountain-Coach/AudioTalk-LegacyDocs

How to publish:

  cd "$OUT_DIR"
  git init
  git add .
  git commit -m "docs: import legacy AudioTalk documents from monorepo"
  # Optional: gh repo create Fountain-Coach/AudioTalk-LegacyDocs --public --source . --push
  # Or set remote manually and push

EOF

echo "Export prepared at: $OUT_DIR"

