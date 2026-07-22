#!/usr/bin/env bash
#
# Installer untuk laravel-ari-standards
#
# Pemakaian:
#   # Install ke project Laravel yang sedang aktif (folder saat ini)
#   curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash
#
#   # Install global, otomatis kepakai di SEMUA project Claude Code
#   curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash -s -- --global
#
# Ganti <GITHUB_USERNAME> di atas dengan username GitHub kamu setelah repo dipublish.

set -euo pipefail

# --- Konfigurasi (edit setelah upload ke GitHub) -----------------------
REPO_SLUG="${REPO_SLUG:-<GITHUB_USERNAME>/laravel-ari-standards}"
BRANCH="${BRANCH:-main}"
SKILL_NAME="laravel-ari-standards"
RAW_BASE="https://raw.githubusercontent.com/${REPO_SLUG}/${BRANCH}"
# -------------------------------------------------------------------------

MODE="project"
TARGET_DIR="$(pwd)"

for arg in "$@"; do
  case "$arg" in
    --global) MODE="global" ;;
    --project) MODE="project" ;;
    --dir=*) TARGET_DIR="${arg#*=}" ;;
    -h|--help)
      echo "Pemakaian: install.sh [--global|--project] [--dir=/path/ke/project]"
      exit 0
      ;;
  esac
done

# Jika script dijalankan dari dalam clone repo lokal, pakai file lokal.
# Kalau tidak (mode curl | bash), download dari GitHub raw.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-.}")" 2>/dev/null && pwd || true)"
LOCAL_MODE=false
if [[ -n "${SCRIPT_DIR:-}" && -f "${SCRIPT_DIR}/SKILL.md" ]]; then
  LOCAL_MODE=true
fi

fetch_file() {
  local rel_path="$1"
  local dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [[ "$LOCAL_MODE" == true ]]; then
    cp "${SCRIPT_DIR}/${rel_path}" "$dest"
  else
    curl -fsSL "${RAW_BASE}/${rel_path}" -o "$dest"
  fi
  echo "  -> ${dest}"
}

echo "Installing ${SKILL_NAME} (mode: ${MODE})"
echo

if [[ "$MODE" == "global" ]]; then
  # Global: kepakai otomatis di SEMUA project Claude Code, tanpa install ulang.
  DEST="${HOME}/.claude/skills/${SKILL_NAME}/SKILL.md"
  fetch_file "SKILL.md" "$DEST"
  echo
  echo "Selesai. Skill terpasang global di ~/.claude/skills/${SKILL_NAME}/"
  echo "Claude Code akan otomatis konsultasi skill ini di project Laravel manapun."
else
  # Project: pasang Skill Claude Code + AGENTS.md universal + pointer CLAUDE.md
  cd "$TARGET_DIR"

  fetch_file "SKILL.md" ".claude/skills/${SKILL_NAME}/SKILL.md"
  fetch_file "AGENTS.md" "AGENTS.md"

  if [[ -f "CLAUDE.md" ]]; then
    if ! grep -q "AGENTS.md" CLAUDE.md 2>/dev/null; then
      {
        echo ""
        echo "## Project Standards"
        echo ""
        echo "Baca dan patuhi \`AGENTS.md\` di root project ini (Laravel Ari Standards)."
      } >> CLAUDE.md
      echo "  -> CLAUDE.md (ditambahkan referensi ke AGENTS.md)"
    else
      echo "  -> CLAUDE.md sudah mereferensikan AGENTS.md, dilewati"
    fi
  else
    fetch_file "CLAUDE.md" "CLAUDE.md"
  fi

  echo
  echo "Selesai. Terpasang di: ${TARGET_DIR}"
  echo "  .claude/skills/${SKILL_NAME}/SKILL.md   <- dipakai Claude Code (auto-trigger)"
  echo "  AGENTS.md                                <- dipakai Cursor / Cline / Windsurf / Aider / Codex, dll"
  echo "  CLAUDE.md                                <- pointer, auto-dibaca Claude Code tiap sesi"
fi
