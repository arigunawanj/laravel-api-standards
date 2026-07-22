# laravel-ari-standards

Standar arsitektur, naming convention, dan struktur folder Laravel API milik Ari —
dipaketkan sebagai **Skill** yang bisa dipasang sekali per project (atau sekali
secara global) dan otomatis dipakai oleh AI coding agent, tanpa copy-paste
dokumentasi berulang-ulang tiap bikin project baru.

Mencakup: multi-tenant (company/plan/RBAC), versioning API, Form Request wajib,
response macro standar, anti N+1, security/injection prevention, token security
Sanctum, naming tabel (`m_`, `t_`, `_det`), naming model (`...Model`), dan struktur
folder per fitur.

## Kepakai di agent apa saja

| Agent | File yang dipakai |
|---|---|
| Claude Code / Claude.ai / Cowork | `.claude/skills/laravel-ari-standards/SKILL.md` (native Skill, auto-trigger dari deskripsi) |
| Cursor, Cline, Windsurf, Aider, OpenAI Codex CLI, dll | `AGENTS.md` di root project (konvensi universal yang didukung agent-agent tersebut) |
| Claude Code (fallback tanpa trigger) | `CLAUDE.md` — otomatis dibaca tiap sesi, cukup jadi pointer ke `AGENTS.md` |

`AGENTS.md` digenerate otomatis dari isi `SKILL.md` (lihat `scripts/sync-agents.sh`)
supaya kamu cuma perlu maintain **satu** sumber (`SKILL.md`), tidak dua dokumen
yang bisa beda-beda.

## Install

### A. Sekali pasang per project (rekomendasi kalau standar berbeda per klien)

Jalankan di root project Laravel yang baru dibuat:

```bash
curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash
```

Ini akan membuat:
```
.claude/skills/laravel-ari-standards/SKILL.md   # dipakai Claude Code
AGENTS.md                                        # dipakai agent lain
CLAUDE.md                                        # pointer, auto-load Claude Code
```

### B. Install sekali, kepakai otomatis di SEMUA project (rekomendasi kalau standar selalu sama)

```bash
curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash -s -- --global
```

Ini memasang ke `~/.claude/skills/laravel-ari-standards/SKILL.md`. Claude Code akan
otomatis mengonsultasikan skill ini di project Laravel manapun tanpa perlu
install ulang atau taruh file apapun di tiap project.

> Catatan: mode global hanya berlaku untuk Claude Code. Untuk Cursor/Cline/dll
> tetap perlu `AGENTS.md` per project (jalankan mode A), karena tool-tool
> tersebut belum punya mekanisme skill global lintas-project.

## Cara publish repo ini ke GitHub kamu sendiri

1. Buat repo baru di GitHub, misal `laravel-ari-standards` (boleh public/private —
   kalau private, `install.sh` versi `curl` tidak akan bisa akses tanpa token,
   jadi disarankan **public** khusus untuk repo standar seperti ini).
2. Di folder ini, jalankan:
   ```bash
   git init
   git add .
   git commit -m "init: laravel-ari-standards skill"
   git branch -M main
   git remote add origin https://github.com/<GITHUB_USERNAME>/laravel-ari-standards.git
   git push -u origin main
   ```
3. Buka `install.sh` dan `README.md`, ganti semua `<GITHUB_USERNAME>` dengan
   username GitHub kamu, lalu commit ulang.
4. Tes dari project lain:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash
   ```

## Update standar di kemudian hari

1. Edit `SKILL.md` (source of truth).
2. Jalankan `./scripts/sync-agents.sh` supaya `AGENTS.md` ikut update.
3. Commit & push.
4. Project lama tinggal jalankan ulang perintah install di atas untuk narik versi
   terbaru (script aman dijalankan berkali-kali / idempotent).

## Struktur repo

```
laravel-ari-standards/
├── SKILL.md              # source of truth: standar lengkap (format Claude Skill)
├── AGENTS.md              # auto-generated dari SKILL.md, untuk agent non-Claude
├── CLAUDE.md               # pointer pendek, auto-dibaca Claude Code
├── install.sh               # installer (curl | bash), mode --project / --global
└── scripts/
    └── sync-agents.sh       # regenerate AGENTS.md dari SKILL.md
```
