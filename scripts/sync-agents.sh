#!/usr/bin/env bash
# Sinkronkan AGENTS.md dari body SKILL.md (tanpa YAML frontmatter).
# Jalankan ini setiap kali SKILL.md diedit.
set -euo pipefail

cd "$(dirname "$0")/.."

HEADER='<!--
  File ini adalah standar instruksi UNIVERSAL untuk AI coding agent
  (Cursor, Cline, Windsurf, Aider, OpenAI Codex CLI, dll — semua yang
  mendukung konvensi AGENTS.md).

  Untuk Claude Code, gunakan SKILL.md di folder yang sama (format Skill
  native Claude, dengan trigger otomatis berdasarkan deskripsi).

  Sumber kebenaran (source of truth) ada di SKILL.md. File ini digenerate
  dari body SKILL.md (tanpa YAML frontmatter) supaya isinya selalu identik.
  Jangan edit dua-duanya secara terpisah — edit SKILL.md, lalu jalankan
  ./scripts/sync-agents.sh untuk sinkronkan AGENTS.md.
-->
'

{
  echo "$HEADER"
  awk 'c<2 && /^---$/{c++; next} c>=2{print}' skills/laravel-api-standards/SKILL.md
} > AGENTS.md

echo "AGENTS.md berhasil disinkronkan dari SKILL.md"
