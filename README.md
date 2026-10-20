# laravel-api-standards

Standar arsitektur, naming convention, dan struktur folder untuk Laravel API —
dipaketkan sebagai **Claude Code Plugin** sekaligus **Skill universal**, supaya
tim tinggal 1-2 command tiap bikin project baru, tanpa copy-paste dokumentasi.

Target: **Laravel 13** (PHP 8.3+), tetap kompatibel dengan Laravel 12. Memakai
Sanctum 4, Spatie Laravel Permission 8, Reverb (realtime), Laravel AI SDK,
Laravel Excel 4, DomPDF 3, PHP attributes model (`#[Table]`,
`#[Fillable]`), konfigurasi `bootstrap/app.php`, dan guard N+1 bawaan Laravel.

Mencakup: multi-tenant (company/plan), RBAC dinamis (role dibuat user, permission per role), konfirmasi stack sebelum install, versioning API, Form Request wajib,
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

## Install (semua agent: Codex, Gemini CLI, Antigravity, Cursor, Copilot, Windsurf, dll)

Jalankan di root project Laravel kamu:

```bash
curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash
```

Yang dipasang:

| Agent | Lokasi |
|---|---|
| Claude Code | `.claude/skills/laravel-api-standards/` |
| Codex | `.agents/skills/laravel-api-standards/` + `AGENTS.md` |
| Gemini CLI | `.gemini/skills/laravel-api-standards/` + `GEMINI.md` |
| Antigravity | `.agent/skills/laravel-api-standards/` |
| Cursor, GitHub Copilot, Windsurf, Cline, Aider | `AGENTS.md` (dibaca otomatis dari root project) |

`AGENTS.md`, `CLAUDE.md`, dan `GEMINI.md` yang sudah ada **tidak ditimpa**, hanya
ditambahkan pointer ke standar ini.

Install global (sekali pasang, kepakai di semua project untuk Claude Code, Codex,
Gemini CLI, dan Antigravity):

```bash
curl -fsSL https://raw.githubusercontent.com/arigunawanj/laravel-api-standards/main/install.sh | bash -s -- --global
```

Gemini CLI juga bisa lewat extension:

```bash
gemini extensions install https://github.com/arigunawanj/laravel-api-standards
```

## Cara kerja saat dipakai agent

- **Konfirmasi dulu, baru install.** Sebelum memasang package opsional (Reverb,
  AI SDK, Excel, PDF), agent wajib cek yang sudah terpasang lalu menanyakan ke kamu
  mana yang dibutuhkan. Jawabanmu dicatat di `AGENTS.md` (`## Stack Terpilih`)
  supaya agent lain/sesi berikutnya tidak bertanya ulang.
- **Command non-interaktif.** Semua `artisan`/`composer` memakai `--no-interaction`
  dan flag eksplisit, jadi tidak macet di agent yang tidak bisa menjawab prompt.
- **RBAC dinamis.** Owner/admin company bisa membuat role sendiri dengan
  permission berbeda-beda per role (Spatie teams per company, anti privilege
  escalation), lewat endpoint `/api/v1/rbac/*`.

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
