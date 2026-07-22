# laravel-ari-standards

Standar arsitektur, naming convention, dan struktur folder Laravel API milik Ari —
dipaketkan sebagai **Claude Code Plugin** sekaligus **Skill universal**, supaya
tinggal 1-2 command tiap bikin project baru, tidak copy-paste dokumentasi lagi.

Mencakup: multi-tenant (company/plan/RBAC), versioning API, Form Request wajib,
response macro standar, anti N+1, security/injection prevention, token security
Sanctum, naming tabel (`m_`, `t_`, `_det`), naming model (`...Model`), dan struktur
folder per fitur.

## Install (Claude Code — paling simpel)

Buka Claude Code di mana saja, lalu jalankan dua command ini:

```
/plugin marketplace add <GITHUB_USERNAME>/laravel-ari-standards
/plugin install laravel-ari-standards@laravel-ari-standards
```

Ganti `<GITHUB_USERNAME>` dengan username GitHub kamu. Sekali install, plugin ini
otomatis aktif di **semua project** kamu (pilih "User scope" saat diminta) — tidak
perlu install ulang tiap bikin project Laravel baru.

Setelah install, jalankan `/reload-plugins` supaya langsung aktif di sesi
berjalan. Claude Code akan otomatis mengonsultasikan skill ini setiap kali kamu
membuat/mengubah model, controller, migration, request, atau resource Laravel.

Update ke versi terbaru kalau `SKILL.md` diedit:
```
/plugin marketplace update laravel-ari-standards
/plugin update laravel-ari-standards
```

## Install (agent selain Claude Code — Cursor, Cline, Windsurf, Aider, Codex, dll)

Agent-agent ini belum punya sistem plugin seperti Claude Code, jadi pakai file
`AGENTS.md` (konvensi universal yang mereka baca otomatis dari root project):

```bash
curl -fsSL https://raw.githubusercontent.com/<GITHUB_USERNAME>/laravel-ari-standards/main/install.sh | bash
```

Jalankan perintah ini di root project Laravel yang baru dibuat. Ini akan
menyalin `AGENTS.md` ke root project + `SKILL.md` ke `.claude/skills/` (sebagai
fallback kalau `/plugin` belum tersedia di versi Claude Code kamu).

## Struktur repo

```
laravel-ari-standards/
├── .claude-plugin/
│   ├── plugin.json          # manifest plugin
│   └── marketplace.json      # katalog marketplace (repo ini jadi marketplace-nya sendiri)
├── skills/
│   └── laravel-ari-standards/
│       └── SKILL.md            # source of truth: standar lengkap
├── AGENTS.md                     # auto-generated dari SKILL.md, untuk agent non-Claude
├── CLAUDE.md                      # pointer pendek (dipakai mode fallback install.sh)
├── install.sh                      # installer fallback (curl | bash)
└── scripts/
    └── sync-agents.sh                # regenerate AGENTS.md dari SKILL.md
```

## Cara publish ke GitHub kamu

1. Buat repo baru di GitHub: `laravel-ari-standards`, **public** (marketplace
   plugin butuh akses publik supaya `/plugin marketplace add` bisa fetch).
2. Di folder ini:
   ```bash
   git init
   git add .
   git commit -m "init: laravel-ari-standards plugin"
   git branch -M main
   git remote add origin https://github.com/<GITHUB_USERNAME>/laravel-ari-standards.git
   git push -u origin main
   ```
3. Ganti semua `<GITHUB_USERNAME>` di README.md dan install.sh dengan username
   GitHub kamu, commit ulang.
4. Tes dari Claude Code (di project manapun):
   ```
   /plugin marketplace add <GITHUB_USERNAME>/laravel-ari-standards
   /plugin install laravel-ari-standards@laravel-ari-standards
   ```

## Update standar di kemudian hari

1. Edit `skills/laravel-ari-standards/SKILL.md` (source of truth).
2. Jalankan `./scripts/sync-agents.sh` supaya `AGENTS.md` ikut update.
3. Commit & push.
4. User plugin tinggal `/plugin marketplace update laravel-ari-standards` lalu
   `/plugin update laravel-ari-standards`. User `install.sh` tinggal jalankan
   ulang perintah install (idempotent).
