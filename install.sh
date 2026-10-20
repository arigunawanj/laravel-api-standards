#!/usr/bin/env bash
#
# Installer FALLBACK untuk laravel-api-standards.
#
# Kalau kamu pakai Claude Code versi baru, install lewat /plugin jauh lebih
# simpel (2 baris, langsung dari dalam Claude Code, tanpa curl/bash):
#
#   /plugin marketplace add arigunawanj/laravel-api-standards
#   /plugin install laravel-api-standards@laravel-api-standards
#
# Script ini memasang skill untuk SEMUA agent sekaligus:
#   Claude Code  -> .claude/skills/
#   Codex        -> .agents/skills/   (+ AGENTS.md)
#   Gemini CLI   -> .gemini/skills/   (+ GEMINI.md)
#   Antigravity  -> .agent/skills/ (project) / ~/.gemini/antigravity/skills/ (global)
#   Cursor, Copilot, Windsurf, Cline, Aider, dll -> AGENTS.md di root project
#
# Pemakaian:
#   # Install ke project Laravel yang sedang aktif (folder saat ini)
#   curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash
#
#   # Install global, otomatis kepakai di SEMUA project (Claude Code, Codex, Gemini CLI, Antigravity)
#   curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash -s -- --global
#
# Fork repo ini? Override REPO_SLUG=<username>/<repo> sebelum menjalankan script.

set -euo pipefail

# --- Konfigurasi ---------------------------------------------------------
REPO_SLUG="${REPO_SLUG:-arigunawanj/laravel-api-standards}"
BRANCH="${BRANCH:-main}"
SKILL_NAME="laravel-api-standards"
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
if [[ -n "${SCRIPT_DIR:-}" && -f "${SCRIPT_DIR}/skills/${SKILL_NAME}/SKILL.md" ]]; then
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

# Tambahkan pointer ke file instruksi agent (CLAUDE.md / GEMINI.md) tanpa menimpa isi lama.
link_pointer() {
  local file="$1"
  if [[ -f "$file" ]]; then
    if ! grep -q "AGENTS.md" "$file" 2>/dev/null; then
      {
        echo ""
        echo "## Project Standards"
        echo ""
        echo "Baca dan patuhi \`AGENTS.md\` di root project ini (Laravel API Standards)."
      } >> "$file"
      echo "  -> ${file} (ditambahkan referensi ke AGENTS.md)"
    else
      echo "  -> ${file} sudah mereferensikan AGENTS.md, dilewati"
    fi
  else
    fetch_file "CLAUDE.md" "$file"
  fi
}

if [[ "$MODE" == "global" ]]; then
  # Global: kepakai otomatis di SEMUA project, tanpa install ulang.
  for dir in "${HOME}/.claude/skills" "${HOME}/.agents/skills" "${HOME}/.gemini/skills" "${HOME}/.gemini/antigravity/skills"; do
    fetch_file "skills/${SKILL_NAME}/SKILL.md" "${dir}/${SKILL_NAME}/SKILL.md"
  done
  echo
  echo "Selesai. Skill terpasang global untuk Claude Code, Codex, Gemini CLI, dan Antigravity."
  echo "Untuk Cursor/Copilot/Windsurf, jalankan mode project (tanpa --global) di root project."
else
  # Project: skill untuk tiap agent + AGENTS.md universal + pointer CLAUDE.md / GEMINI.md
  cd "$TARGET_DIR"

  for dir in ".claude/skills" ".agents/skills" ".gemini/skills" ".agent/skills"; do
    fetch_file "skills/${SKILL_NAME}/SKILL.md" "${dir}/${SKILL_NAME}/SKILL.md"
  done

  if [[ -f "AGENTS.md" ]] && ! grep -q "Laravel API Standards\|laravel-api-standards" AGENTS.md 2>/dev/null; then
    # Jangan timpa AGENTS.md milik project; tambahkan pointer saja
    {
      echo ""
      echo "## Project Standards"
      echo ""
      echo "Ikuti standar Laravel API di \`.agents/skills/${SKILL_NAME}/SKILL.md\` sebelum membuat atau mengubah model, controller, migration, request, resource, atau RBAC."
    } >> AGENTS.md
    echo "  -> AGENTS.md (sudah ada, ditambahkan pointer ke skill)"
  else
    fetch_file "AGENTS.md" "AGENTS.md"
  fi

  link_pointer "CLAUDE.md"
  link_pointer "GEMINI.md"

  echo
  echo "Selesai. Terpasang di: ${TARGET_DIR}"
  echo "  .claude/skills/${SKILL_NAME}/   <- Claude Code"
  echo "  .agents/skills/${SKILL_NAME}/   <- Codex"
  echo "  .gemini/skills/${SKILL_NAME}/   <- Gemini CLI"
  echo "  .agent/skills/${SKILL_NAME}/    <- Antigravity"
  echo "  AGENTS.md                        <- Codex, Cursor, Copilot, Windsurf, Cline, Aider, dll"
  echo "  CLAUDE.md / GEMINI.md            <- pointer ke AGENTS.md"
fi
