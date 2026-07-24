# laravel-api-standards

Standar arsitektur, naming convention, dan struktur folder untuk Laravel API —
dipaketkan sebagai **Claude Code Plugin** sekaligus **Skill universal**, supaya
tim tinggal 1-2 command tiap bikin project baru, tanpa copy-paste dokumentasi.

Mencakup: multi-tenant (company/plan/RBAC), versioning API, Form Request wajib,
response macro standar, anti N+1, security/injection prevention, token security
Sanctum, naming tabel (`m_`, `t_`, `_det`), naming model (`...Model`), dan struktur
folder per fitur.

## Install (Claude Code — paling simpel)

Buka Claude Code di project Laravel kamu, lalu jalankan:

```
/plugin marketplace add arigunawanj/laravel-api-standards
/plugin install laravel-api-standards@laravel-api-standards
```

Pilih **"User scope"** saat diminta — sekali install, plugin otomatis aktif di
**semua project** kamu, tidak perlu install ulang tiap bikin project baru.

Setelah install, jalankan `/reload-plugins` supaya langsung aktif di sesi
berjalan. Claude Code akan otomatis mengonsultasikan skill ini setiap kali kamu
membuat/mengubah model, controller, migration, request, atau resource Laravel.

Update ke versi terbaru:
```
/plugin marketplace update laravel-api-standards
/plugin update laravel-api-standards
```

## Install (agent selain Claude Code — Cursor, Cline, Windsurf, Aider, Codex, dll)

Agent-agent ini belum punya sistem plugin seperti Claude Code, jadi pakai file
`AGENTS.md` (konvensi universal yang mereka baca otomatis dari root project):

```bash
curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash
```

Jalankan di root project Laravel kamu. Ini menyalin `AGENTS.md` ke root project
+ `SKILL.md` ke `.claude/skills/` (fallback kalau `/plugin` belum tersedia di
versi Claude Code kamu).

Opsi lain:
```bash
# Install global — otomatis kepakai di semua project Claude Code
curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash -s -- --global
```

## Struktur repo

```
laravel-api-standards/
├── .claude-plugin/
│   ├── plugin.json          # manifest plugin
│   └── marketplace.json     # katalog marketplace (repo ini jadi marketplace-nya sendiri)
├── skills/
│   └── laravel-api-standards/
│       └── SKILL.md         # source of truth: standar lengkap
├── AGENTS.md                # auto-generated dari SKILL.md, untuk agent non-Claude
├── CLAUDE.md                # pointer pendek (dipakai mode fallback install.sh)
├── install.sh                # installer fallback (curl | bash)
└── scripts/
    └── sync-agents.sh        # regenerate AGENTS.md dari SKILL.md
```

## Update standar (untuk pemakai plugin)

Kalau maintainer merilis versi baru:

- Pengguna `/plugin`: `/plugin marketplace update laravel-api-standards` lalu
  `/plugin update laravel-api-standards`.
- Pengguna `install.sh`: jalankan ulang perintah install (idempotent).

---

## Maintaining (untuk yang kelola repo ini)

<details>
<summary>Publish pertama kali & update standar</summary>

### Publish awal ke GitHub

1. Buat repo baru di GitHub: `laravel-api-standards`, **public** (marketplace
   plugin butuh akses publik supaya `/plugin marketplace add` bisa fetch).
2. Di folder ini:
   ```bash
   git init
   git add .
   git commit -m "init: laravel-api-standards plugin"
   git branch -M main
   git remote add origin https://github.com/arigunawanj/laravel-api-standards.git
   git push -u origin main
   ```
3. Tes dari Claude Code (di project manapun):
   ```
   /plugin marketplace add arigunawanj/laravel-api-standards
   /plugin install laravel-api-standards@laravel-api-standards
   ```

### Update standar di kemudian hari

1. Edit `skills/laravel-api-standards/SKILL.md` (source of truth).
2. Jalankan `./scripts/sync-agents.sh` supaya `AGENTS.md` ikut update.
3. Naikkan `version` di `.claude-plugin/plugin.json` dan
   `.claude-plugin/marketplace.json`.
4. Commit & push.

</details>

## License

MIT — bebas dipakai, dimodifikasi, dan didistribusikan ulang.
