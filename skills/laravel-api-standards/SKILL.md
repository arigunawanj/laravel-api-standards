---
name: laravel-api-standards
description: Architect, implement, and review Laravel 13 APIs (PHP 8.3+, also compatible with Laravel 12) following strict enterprise standards for multi-tenancy, naming conventions (m_, t_, Model suffix), folder structures, and mandatory audit fields. Use when creating or modifying Laravel models, controllers, migrations, RBAC roles/permissions, or when performing code reviews to ensure strict adherence to the defined schema. Before installing any optional package (Reverb, AI SDK, Excel, DomPDF) the agent must ask the user which ones are needed.
---

# Dokumentasi Awalan Laravel API (Naming Convention & Struktur Folder)

Dokumentasi ini digunakan sebagai **standar awal (awalan / prompt)** dalam membuat API menggunakan **Laravel**, agar struktur project rapi, konsisten, dan mudah dikembangkan.

---

## 0. Protokol Agent (Wajib Dibaca Sebelum Install Apa Pun)

Standar ini dipakai oleh berbagai AI coding agent (Claude Code, Codex, Gemini CLI, Antigravity, Cursor, Copilot, Windsurf, dll). Aturan di bagian ini berlaku sama untuk semua agent.

### 0.1 Konfirmasi Stack Sebelum Install

**Dilarang asal install package.** Sebelum menjalankan `composer require`, `php artisan install:*`, atau `vendor:publish`:

1. **Cek dulu yang sudah terpasang**: baca `composer.json`, dan cek keberadaan `routes/api.php`, `routes/channels.php`, `config/permission.php`, `config/reverb.php`, `config/ai.php`, `config/excel.php`, `config/dompdf.php`. Package yang sudah ada tidak di-install ulang.
2. **Cek keputusan sebelumnya**: jika `AGENTS.md` di root project sudah punya bagian `## Stack Terpilih`, ikuti itu dan **jangan tanya ulang**.
3. **Tanya user sekali** (satu pertanyaan berisi daftar pilihan), lalu **berhenti dan tunggu jawaban**. Jangan menebak dan jangan lanjut install sebelum dijawab.
4. **Install hanya yang dipilih**, lalu catat keputusan ke `AGENTS.md` (lihat 0.3).

Paket inti (dibutuhkan oleh standar ini, tetap diinformasikan ke user sebelum dipasang):

* `install:api` + Sanctum: hanya jika `routes/api.php` belum ada.
* Spatie Laravel Permission: untuk RBAC (1.3.4 dan 1.3.8).

Paket opsional (**hanya dipasang jika user memilih**):

| Kode | Package | Dipakai untuk |
|---|---|---|
| `reverb` | `laravel/reverb` (via `install:broadcasting`) | Realtime: notifikasi, progress, chat, streaming AI |
| `ai` | `laravel/ai` | Fitur AI: ringkasan, klasifikasi, agent, embeddings |
| `excel` | `maatwebsite/excel` | Export/import Excel/CSV |
| `pdf` | `barryvdh/laravel-dompdf` | Export PDF (invoice, laporan, slip) |

Template pertanyaan (sesuaikan isinya dengan yang belum terpasang):

```text
Sebelum saya setup, fitur mana yang dibutuhkan project ini? (boleh pilih lebih dari satu, atau "tidak ada")

Inti (akan dipasang): API + Sanctum, Spatie Permission (RBAC)

Opsional:
1. Realtime / WebSocket (Laravel Reverb)
2. Fitur AI (Laravel AI SDK) - jika ya, provider apa? (OpenAI / Anthropic / Gemini / lainnya)
3. Export/Import Excel (Laravel Excel 4)
4. Export PDF (DomPDF)
```

Cara bertanya per agent:

* Jika agent punya tool pertanyaan interaktif (mis. `AskUserQuestion` di Claude Code, atau fitur ask/confirm bawaan agent lain), gunakan tool itu dengan mode multi-pilih.
* Jika tidak ada, tulis pertanyaan di chat dan akhiri giliran untuk menunggu jawaban.
* Pada mode non-interaktif / otomatis (CI, agent background tanpa user), **jangan install paket opsional**. Pasang inti saja dan laporkan bahwa paket opsional menunggu keputusan user.

Jika user hanya minta review kode atau perubahan kecil, **jangan** menawarkan install apa pun.

### 0.2 Command Wajib Non-Interaktif

Agent tidak bisa menjawab prompt interaktif artisan/composer, jadi semua command wajib memakai flag eksplisit:

```shell
php artisan install:api --no-interaction
php artisan install:broadcasting --reverb --without-node --no-interaction
composer require <package> --no-interaction
php artisan vendor:publish --provider="..." --no-interaction
php artisan migrate --no-interaction
```

### 0.3 Catat Keputusan Stack

Setelah user menjawab, tambahkan (atau perbarui) bagian ini di `AGENTS.md` root project agar sesi/agent berikutnya tidak bertanya ulang:

```markdown
## Stack Terpilih

- Inti: Sanctum, Spatie Permission (teams = company)
- Reverb: ya
- AI SDK: ya (provider: OpenAI)
- Excel: tidak
- PDF: ya
```

Bagian standar untuk package yang **tidak** dipilih (mis. 1.9 Reverb, 1.10 AI, 1.11 Excel/PDF) diabaikan, dan agent tidak membuat file/folder untuk package tersebut.

---

## 1. Tujuan

* Menyeragamkan **penamaan database, model, controller, seeder, dan resource**
* Memudahkan maintenance dan scaling API
* Memisahkan **master data**, **transaksi**, dan **tabel jembatan (detail)** secara jelas
* Menambahkan standar **Soft Deletes**, **audit field (created_by/updated_by/deleted_by)**, dan **Helpers** untuk kode reusable
* Menstandarkan **multi-company (tenant)**, **plan/modul**, dan **RBAC (role/permission)** untuk platform enterprise

---

## 1.0 Target Versi

* **Laravel 13.x** (rilis 17 Maret 2026), **PHP minimal 8.3**.
* Tetap kompatibel dengan **Laravel 12**, tetapi tetap butuh **PHP 8.3+** karena Spatie Permission 8, Laravel AI SDK, dan Laravel Excel 4 mensyaratkan PHP 8.3. Fitur yang khusus Laravel 13 (PHP attributes seperti `#[Table]`, `#[Fillable]`, `#[Middleware]`) diberi catatan fallback-nya.
* Struktur aplikasi mengikuti skeleton Laravel 11+: **tidak ada** `app/Http/Kernel.php` dan `app/Console/Kernel.php`. Middleware, exception handling, dan routing dikonfigurasi di `bootstrap/app.php`; service provider didaftarkan di `bootstrap/providers.php`.

---

## 1.1 Stack (Inti + Opsional)

Backend ini menggunakan Laravel + package berikut. Paket opsional **hanya** dipasang setelah dikonfirmasi user (lihat 0.1).

| Package | Versi | Status | Fungsi |
|---|---|---|---|
| `laravel/sanctum` | ^4 | Inti | API authentication (Bearer token) |
| `spatie/laravel-permission` | ^8 | Inti | RBAC dinamis per company |
| `laravel/reverb` | ^1.12 | Opsional | WebSocket server untuk realtime / broadcasting |
| `laravel/ai` | ^1.3 | Opsional | Laravel AI SDK (agent, structured output, embeddings, dll) |
| `maatwebsite/excel` | ^4.0 | Opsional | Export/import Excel (Laravel Excel 4, PhpSpreadsheet 5) |
| `barryvdh/laravel-dompdf` | ^3.1 | Opsional | Export PDF (DomPDF 3) |

### 1.1.1 Urutan Setup Project Baru

Skeleton Laravel 11+ **tidak** punya `routes/api.php` dan `routes/channels.php`. Jalankan berurutan di root project, **lewati langkah untuk package yang tidak dipilih atau sudah terpasang**:

```shell
# 1. [Inti] API + Sanctum (membuat routes/api.php, prefix /api, middleware group api)
php artisan install:api --no-interaction

# 2. [Inti] Spatie Permission. Set 'teams' => true dan 'team_foreign_key' => 'company_id'
#    di config/permission.php SEBELUM migrate (lihat 1.3.8)
composer require spatie/laravel-permission --no-interaction
php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider" --no-interaction

# 3. [Opsional: reverb] Broadcasting + Reverb (routes/channels.php, config/reverb.php, env REVERB_*)
php artisan install:broadcasting --reverb --without-node --no-interaction

# 4. [Opsional: ai]
composer require laravel/ai --no-interaction
php artisan vendor:publish --provider="Laravel\Ai\AiServiceProvider" --no-interaction

# 5. [Opsional: excel]
composer require maatwebsite/excel --no-interaction
php artisan vendor:publish --provider="Maatwebsite\Excel\ExcelServiceProvider" --tag=config --no-interaction

# 6. [Opsional: pdf]
composer require barryvdh/laravel-dompdf --no-interaction
php artisan vendor:publish --provider="Barryvdh\DomPDF\ServiceProvider" --no-interaction

# 7. Migrasi (termasuk tabel package) + seed katalog permission
php artisan migrate --no-interaction
php artisan db:seed --class="Database\Seeders\Rbac\PermissionSeeder" --no-interaction
```

Jika Reverb dipilih, setelah langkah 3 **wajib** ubah registrasi channel di `bootstrap/app.php` agar client API (token Sanctum) bisa auth ke private channel. Lihat 1.9.2.

Catatan:

* Config package berada di `config/sanctum.php`, `config/permission.php`, `config/reverb.php`, `config/ai.php`, `config/excel.php`, dan `config/dompdf.php`.
* Tabel bawaan package (`personal_access_tokens`, `roles`, `permissions`, `model_has_*`, `role_has_permissions`, `agent_conversations`, `agent_conversation_messages`, `jobs`, `cache`, dst) **dikecualikan** dari aturan prefix `m_` / `t_` dan kolom audit. Jangan rename tabel package.

---

## 1.2 Konsep Platform “All-In Enterprise”

CORE PLATFORM

* HRIS
* Productivity & KPI
* Task & Project Management
* Portal Client
* Finance
* Analytics & Reporting

Prinsip implementasi:

* **Multi-company (tenant)**: setiap request harus “punya konteks company”
* **Paket/Plan (Basic/Pro/Enterprise)** menentukan modul yang aktif untuk company
* **RBAC** menentukan user boleh akses apa di dalam company (berdasarkan jabatan/role)

---

## 1.3 Konvensi Routing API (Auth + Multi-Tenant + Module + Permission)

### 1.3.1 Authentication (Sanctum)

Endpoint:

* `POST /api/auth/login`
* `GET /api/auth/me` (auth)
* `POST /api/auth/logout` (auth)

Response login mengembalikan token:

* Header request berikutnya: `Authorization: Bearer <token>`

### 1.3.2 Multi-Tenant Context

Setiap endpoint bisnis wajib berjalan dalam konteks tenant aktif.

Standar implementasi:

* Tenant context ditentukan oleh mekanisme yang disepakati project (contoh: subdomain, header, atau relasi user-tenant).
* Semua query data bisnis wajib ter-scope ke tenant aktif.
* Endpoint lintas tenant tanpa otorisasi eksplisit tidak diperbolehkan.

Middleware:

* Gunakan middleware tenant sesuai implementasi project (contoh: `tenant`).
* Semua alias middleware custom (`tenant`, `module`) dan Spatie (`permission`, `role`) **wajib** didaftarkan di `bootstrap/app.php` (lihat 1.3.7).

### 1.3.3 Module Gating (Plan/Entitlement)

Setiap modul di-gate dengan middleware:

* `module:<moduleKey>` (contoh `module:hris`, `module:finance`)

Jika modul tidak aktif untuk company, API mengembalikan **403** dengan format macro (lewat handler di 1.3.7).

Urutan middleware **wajib**: `auth:sanctum` → `tenant` → `module:<key>` → `permission:<key>`. Middleware `module` dan `permission` butuh company aktif yang diset oleh `tenant`, jadi tidak boleh dipasang sebelum `tenant`. Dengan urutan ini, client selalu menerima alasan yang paling mendasar dulu (401 sebelum 403 tenant, 403 tenant sebelum 403 modul, dst).

Contoh implementasi (tabel `t_company_module_det` berisi `company_id`, `module_key`, `is_active`; sesuaikan dengan model plan/entitlement project):

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureModuleIsActive
{
    /**
     * Pemakaian di route: ->middleware('module:hris')
     * Wajib dipasang SETELAH middleware tenant (butuh company aktif).
     */
    public function handle(Request $request, Closure $next, string $module): Response
    {
        $company = $request->attributes->get('company');

        if (! $company?->hasActiveModule($module)) {
            abort(403, "Modul {$module} tidak aktif untuk paket company {$company?->nama}. Hubungi admin company untuk mengaktifkan atau upgrade paket");
        }

        return $next($request);
    }
}
```

```php
// Model company
public function hasActiveModule(string $module): bool
{
    return DB::table('t_company_module_det')
        ->where('company_id', $this->id)
        ->where('module_key', $module)
        ->where('is_active', true)
        ->exists();
}
```

Middleware custom **wajib** menolak dengan `abort($status, 'pesan')` (atau return response macro), jangan `return response()->json([...])` manual, agar format error tetap seragam.

### 1.3.4 Permission Check (RBAC)

RBAC pada project Laravel ini menggunakan package **Spatie Laravel Permission (v8)**. v8 membutuhkan PHP 8.3+ dan Laravel 12/13.

Referensi:

* https://spatie.be/docs/laravel-permission/v8/introduction

Upgrade dari versi lama:

* v6 → v7: event dan command class mendapat suffix (`RoleAttachedEvent`, `CacheResetCommand`, dst), `clearClassPermissions()` dihapus (ganti `clearPermissionsCollection()`), `assignRole()` / `givePermissionTo()` kini return `static`.
* v7 → v8: `findByName()` dan `findOrCreate()` menerima `BackedEnum|string`; sesuaikan signature jika punya model Role/Permission custom.

Permission check per endpoint:

* `permission:<permissionKey>` (contoh `permission:hris.employee.view`)

Catatan:

* Jika membership `is_owner = true` maka bypass permission.
* Assign role/permission mengikuti pola Spatie (`assignRole`, `givePermissionTo`).
* Permission check gunakan kemampuan native Laravel/Gate yang terintegrasi (`can`) sesuai integrasi Spatie.
* Role dibuat per company, jadi fitur **teams** Spatie **wajib** aktif dengan `company_id` sebagai team key. Detail lengkap, termasuk role dinamis yang dibuat user, ada di 1.3.8.
* Permission key boleh berupa string atau `BackedEnum` (v8), contoh enum `Permission::HrisEmployeeView`.

### 1.3.5 Grouping API V1 per Modul

Standar grouping:

* `/api/v1/hris/...`
* `/api/v1/tasks/...`
* `/api/v1/kpi/...`
* `/api/v1/projects/...`
* `/api/v1/client-portal/...`
* `/api/v1/finance/...`
* `/api/v1/analytics/...`

Semua route di atas minimal:

* `auth:sanctum`
* `tenant` (atau middleware tenant yang setara di project)
* `module:<moduleKey>`
* `permission:<permissionKey>` (sesuai endpoint)

### 1.3.6 Versioning API (v1 / v2 / v3)

Untuk Laravel API, versioning endpoint **wajib** disiapkan agar backward compatibility aman saat ada perubahan besar.

Aturan utama:

* Semua endpoint harus menggunakan prefix versi:
  * `/api/v1/...`
  * `/api/v2/...`
  * `/api/v3/...`
* Versi baru dibuat jika ada **breaking changes**, contoh:
  * perubahan struktur response yang memutus integrasi client lama
  * perubahan kontrak request (field wajib berubah signifikan)
  * perubahan alur bisnis yang tidak kompatibel dengan versi sebelumnya
* Jika perubahan hanya additive (misalnya tambah field optional), tetap di versi yang sama.

Prinsip kompatibilitas:

* Endpoint lama tetap aktif selama masa transisi.
* Jangan menghapus `v1` langsung saat rilis `v2`.
* Dokumentasikan status versi:
  * `active` (digunakan)
  * `deprecated` (masih hidup, akan dipensiunkan)
  * `sunset` (ditutup pada tanggal tertentu)

Contoh grouping route per versi (Laravel):

```php
Route::prefix('v1')->middleware(['auth:sanctum', 'tenant'])->group(function () {
    Route::prefix('hris')->middleware(['module:hris'])->group(function () {
        // endpoint v1
    });
});

Route::prefix('v2')->middleware(['auth:sanctum', 'tenant'])->group(function () {
    Route::prefix('hris')->middleware(['module:hris'])->group(function () {
        // endpoint v2 (jika ada breaking change)
    });
});
```

### 1.3.7 Registrasi Middleware & Exception (bootstrap/app.php)

Laravel 11+ tidak lagi memakai `app/Http/Kernel.php`. Alias middleware dan rendering exception API **wajib** dikonfigurasi di `bootstrap/app.php`:

```php
<?php

use App\Helpers\ApiErrorHelpers;
use App\Http\Middleware\EnsureModuleIsActive;
use App\Http\Middleware\SetTenantContext;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Spatie\Permission\Exceptions\UnauthorizedException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'tenant' => SetTenantContext::class,
            'module' => EnsureModuleIsActive::class,
            'role' => \Spatie\Permission\Middleware\RoleMiddleware::class,
            'permission' => \Spatie\Permission\Middleware\PermissionMiddleware::class,
            'role_or_permission' => \Spatie\Permission\Middleware\RoleOrPermissionMiddleware::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        // Semua route API selalu dirender sebagai JSON
        $exceptions->shouldRenderJsonWhen(
            fn (Request $request) => $request->is('api/*') || $request->expectsJson()
        );

        // Kode referensi error ikut tercatat di log, sama dengan yang dikirim ke client
        $exceptions->context(fn () => ['error_ref' => ApiErrorHelpers::reference()]);

        // Urutan penting: callback pertama yang cocok & mengembalikan response yang dipakai.

        // 1. 401: token tidak dikirim / tidak valid / kedaluwarsa
        $exceptions->render(function (AuthenticationException $e, Request $request) {
            if ($request->is('api/*')) {
                $message = ApiErrorHelpers::unauthenticated($e, $request);

                return response()->unauthorized([$message], $message);
            }
        });

        // 2. 403 dari middleware permission Spatie, sebutkan izin yang dibutuhkan
        $exceptions->render(function (UnauthorizedException $e, Request $request) {
            if ($request->is('api/*')) {
                $message = ApiErrorHelpers::permissionDenied($e);

                return response()->forbidden([$message], $message);
            }
        });

        // 3. Semua HTTP error lain: abort() dari middleware/controller, policy, 404, 405, 409, 429, 503, dst
        $exceptions->render(function (HttpExceptionInterface $e, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            $status = $e->getStatusCode();
            $message = ApiErrorHelpers::fromHttpException($e, $request);
            $args = [[$message], $message];

            $response = match ($status) {
                400 => response()->badRequest(...$args),
                401 => response()->unauthorized(...$args),
                403 => response()->forbidden(...$args),
                404 => response()->notFound(...$args),
                405 => response()->methodNotAllowed(...$args),
                409 => response()->conflict(...$args),
                429 => response()->tooManyRequests(...$args),
                503 => response()->serviceUnavailable(...$args),
                default => response()->failed([$message], $message, $status),
            };

            // Pertahankan header seperti Retry-After (429) dan Allow (405)
            return $response->withHeaders($e->getHeaders());
        });

        // 4. Fallback 500: pesan aman + kode referensi untuk dilacak di log
        $exceptions->render(function (Throwable $e, Request $request) {
            if (! $request->is('api/*') || $e instanceof ValidationException || $e instanceof HttpResponseException) {
                return null; // 422 tetap format default Laravel
            }

            $ref = ApiErrorHelpers::reference();
            $message = "Terjadi kesalahan pada server saat memproses {$request->method()} /{$request->path()}. Kode referensi: {$ref}. Laporkan kode ini ke tim IT";

            return response()->internalServerError(
                [$message],
                $message,
                array_filter([
                    'error_ref' => $ref,
                    'debug' => config('app.debug') ? ['exception' => $e::class, 'detail' => $e->getMessage(), 'file' => $e->getFile().':'.$e->getLine()] : null,
                ]),
            );
        });
    })
    ->create();
```

Catatan:

* **Semua error dari middleware dan controller keluar dengan format macro yang sama**, termasuk `abort(403, '...')`, 403 dari policy/Gate, `module:`, `tenant`, `permission:`, `throttle:`, 404, 405, 409, 503 (maintenance mode), dan 500.
* `ModelNotFoundException` (dari `findOrFail`) dan `AuthorizationException` (dari policy) otomatis dikonversi Laravel menjadi `HttpException` 404/403 sebelum callback dijalankan, jadi ikut tertangkap handler nomor 3. Controller **tidak perlu** `try/catch` hanya untuk 404/403.
* Pesan disusun oleh `ApiErrorHelpers` (lihat 1.5.1): spesifik tetapi aman. Pesan bawaan framework yang membocorkan namespace (`No query results for model [App\Models\...]`) diganti `Data Kategori dengan ID 999 tidak ditemukan`. Status lain meneruskan pesan dari `abort($status, 'pesan')`.
* Header bawaan tetap dikirim (`Retry-After` untuk 429, `Allow` untuk 405), supaya frontend tahu kapan boleh retry.
* Error 500 tidak pernah membocorkan detail (SQL, path) di production. Client menerima **kode referensi** (`settings.error_ref`) yang sama dengan yang tercatat di log (via `$exceptions->context`), sehingga tim IT bisa langsung mencari error-nya. Detail exception hanya muncul di `settings.debug` saat `APP_DEBUG=true`.
* `ValidationException` tetap memakai format default Laravel (lihat 1.4), tidak dipetakan ke macro.
* **Urutan callback penting**: Laravel memakai callback pertama yang cocok dan mengembalikan response. Callback spesifik (`AuthenticationException`, Spatie `UnauthorizedException`) wajib di atas `HttpExceptionInterface`, dan `Throwable` wajib paling bawah.

Peta error API (contoh `message` yang diterima frontend):

| Sumber | Status | Contoh `message` |
|---|---|---|
| Header token tidak dikirim (`auth:sanctum`) | 401 | `Token tidak ditemukan. Sertakan header Authorization: Bearer <token>` |
| Token salah / expired (`auth:sanctum`) | 401 | `Token tidak valid atau sudah kedaluwarsa. Silakan login ulang` |
| Header company tidak dikirim (`tenant`) | 400 | `Header X-Company-Id wajib dikirim untuk menentukan company aktif` |
| Bukan anggota company (`tenant`) | 403 | `Anda bukan anggota company dengan ID 99. Pilih company yang terdaftar di akun Anda` |
| Modul tidak aktif (`module:`) | 403 | `Modul hris tidak aktif untuk paket company ACME. Hubungi admin company untuk mengaktifkan atau upgrade paket` |
| Tidak punya permission (`permission:`) | 403 | `Anda tidak memiliki izin untuk aksi ini. Izin yang dibutuhkan: hris.employee.create` |
| Policy / `abort(403, ...)` | 403 | pesan spesifik dari kode |
| Data tidak ada (`findOrFail`, route model binding) | 404 | `Data Kategori dengan ID 999 tidak ditemukan` |
| Endpoint tidak ada | 404 | `Endpoint GET /api/v1/tidak-ada tidak ditemukan` |
| Method salah | 405 | `Method POST tidak didukung untuk endpoint /api/v1/kategori/1. Method yang didukung: GET, HEAD` |
| Konflik bisnis | 409 | `Role "Staff HR" tidak bisa dihapus karena masih dipakai` |
| Validasi gagal | 422 | format default Laravel, pesan per field berbahasa Indonesia (1.4) |
| Rate limit (`throttle:`) | 429 | `Terlalu banyak request. Coba lagi dalam 42 detik` + header `Retry-After` |
| Maintenance (`php artisan down`) | 503 | `Sistem sedang dalam pemeliharaan. Coba lagi beberapa saat lagi` |
| Exception tak tertangani | 500 | `Terjadi kesalahan pada server saat memproses GET /api/v1/x. Kode referensi: <uuid>. Laporkan kode ini ke tim IT` |

Test wajib (`tests/Feature/ErrorFormatTest.php`): tiap baris tabel di atas mengembalikan struktur `status_code`, `message`, `errors`, `settings` dengan status **dan pesan** yang benar, `Retry-After` ada di 429, dan 500 tidak mengandung detail exception saat `APP_DEBUG=false` tetapi kode referensinya ada di log.
* Laravel 13: middleware juga boleh dideklarasikan di controller memakai attribute `#[Middleware('permission:hris.employee.view', only: ['index'])]` (`Illuminate\Routing\Attributes\Controllers\Middleware`). Untuk Laravel 12 gunakan interface `HasMiddleware` + static `middleware()`. Pilih **satu** pola per project (route-level atau controller-level), jangan dicampur.

Rekomendasi struktur controller/resource per versi:

* Controller:
  * `App\Http\Controllers\Api\V1\...`
  * `App\Http\Controllers\Api\V2\...`
* Resource:
  * `App\Http\Resources\Api\V1\...`
  * `App\Http\Resources\Api\V2\...`

Tujuan:

* Client lama tetap jalan.
* Pengembangan fitur baru lebih aman.
* Migrasi antar versi lebih terkontrol.

### 1.3.8 RBAC Dinamis: Role Dibuat User, Permission Berbeda per Role

Kebutuhan: admin/owner company bisa **membuat role sendiri** (mis. "Staff HR", "Manager HR", "Finance Viewer") lalu memilih **permission yang berbeda-beda untuk tiap role**, dan meng-assign role ke user. Role milik satu company tidak terlihat dan tidak bisa dipakai company lain.

Prinsip:

* **Permission didefinisikan di kode** (katalog enum + seeder), tidak bisa dibuat lewat API. Middleware route mengacu ke nama permission ini, jadi permission buatan user tidak akan pernah dicek oleh kode mana pun.
* **Role dibuat user lewat API**, per company, dan isinya dipilih dari katalog permission.
* Satu user boleh punya beberapa role; permission efektif = gabungan permission dari semua role-nya.
* Format nama permission: `<modul>.<resource>.<aksi>`, contoh `hris.employee.view`, `finance.invoice.approve`.
* Owner company (`is_owner = true` di tabel membership) bypass semua permission lewat `Gate::before`.
* **Anti privilege escalation**: user non-owner hanya boleh memberikan permission yang dia sendiri punya, baik saat menyusun role maupun saat meng-assign role ke user.
* Role yang masih dipakai user tidak boleh dihapus (409 Conflict).
* Semua permission memakai `guard_name = 'web'` (default Spatie). Spatie membaca guard dari model User, sehingga tetap jalan untuk request `auth:sanctum`. **Jangan** membuat permission dengan guard `sanctum`.

#### Konfigurasi Spatie (sebelum `migrate` pertama)

Di `config/permission.php`:

```php
'column_names' => [
    // ...
    'team_foreign_key' => 'company_id',
],

'teams' => true,
```

Jika migration Spatie sudah terlanjur dijalankan tanpa teams, buat migration baru untuk menambahkan kolom `company_id` ke tabel `roles`, `model_has_roles`, dan `model_has_permissions` (lihat dokumentasi teams Spatie). Jangan edit migration lama yang sudah jalan di production.

#### Middleware tenant (contoh)

Middleware `tenant` wajib menentukan company aktif, memastikan user anggota company tersebut, lalu meng-scope Spatie ke company itu. Contoh di bawah memakai header `X-Company-Id` dan tabel membership `t_company_user_det` (kolom `company_id`, `user_id`, `is_owner`); sesuaikan dengan mekanisme tenant project.

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SetTenantContext
{
    public function handle(Request $request, Closure $next): Response
    {
        $companyId = $request->header('X-Company-Id');

        if (! $companyId) {
            abort(400, 'Header X-Company-Id wajib dikirim untuk menentukan company aktif');
        }

        $company = $request->user()?->companies()->whereKey((int) $companyId)->first();

        if (! $company) {
            abort(403, "Anda bukan anggota company dengan ID {$companyId}. Pilih company yang terdaftar di akun Anda");
        }

        // Simpan konteks tenant untuk request ini
        $request->attributes->set('company', $company);

        // Scope role/permission Spatie ke company aktif
        setPermissionsTeamId($company->id);
        $request->user()->unsetRelation('roles')->unsetRelation('permissions');

        return $next($request);
    }
}
```

Relasi membership yang dipakai (di model user dan company):

```php
// Model user
public function companies(): BelongsToMany
{
    return $this->belongsToMany(CompanyModel::class, 't_company_user_det', 'user_id', 'company_id')->withPivot('is_owner');
}

// Model company
public function users(): BelongsToMany
{
    return $this->belongsToMany(UserModel::class, 't_company_user_det', 'company_id', 'user_id')->withPivot('is_owner');
}
```

Owner bypass di `AppServiceProvider::boot()`:

```php
use App\Helpers\RbacHelpers;
use Illuminate\Support\Facades\Gate;

Gate::before(function ($user, string $ability) {
    return RbacHelpers::isOwner(request()) ? true : null;
});
```

#### Katalog permission (enum + seeder)

Setiap modul baru wajib menambahkan permission-nya ke enum ini, lalu seeder dijalankan ulang (idempotent, aman di-deploy berkali-kali).

```php
<?php

namespace App\Enums;

/**
 * Katalog permission. Permission didefinisikan di kode (bukan dibuat user),
 * user hanya menyusun role dari permission yang ada di sini.
 * Format: <modul>.<resource>.<aksi>
 */
enum PermissionEnum: string
{
    // RBAC
    case RbacRoleView = 'rbac.role.view';
    case RbacRoleManage = 'rbac.role.manage';
    case RbacUserAssign = 'rbac.user.assign';

    // HRIS
    case HrisEmployeeView = 'hris.employee.view';
    case HrisEmployeeCreate = 'hris.employee.create';
    case HrisEmployeeUpdate = 'hris.employee.update';
    case HrisEmployeeDelete = 'hris.employee.delete';

    public function module(): string
    {
        return explode('.', $this->value)[0];
    }
}
```

```php
<?php

namespace Database\Seeders\Rbac;

use App\Enums\PermissionEnum;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\PermissionRegistrar;

class PermissionSeeder extends Seeder
{
    public function run(): void
    {
        foreach (PermissionEnum::cases() as $permission) {
            Permission::findOrCreate($permission->value, 'web');
        }

        app(PermissionRegistrar::class)->forgetCachedPermissions();
    }
}
```

#### Helpers RBAC

```php
<?php

namespace App\Helpers;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Spatie\Permission\Models\Role;

class RbacHelpers
{
    /**
     * Query role milik company aktif saja.
     */
    public static function companyRoles(): Builder
    {
        return Role::query()->where(config('permission.column_names.team_foreign_key'), getPermissionsTeamId());
    }

    public static function isOwner(Request $request): bool
    {
        return (bool) $request->attributes->get('company')?->pivot?->is_owner;
    }

    /**
     * Permission yang diminta tapi tidak dimiliki user (anti privilege escalation).
     * Owner boleh memberikan semua permission.
     */
    public static function permissionsBeyondUser(Request $request, Collection|array $permissionNames): Collection
    {
        if (self::isOwner($request)) {
            return collect();
        }

        $owned = $request->user()->getAllPermissions()->pluck('name');

        return collect($permissionNames)->diff($owned)->values();
    }
}
```

#### Form Request

```php
<?php

namespace App\Http\Requests\Rbac;

use App\Helpers\RbacHelpers;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class RoleStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $teamKey = config('permission.column_names.team_foreign_key');

        return [
            'name' => [
                'required', 'string', 'max:100',
                Rule::unique('roles', 'name')
                    ->where($teamKey, getPermissionsTeamId())
                    ->where('guard_name', 'web')
                    ->ignore($this->route('id')),
            ],
            'permissions' => ['required', 'array', 'min:1'],
            'permissions.*' => ['string', 'distinct', Rule::exists('permissions', 'name')->where('guard_name', 'web')],
        ];
    }

    public function attributes(): array
    {
        return [
            'name' => 'nama role',
            'permissions' => 'daftar permission',
            'permissions.*' => 'permission',
        ];
    }

    public function messages(): array
    {
        return [
            'name.required' => 'Nama role wajib diisi',
            'name.max' => 'Nama role maksimal :max karakter',
            'name.unique' => 'Role dengan nama ":input" sudah ada di company ini. Gunakan nama lain',
            'permissions.required' => 'Pilih minimal satu permission untuk role ini',
            'permissions.min' => 'Pilih minimal satu permission untuk role ini',
            'permissions.*.exists' => 'Permission ":input" tidak terdaftar di katalog permission',
            'permissions.*.distinct' => 'Permission ":input" dipilih lebih dari sekali',
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator) {
                $beyond = RbacHelpers::permissionsBeyondUser($this, $this->input('permissions', []));

                if ($beyond->isNotEmpty()) {
                    $validator->errors()->add('permissions', 'Anda tidak bisa memberikan permission yang tidak Anda miliki: '.$beyond->implode(', '));
                }
            },
        ];
    }
}
```

```php
<?php

namespace App\Http\Requests\Rbac;

class RoleUpdateRequest extends RoleStoreRequest
{
}
```

```php
<?php

namespace App\Http\Requests\Rbac;

use App\Helpers\RbacHelpers;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UserRoleSyncRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $teamKey = config('permission.column_names.team_foreign_key');

        return [
            'roles' => ['present', 'array'],
            'roles.*' => ['integer', 'distinct', Rule::exists('roles', 'id')->where($teamKey, getPermissionsTeamId())],
        ];
    }

    public function messages(): array
    {
        return [
            'roles.present' => 'Field roles wajib dikirim (kirim [] untuk melepas semua role)',
            'roles.*.exists' => 'Role dengan ID :input tidak ditemukan di company ini',
            'roles.*.distinct' => 'Role dengan ID :input dipilih lebih dari sekali',
        ];
    }

    public function after(): array
    {
        return [
            function (Validator $validator) {
                if ($validator->errors()->isNotEmpty()) {
                    return;
                }

                $permissions = RbacHelpers::companyRoles()
                    ->whereKey($this->input('roles', []))
                    ->with('permissions')
                    ->get()
                    ->flatMap(fn ($role) => $role->permissions->pluck('name'))
                    ->unique();

                $beyond = RbacHelpers::permissionsBeyondUser($this, $permissions);

                if ($beyond->isNotEmpty()) {
                    $validator->errors()->add('roles', 'Role berisi permission yang tidak Anda miliki: '.$beyond->implode(', '));
                }
            },
        ];
    }
}
```

#### Resource & Controller

```php
<?php

namespace App\Http\Resources\Api\V1\Rbac;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RoleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'permissions' => $this->permissions->pluck('name')->sort()->values(),
        ];
    }
}
```

```php
<?php

namespace App\Http\Controllers\Api\V1\Rbac;

use App\Http\Controllers\Controller;
use Illuminate\Support\Str;
use Spatie\Permission\Models\Permission;

class PermissionController extends Controller
{
    /**
     * Daftar permission yang bisa dipilih saat menyusun role, dikelompokkan per modul.
     */
    public function index()
    {
        $grouped = Permission::query()
            ->where('guard_name', 'web')
            ->orderBy('name')
            ->pluck('name')
            ->groupBy(fn (string $name) => Str::before($name, '.'));

        return response()->success($grouped, 'Daftar permission');
    }
}
```

```php
<?php

namespace App\Http\Controllers\Api\V1\Rbac;

use App\Helpers\RbacHelpers;
use App\Http\Controllers\Controller;
use App\Http\Requests\Rbac\RoleStoreRequest;
use App\Http\Requests\Rbac\RoleUpdateRequest;
use App\Http\Resources\Api\V1\Rbac\RoleResource;
use Illuminate\Support\Facades\DB;
use Spatie\Permission\Models\Role;

class RoleController extends Controller
{
    public function index()
    {
        $roles = RbacHelpers::companyRoles()->with('permissions')->orderBy('name')->get();

        return response()->success(RoleResource::collection($roles), 'Daftar role');
    }

    public function show(string $id)
    {
        $role = RbacHelpers::companyRoles()->with('permissions')->findOrFail($id);

        return response()->success(new RoleResource($role), 'Detail role');
    }

    public function store(RoleStoreRequest $request)
    {
        $data = $request->validated();

        $role = DB::transaction(function () use ($data) {
            $role = Role::create(['name' => $data['name'], 'guard_name' => 'web']); // company_id otomatis dari team aktif
            $role->syncPermissions($data['permissions']);

            return $role;
        });

        return response()->created(new RoleResource($role->load('permissions')), 'Role berhasil dibuat');
    }

    public function update(RoleUpdateRequest $request, string $id)
    {
        $role = RbacHelpers::companyRoles()->findOrFail($id);
        $data = $request->validated();

        DB::transaction(function () use ($role, $data) {
            $role->update(['name' => $data['name']]);
            $role->syncPermissions($data['permissions']);
        });

        return response()->success(new RoleResource($role->load('permissions')), 'Role berhasil diubah');
    }

    public function destroy(string $id)
    {
        $role = RbacHelpers::companyRoles()->findOrFail($id);

        $usedBy = $role->users()->count();

        if ($usedBy > 0) {
            return response()->conflict(
                ["Role \"{$role->name}\" masih dipakai oleh {$usedBy} user. Lepas role ini dari user tersebut sebelum menghapus"],
                "Role \"{$role->name}\" tidak bisa dihapus karena masih dipakai",
            );
        }

        $role->delete();

        return response()->success([], "Role \"{$role->name}\" berhasil dihapus");
    }
}
```

```php
<?php

namespace App\Http\Controllers\Api\V1\Rbac;

use App\Helpers\RbacHelpers;
use App\Http\Controllers\Controller;
use App\Http\Requests\Rbac\UserRoleSyncRequest;
use App\Http\Resources\Api\V1\Rbac\RoleResource;

class UserRoleController extends Controller
{
    /**
     * Ganti seluruh role user di company aktif (sync).
     */
    public function update(UserRoleSyncRequest $request, string $userId)
    {
        $user = $request->attributes->get('company')->users()->findOrFail($userId); // hanya anggota company aktif

        $roles = RbacHelpers::companyRoles()->whereKey($request->validated('roles'))->get();
        $user->syncRoles($roles);

        return response()->success(RoleResource::collection($user->roles()->with('permissions')->get()), 'Role user berhasil diperbarui');
    }
}
```

#### Routes

```php
<?php

use App\Http\Controllers\Api\V1\Rbac\PermissionController;
use App\Http\Controllers\Api\V1\Rbac\RoleController;
use App\Http\Controllers\Api\V1\Rbac\UserRoleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->middleware(['auth:sanctum', 'tenant'])->group(function () {
    Route::prefix('rbac')->group(function () {
        Route::get('permissions', [PermissionController::class, 'index'])->middleware('permission:rbac.role.view');
        Route::get('roles', [RoleController::class, 'index'])->middleware('permission:rbac.role.view');
        Route::get('roles/{id}', [RoleController::class, 'show'])->middleware('permission:rbac.role.view');
        Route::post('roles', [RoleController::class, 'store'])->middleware('permission:rbac.role.manage');
        Route::put('roles/{id}', [RoleController::class, 'update'])->middleware('permission:rbac.role.manage');
        Route::delete('roles/{id}', [RoleController::class, 'destroy'])->middleware('permission:rbac.role.manage');
        Route::put('users/{userId}/roles', [UserRoleController::class, 'update'])->middleware('permission:rbac.user.assign');
    });
});
```

Kontrak endpoint:

| Method | Endpoint | Permission | Body |
|---|---|---|---|
| GET | `/api/v1/rbac/permissions` | `rbac.role.view` | - |
| GET | `/api/v1/rbac/roles` | `rbac.role.view` | - |
| GET | `/api/v1/rbac/roles/{id}` | `rbac.role.view` | - |
| POST | `/api/v1/rbac/roles` | `rbac.role.manage` | `{"name": "Staff HR", "permissions": ["hris.employee.view"]}` |
| PUT | `/api/v1/rbac/roles/{id}` | `rbac.role.manage` | sama dengan POST (permission di-sync penuh) |
| DELETE | `/api/v1/rbac/roles/{id}` | `rbac.role.manage` | - (409 jika role masih dipakai) |
| PUT | `/api/v1/rbac/users/{userId}/roles` | `rbac.user.assign` | `{"roles": [3, 5]}` (sync penuh, `[]` untuk melepas semua) |

Semua request wajib header `Authorization: Bearer <token>` dan `X-Company-Id: <id>` (atau mekanisme tenant project).

Checklist test RBAC (wajib ada di `tests/Feature/Rbac/`):

* Dua role dengan permission berbeda: user A (role 1) hanya bisa view, user B (role 2) bisa view + create.
* Mengubah permission role langsung berlaku untuk user yang memegang role itu.
* Role company A tidak bisa dilihat/diubah/di-assign dari company B (404/422), nama role sama boleh di company berbeda, duplikat di company sama ditolak (422).
* User non-owner tidak bisa memberi permission yang tidak dia punya (422).
* Permission di luar katalog ditolak (422).
* Role yang masih dipakai tidak bisa dihapus (409).
* 403 dari middleware `permission:` memakai format response macro.

---

## 1.4 Standar Validation (Form Request Wajib)

Semua validasi input API **wajib** menggunakan **Form Request**, bukan validasi manual di Controller.

Aturan:

* Generate request class dengan Artisan:
  * `php artisan make:request PostStoreRequest`
  * `php artisan make:request PostUpdateRequest`
* Simpan pada folder:
  * `app/Http/Requests/<Fitur>/`
* Penamaan class:
  * `[NamaFitur]StoreRequest`
  * `[NamaFitur]UpdateRequest`
  * (Opsional) `[NamaFitur]IndexRequest` jika endpoint list memiliki filter kompleks

Implementasi:

* Method `authorize()`:
  * Default `return true;` jika authorization sudah ditangani middleware (`auth:sanctum`, `tenant`, `permission`)
* Method `rules()`:
  * Semua rule validasi didefinisikan di sini (required, string, max, exists, unique, array, dst)
* Method `messages()` (opsional):
  * Digunakan untuk custom pesan validasi agar konsisten
* Method `prepareForValidation()` (opsional):
  * Digunakan untuk normalisasi data sebelum validasi (trim, cast, mapping key, dst)
* Laravel 13 (opsional): attribute `#[StopOnFirstFailure]` (`Illuminate\Foundation\Http\Attributes\StopOnFirstFailure`) menggantikan property `$stopOnFirstFailure`.

Penggunaan di Controller (wajib):

* Injeksi Request class di method controller, contoh:
  * `store(PostStoreRequest $request)`
  * `update(PostUpdateRequest $request, $id)`
* Ambil payload tervalidasi hanya dari:
  * `$request->validated()`
* Dilarang memakai:
  * `$request->all()` untuk proses simpan/update data
  * `Validator::make(...)` manual di controller (kecuali kebutuhan khusus yang terdokumentasi)

Standar response error validasi:

* Jika validasi gagal, response harus **422 Unprocessable Entity** dengan format default Laravel. `message` berisi pesan error pertama (+ jumlah error lain), dan key nested memakai dot notation:

```json
{
  "message": "The nama field is required. (and 1 more error)",
  "errors": {
    "nama": [
      "The nama field is required."
    ],
    "items.0.qty": [
      "The items.0.qty field must be at least 1."
    ]
  }
}
```

* Format ini otomatis keluar jika request API meminta JSON (header `Accept: application/json`, atau route `api/*` dengan `shouldRenderJsonWhen` di 1.3.7).

---

## 1.5 Standar Response API (Response Macro Provider Wajib)

Semua response API pada controller **wajib** menggunakan macro response terstandar dari provider.

Aturan:

* Wajib membuat provider dengan nama file:
  * `app/Providers/ResponseMacroServiceProvider.php`
* Saat implementasi endpoint:
  * Jika file `app/Providers/ResponseMacroServiceProvider.php` **belum ada**, wajib langsung buat file tersebut dengan isi macro standar berikut: `success`, `failed`, `successWithPagination`, `created`, `badRequest`, `unauthorized`, `forbidden`, `notFound`, `methodNotAllowed`, `conflict`, `unprocessableEntity`, `tooManyRequests`, `internalServerError`, `serviceUnavailable`.
  * Jika file `app/Providers/ResponseMacroServiceProvider.php` **sudah ada**, wajib gunakan provider yang ada di project (tidak membuat duplikat provider baru).
* Isi provider mengikuti standar macro berikut:
  * `success`
  * `failed`
  * `successWithPagination`
  * `created`
  * `badRequest`
  * `unauthorized`
  * `forbidden`
  * `notFound`
  * `methodNotAllowed`
  * `conflict`
  * `unprocessableEntity`
  * `tooManyRequests`
  * `internalServerError`
  * `serviceUnavailable`
* Provider wajib terdaftar pada aplikasi Laravel agar macro bisa dipanggil melalui `response()->...`.
* Laravel 11+ (termasuk 12 dan 13):
  * Wajib daftarkan `\App\Providers\ResponseMacroServiceProvider::class` di file `bootstrap/providers.php`.
  * `php artisan make:provider ResponseMacroServiceProvider` otomatis menambahkannya ke `bootstrap/providers.php`; jika file dibuat manual, tambahkan sendiri.
  * Tanpa registrasi ini, macro `response()->success(...)` dan macro lainnya tidak akan aktif.

Contoh `bootstrap/providers.php` (Laravel 11+):

```php
<?php

return [
    \App\Providers\AppServiceProvider::class,
    \App\Providers\ResponseMacroServiceProvider::class,
];
```

Penggunaan di Controller (wajib):

* Seluruh endpoint harus mengembalikan response melalui macro provider, bukan format JSON manual.
* Gunakan pola:
  * `response()->success(...)` untuk sukses ambil data
  * `response()->created(...)` untuk create
  * `response()->notFound(...)` untuk data tidak ditemukan
  * `response()->unprocessableEntity(...)` untuk validasi gagal (jika diperlukan custom handling)
  * `response()->internalServerError(...)` untuk error server
* Jangan membungkus seluruh method dengan `catch (\Exception $e)` lalu mengembalikan 404. Itu menyamarkan error server (500) sebagai "not found". Biarkan `findOrFail` melempar exception; mapping ke `response()->notFound()` ditangani global di `bootstrap/app.php` (1.3.7). Gunakan `try/catch` hanya untuk exception spesifik yang memang perlu respons berbeda.

Contoh implementasi controller:

```php
public function show(string $id)
{
    $pendaftaran = PendaftaranModel::with(['peserta', 'merchandise.merchandise', 'kategoriLomba'])
        ->findOrFail($id); // 404 otomatis via handler global

    return response()->success(
        new PendaftaranResource($pendaftaran),
        'Data pendaftaran berhasil diambil'
    );
}
```

Catatan Laravel 13: framework kini punya JSON:API resources bawaan. Project ini **tidak** memakainya; format response tetap mengikuti macro di bawah agar kontrak dengan frontend tidak berubah.

Template wajib `app/Providers/ResponseMacroServiceProvider.php` (gunakan isi ini secara konsisten, jangan diimprovisasi/random):

```php
<?php

namespace App\Providers;

use Illuminate\Support\Facades\Response;
use Illuminate\Support\ServiceProvider;

class ResponseMacroServiceProvider extends ServiceProvider
{
    /**
     * Register services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap services.
     */
    public function boot(): void
    {
        Response::macro('success', function ($data = [], $message = '', $settings = []) {
            return Response::make([
                'status_code' => 200,
                'data' => $data,
                'message' => $message,
                'settings' => $settings,
            ], 200);
        });

        Response::macro('failed', function ($error = [], $messageOrCode = 422, $code = 422, $settings = []) {
            $message = '';
            $httpCode = 422;

            if (is_int($messageOrCode)) {
                $httpCode = $messageOrCode;
            } else {
                $message = $messageOrCode;
                $httpCode = $code;
            }

            if (is_array($error)) {
                $arrError = $error;
            } else {
                $arrError = [$error];
            }

            return Response::make([
                'status_code' => $httpCode,
                'message' => $message,
                'errors' => $arrError,
                'settings' => $settings,
            ], $httpCode);
        });

        Response::macro('successWithPagination', function ($paginatedData, $resourceClass, $message = '', $settings = []) {
            $response = [
                'status_code' => 200,
                'data' => $resourceClass::collection($paginatedData->items()),
                'message' => $message,
                'settings' => $settings,
            ];

            // Add pagination metadata if it's a paginated result
            if (method_exists($paginatedData, 'currentPage')) {
                $response['pagination'] = [
                    'current_page' => $paginatedData->currentPage(),
                    'last_page' => $paginatedData->lastPage(),
                    'per_page' => $paginatedData->perPage(),
                    'total' => $paginatedData->total(),
                    'from' => $paginatedData->firstItem(),
                    'to' => $paginatedData->lastItem(),
                    'has_more_pages' => $paginatedData->hasMorePages(),
                ];
            }

            return Response::make($response, 200);
        });

        Response::macro('created', function ($data = [], $message = '', $settings = []) {
            return Response::make([
                'status_code' => 201,
                'data' => $data,
                'message' => $message,
                'settings' => $settings
            ], 201);
        });

        Response::macro('badRequest', function ($error = [], $message = 'Bad Request', $settings = []) {
            return Response::make([
                'status_code' => 400,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 400);
        });

        Response::macro('unauthorized', function ($error = ['Unauthorized'], $message = 'Unauthorized', $settings = []) {
            return Response::make([
                'status_code' => 401,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 401);
        });

        Response::macro('forbidden', function ($error = ['Forbidden'], $message = 'Forbidden', $settings = []) {
            return Response::make([
                'status_code' => 403,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 403);
        });

        Response::macro('notFound', function ($error = ['Not Found'], $message = 'Not Found', $settings = []) {
            return Response::make([
                'status_code' => 404,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 404);
        });

        Response::macro('methodNotAllowed', function ($error = ['Method Not Allowed'], $message = 'Method Not Allowed', $settings = []) {
            return Response::make([
                'status_code' => 405,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 405);
        });

        Response::macro('conflict', function ($error = ['Conflict'], $message = 'Conflict', $settings = []) {
            return Response::make([
                'status_code' => 409,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 409);
        });

        Response::macro('unprocessableEntity', function ($error = [], $message = 'Unprocessable Entity', $settings = []) {
            return Response::make([
                'status_code' => 422,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 422);
        });

        Response::macro('tooManyRequests', function ($error = ['Too Many Requests'], $message = 'Too Many Requests', $settings = []) {
            return Response::make([
                'status_code' => 429,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 429);
        });

        Response::macro('internalServerError', function ($error = ['Internal Server Error'], $message = 'Internal Server Error', $settings = []) {
            return Response::make([
                'status_code' => 500,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 500);
        });

        Response::macro('serviceUnavailable', function ($error = ['Service Unavailable'], $message = 'Service Unavailable', $settings = []) {
            return Response::make([
                'status_code' => 503,
                'message' => $message,
                'errors' => is_array($error) ? $error : [$error],
                'settings' => $settings
            ], 503);
        });
    }
}
```

Tujuan:

* Format response konsisten di seluruh endpoint.
* Controller tetap tipis dan mudah dibaca.
* Memudahkan frontend karena struktur response seragam.

### 1.5.1 Standar Pesan Error (Wajib Spesifik, Dilarang Umum)

Pesan error ditulis oleh backend dan langsung ditampilkan frontend ke user, jadi **wajib jelas**: user (dan tim support) harus tahu **apa yang gagal**, **kenapa**, dan **apa yang harus dilakukan**, tanpa perlu membuka log.

Aturan:

* **`message`** = satu kalimat spesifik yang siap ditampilkan: objek + kondisi + (jika ada) langkah perbaikan.
* **`errors`** = daftar detail/alasan. Jika hanya satu alasan, isinya boleh sama dengan `message`.
* Sebutkan **objek yang spesifik**: nama data, ID, nama field, nama modul, nama permission. Contoh `Role "Staff HR"`, `Data Karyawan dengan ID 45`.
* Bahasa Indonesia, kalimat lengkap, tanpa singkatan internal.
* **Dilarang** pesan umum: `Error`, `Gagal`, `Terjadi kesalahan`, `Not Found`, `Forbidden`, `Bad Request`, `Data tidak valid`, `Something went wrong`.
* **Dilarang** memanggil macro error tanpa argumen (`response()->forbidden()`, `response()->notFound()`), dan **dilarang** `abort(403)` tanpa pesan. Selalu `abort(403, 'pesan spesifik')` atau `response()->forbidden(['detail'], 'pesan')`.
* **Spesifik tetapi aman**: jangan menampilkan namespace class, nama tabel, query SQL, path file, stack trace, atau isi token. Detail teknis cukup di log.
* Error 500 tidak boleh menjelaskan penyebab teknis ke client, tetapi wajib menyertakan **kode referensi** yang bisa dicari di log.

Contoh:

| Situasi | Dilarang (umum) | Wajib (spesifik) |
|---|---|---|
| Data tidak ada | `Not Found` | `Data Karyawan dengan ID 45 tidak ditemukan` |
| Hapus data yang masih dipakai | `Gagal menghapus data` | `Role "Staff HR" tidak bisa dihapus karena masih dipakai oleh 3 user` |
| Status transaksi tidak sesuai | `Bad Request` | `Invoice INV-2026-0012 sudah dibayar dan tidak bisa diubah` |
| Kuota/limit | `Forbidden` | `Paket Basic hanya mengizinkan 10 user aktif. Saat ini sudah 10 user, upgrade paket untuk menambah user` |
| File import salah | `File tidak valid` | `Kolom "nama" wajib ada di baris header file Excel` |
| Akses | `Unauthorized` | `Anda tidak memiliki izin untuk aksi ini. Izin yang dibutuhkan: finance.invoice.approve` |

Contoh di controller:

```php
$invoice = InvoiceModel::findOrFail($id); // 404 otomatis: "Data Invoice dengan ID 12 tidak ditemukan"

if ($invoice->status === 'paid') {
    return response()->conflict(
        ["Invoice {$invoice->nomor} sudah berstatus paid sejak {$invoice->paid_at->format('d M Y')}"],
        "Invoice {$invoice->nomor} sudah dibayar dan tidak bisa diubah",
    );
}
```

Di middleware / service (di luar controller), gunakan `abort()` dengan pesan; handler global (1.3.7) mengubahnya ke format macro:

```php
abort(409, "Periode payroll {$periode} sudah dikunci. Buka kunci periode terlebih dahulu");
```

Label data pada pesan 404 otomatis diambil dari nama model (`KaryawanModel` → `Karyawan`, `DetailPostModel` → `Detail Post`). Jika ingin label lain, tambahkan konstanta di model:

```php
class EmployeeModel extends Model
{
    public const LABEL = 'Karyawan';
}
```

Pesan validasi (422) juga wajib jelas dan berbahasa Indonesia:

* Setiap Form Request wajib punya `attributes()` (nama field yang manusiawi) dan `messages()` untuk aturan yang pesannya perlu konteks (unique, exists, aturan bisnis). Contoh lengkap di `RoleStoreRequest` (1.3.8).
* Set `APP_LOCALE=id` dan sediakan terjemahan `lang/id/validation.php` untuk pesan bawaan Laravel. File bisa dibuat dari `php artisan lang:publish` lalu diterjemahkan, atau memakai package terjemahan komunitas (`laravel-lang/common`). Package ini opsional, jadi ikuti protokol konfirmasi di 0.1 sebelum memasangnya.

Helper penyusun pesan untuk handler global (`app/Helpers/ApiErrorHelpers.php`):

```php
<?php

namespace App\Helpers;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Request;
use Illuminate\Support\Arr;
use Illuminate\Support\Str;
use Spatie\Permission\Exceptions\UnauthorizedException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * Menyusun pesan error API yang spesifik (apa yang gagal + kenapa + apa yang harus dilakukan)
 * tanpa membocorkan detail internal (namespace class, SQL, path file).
 */
class ApiErrorHelpers
{
    /**
     * Kode referensi error per request, sama di response dan di log.
     */
    public static function reference(): string
    {
        $request = request();

        if (! $request->attributes->has('error_ref')) {
            $request->attributes->set('error_ref', (string) Str::uuid());
        }

        return $request->attributes->get('error_ref');
    }

    /**
     * Label model untuk pesan: pakai konstanta LABEL jika ada,
     * jika tidak dari nama class (KategoriModel -> Kategori, DetailPostModel -> Detail Post).
     */
    public static function modelLabel(string $modelClass): string
    {
        if (defined($modelClass.'::LABEL')) {
            return $modelClass::LABEL;
        }

        return Str::of(class_basename($modelClass))->replaceEnd('Model', '')->headline()->toString();
    }

    public static function unauthenticated(AuthenticationException $e, Request $request): string
    {
        return $request->bearerToken()
            ? 'Token tidak valid atau sudah kedaluwarsa. Silakan login ulang'
            : 'Token tidak ditemukan. Sertakan header Authorization: Bearer <token>';
    }

    public static function permissionDenied(UnauthorizedException $e): string
    {
        $required = $e->getRequiredPermissions() ?: $e->getRequiredRoles();

        return $required
            ? 'Anda tidak memiliki izin untuk aksi ini. Izin yang dibutuhkan: '.implode(' atau ', $required)
            : 'Anda tidak memiliki izin untuk aksi ini';
    }

    public static function fromHttpException(HttpExceptionInterface $e, Request $request): string
    {
        $status = $e->getStatusCode();
        $previous = $e->getPrevious();
        $headers = $e->getHeaders();
        $endpoint = $request->method().' /'.$request->path();

        if ($previous instanceof ModelNotFoundException) {
            $label = self::modelLabel($previous->getModel());
            $ids = implode(', ', Arr::wrap($previous->getIds()));

            return $ids !== ''
                ? "Data {$label} dengan ID {$ids} tidak ditemukan"
                : "Data {$label} tidak ditemukan";
        }

        return match (true) {
            $status === 404 => "Endpoint {$endpoint} tidak ditemukan",
            $status === 405 => "Method {$request->method()} tidak didukung untuk endpoint /{$request->path()}. Method yang didukung: ".($headers['Allow'] ?? '-'),
            $status === 429 => 'Terlalu banyak request. Coba lagi dalam '.($headers['Retry-After'] ?? 60).' detik',
            $status === 503 && in_array($e->getMessage(), ['', 'Service Unavailable'], true) => 'Sistem sedang dalam pemeliharaan. Coba lagi beberapa saat lagi',
            $e->getMessage() !== '' => $e->getMessage(),
            // Sampai sini berarti ada abort()/exception tanpa pesan: itu pelanggaran standar, perbaiki di kode pemanggil
            default => "Permintaan ke {$endpoint} ditolak (HTTP {$status}) tanpa keterangan. Laporkan ke tim IT",
        };
    }
}
```

Checklist review pesan error:

* Tidak ada pemanggilan macro error tanpa argumen dan tidak ada `abort()` tanpa pesan.
* Setiap `message` menyebut objek spesifik (nama/ID/field/modul/permission).
* Tidak ada nama class, tabel, SQL, atau path di response.
* Test endpoint meng-assert isi `message`, bukan hanya status code.

---

## 1.6 Standar Query Performance (Anti N+1 Wajib)

Semua endpoint Laravel wajib menghindari N+1 query.

Aturan:

* Relasi yang dipakai di Resource/response wajib di-*eager load* menggunakan `with()` atau `load()`.
* Dilarang melakukan akses relasi berulang di loop tanpa eager loading.
* Untuk endpoint list, gunakan eager loading sejak query utama (contoh: `Model::with([...])->paginate(...)`).
* Untuk endpoint detail, gunakan eager loading relasi yang dibutuhkan sebelum return resource.

Contoh benar:

```php
$pendaftaran = PendaftaranModel::with(['peserta', 'merchandise.merchandise', 'kategoriLomba'])
    ->findOrFail($id);
```

Contoh yang harus dihindari:

```php
$pendaftaranList = PendaftaranModel::paginate(10);
foreach ($pendaftaranList as $item) {
    $item->peserta; // memicu N+1 jika tidak eager load
}
```

Guard wajib di `AppServiceProvider::boot()` agar N+1 ketahuan saat development (exception di local/staging, tidak mengganggu production):

```php
use Illuminate\Database\Eloquent\Model;

public function boot(): void
{
    Model::preventLazyLoading(! $this->app->isProduction());
    Model::preventSilentlyDiscardingAttributes(! $this->app->isProduction());
}
```

* `preventSilentlyDiscardingAttributes` membuat field yang tidak ada di `fillable` melempar exception (bukan diam-diam dibuang), sehingga bug mass assignment cepat ketahuan.
* `Model::automaticallyEagerLoadRelationships()` (Laravel 12.8+) **tidak** menggantikan aturan di atas. Eager loading eksplisit dengan `with()` tetap wajib supaya query bisa dibaca dan direview.

Checklist review query:

* Pastikan relasi di Resource sudah dipetakan ke eager loading query.
* Pastikan endpoint list/detail tidak menimbulkan query berulang per item.
* Jika query kompleks, validasi dengan query log/debug tool sebelum merge.

---

## 1.7 Standar Security (Injection Prevention Wajib)

Semua implementasi API wajib mencegah injection data (SQL Injection, mass assignment abuse, dan input berbahaya).

Aturan wajib:

* **Validasi ketat via Form Request**:
  * Semua input dari request harus tervalidasi di `rules()`.
  * Gunakan whitelist field yang diperbolehkan, jangan menerima field liar.
* **Gunakan data tervalidasi saja**:
  * Wajib gunakan `$request->validated()` untuk create/update/filter.
  * Dilarang memakai `$request->all()` langsung ke query atau model.
* **Mass assignment protection**:
  * Model wajib punya daftar fillable yang jelas (`#[Fillable([...])]` di Laravel 13, atau `$fillable` di Laravel 12).
  * Dilarang membuka semua field sensitif untuk diisi dari request.
* **Hindari raw query tidak aman**:
  * Hindari `DB::raw()` dan query raw string jika tidak diperlukan.
  * Jika terpaksa memakai raw query, wajib gunakan parameter binding (prepared statement).
* **Filter/sort whitelist**:
  * Parameter seperti `sort_by`, `direction`, `search_field`, `includes` wajib divalidasi terhadap daftar kolom yang diizinkan.
  * Dilarang langsung menyisipkan nilai request ke `orderBy`, `selectRaw`, `whereRaw`, atau dynamic column name tanpa whitelist.
* **Type casting & sanitasi ringan**:
  * Lakukan normalisasi di `prepareForValidation()` (trim, cast integer/boolean/date) sebelum query.
* **Output safety**:
  * Resource/API response hanya expose field yang memang boleh tampil (hindari kebocoran data internal).

Contoh aman (filter whitelist):

```php
$allowedSort = ['created_at', 'nama', 'status'];
$sortBy = in_array($request->validated('sort_by'), $allowedSort, true)
    ? $request->validated('sort_by')
    : 'created_at';

$direction = $request->validated('direction') === 'asc' ? 'asc' : 'desc';

$query = PendaftaranModel::query()->orderBy($sortBy, $direction);
```

Contoh yang dilarang:

```php
$query = PendaftaranModel::query()
    ->orderBy($request->sort_by, $request->direction); // raw input tanpa whitelist
```

Checklist review security:

* Pastikan tidak ada query builder/raw SQL yang menerima input mentah.
* Pastikan semua endpoint write memakai `$request->validated()`.
* Pastikan model tidak membuka mass assignment berlebihan.
* Pastikan field response tidak membocorkan data sensitif/internal.

---

## 1.8 Standar API Token Security (Sanctum Wajib Aman)

Jika Laravel digunakan sebagai API untuk frontend/mobile, keamanan token wajib diterapkan secara ketat.

Aturan wajib backend:

* Gunakan **Laravel Sanctum** untuk token auth API.
* Semua endpoint bisnis wajib dilindungi `auth:sanctum`.
* Wajib pakai HTTPS pada environment production (token tidak boleh lewat HTTP plain).
* Aktifkan rate limiting pada endpoint sensitif:
  * login, refresh token, forgot password, OTP, dan endpoint auth lain.
  * Definisikan limiter di `AppServiceProvider::boot()`, lalu pasang `throttle:<nama>` di route:

```php
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;

RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by(strtolower((string) $request->input('email')).'|'.$request->ip());
});

// routes/api.php
Route::post('auth/login', [AuthController::class, 'login'])->middleware('throttle:login');
```
* Batasi masa berlaku token (TTL) sesuai kebijakan keamanan (disarankan pendek untuk akses token). Default Sanctum: token **tidak pernah expire**, jadi wajib diset:
  * Global: `'expiration' => 60 * 24` (menit) di `config/sanctum.php`, atau
  * Per token: argumen ketiga `createToken`, contoh `$user->createToken('android-app', ['hris:read'], now()->addDays(7))`.
  * Jadwalkan pembersihan token expired di `routes/console.php`: `Schedule::command('sanctum:prune-expired --hours=24')->daily();`
* Token wajib bisa di-revoke (logout current device / logout all devices).
* Jika akun terindikasi risiko (password reset, device mencurigakan, role berubah), lakukan invalidasi token aktif.

Aturan wajib pembuatan token:

* Saat create token, sertakan konteks perangkat/sesi (nama device/client).
* Gunakan abilities/scopes token sesuai kebutuhan endpoint (least privilege), jangan beri akses penuh jika tidak perlu.
* Jangan menaruh data sensitif ke payload response login selain yang diperlukan.

Aturan wajib controller/service:

* Dilarang menulis token ke log (`Log::info/error`) dalam bentuk plain.
* Dilarang mengembalikan token lama berulang-ulang di endpoint selain login/refresh resmi.
* Dilarang menaruh token pada query string URL.
* Pastikan error response auth tidak membocorkan detail internal.

Aturan integrasi frontend (wajib diikuti tim frontend):

* Simpan token dengan aman (hindari penyimpanan sembarangan yang mudah di-copy).
* Jangan hardcode token di source code.
* Jangan menampilkan token di UI, screenshot, atau console log.
* Gunakan header:
  * `Authorization: Bearer <token>`
* Saat logout, frontend wajib memanggil endpoint revoke token dan menghapus token lokal.

Hardening tambahan (disarankan kuat):

* Tambahkan deteksi anomali sesi (IP/UA/device change) untuk trigger verifikasi ulang.
* Terapkan lockout sementara jika gagal login berulang.
* Audit trail untuk login/logout/revoke token.
* Gunakan CORS policy ketat hanya untuk origin frontend resmi.

Checklist review token security:

* Semua endpoint private sudah `auth:sanctum`.
* Tidak ada token plain di log/response debug.
* Login endpoint memiliki throttle/rate limit.
* Mekanisme revoke token tersedia dan dipakai saat logout.
* Frontend tidak menyimpan/menampilkan token secara tidak aman.

---

## 1.9 Standar Realtime (Laravel Reverb)

Realtime (notifikasi, status proses, progress export, streaming AI) memakai **Laravel Reverb** sebagai WebSocket server dan **broadcasting** Laravel.

### 1.9.1 Konfigurasi Environment

```ini
BROADCAST_CONNECTION=reverb

# Kredensial app (di-generate install:broadcasting, simpan sebagai secret)
REVERB_APP_ID=
REVERB_APP_KEY=
REVERB_APP_SECRET=

# Alamat yang dipakai Laravel & client untuk konek ke Reverb (publik)
REVERB_HOST=ws.domain-anda.com
REVERB_PORT=443
REVERB_SCHEME=https

# Alamat bind server Reverb (internal, di belakang reverse proxy)
REVERB_SERVER_HOST=0.0.0.0
REVERB_SERVER_PORT=8080
```

Aturan:

* Production wajib lewat **TLS** (`wss://`) di belakang reverse proxy (Nginx/Caddy) yang meneruskan ke `REVERB_SERVER_PORT`.
* Isi `allowed_origins` di `config/reverb.php` hanya dengan domain frontend resmi. **Dilarang** `*` di production.
* `REVERB_APP_SECRET` tidak boleh dikirim ke frontend; frontend hanya butuh `REVERB_APP_KEY`, host, port, dan scheme.
* Jalankan server dengan `php artisan reverb:start` di bawah process manager (Supervisor/systemd) dan restart dengan `php artisan reverb:restart` setiap deploy.
* Event broadcast masuk queue, jadi **queue worker wajib jalan** (`php artisan queue:work`).

### 1.9.2 Auth Private Channel untuk Client API (Sanctum)

`install:broadcasting` mendaftarkan `channels:` di `withRouting`, yang memakai session web. Untuk client API (mobile/SPA dengan Bearer token), **hapus** entry `channels:` dari `withRouting` dan ganti dengan `withBroadcasting`:

```php
return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withBroadcasting(
        __DIR__.'/../routes/channels.php',
        ['prefix' => 'api', 'middleware' => ['api', 'auth:sanctum', 'tenant']],
    )
    // ->withMiddleware(...) dan ->withExceptions(...) seperti 1.3.7
    ->create();
```

Endpoint auth channel menjadi `POST /api/broadcasting/auth` dengan header `Authorization: Bearer <token>`.

### 1.9.3 Konvensi Channel & Event

* **Semua data bisnis wajib lewat private/presence channel**. Public channel (`Channel`) hanya untuk data yang memang publik.
* Nama channel wajib ber-scope tenant: `company.{companyId}.<modul>.<resource>.{id}`, contoh `company.12.hris.employee.45`. Untuk notifikasi user: `company.{companyId}.user.{userId}`.
* Callback di `routes/channels.php` wajib mengecek **user anggota company tersebut** dan **permission** yang sesuai, bukan sekadar `true`.
* Event disimpan di `app/Events/<Fitur>/`, nama class bentuk lampau + suffix `Event`, contoh `EmployeeUpdatedEvent`.
* Gunakan `ShouldBroadcast` (lewat queue). `ShouldBroadcastNow` hanya untuk event ringan yang memang harus langsung.
* Payload wajib minimal dan eksplisit lewat `broadcastWith()` (pakai API Resource, jangan kirim seluruh model). Batas aman pesan WebSocket sekitar 10KB.
* Nama event di client distandarkan lewat `broadcastAs()` dengan format `<resource>.<aksi>`, contoh `employee.updated`.

Contoh `routes/channels.php`:

```php
<?php

use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('company.{companyId}.hris.employee.{employeeId}', function (User $user, int $companyId, int $employeeId) {
    return $user->companies()->whereKey($companyId)->exists()
        && $user->can('hris.employee.view');
});

Broadcast::channel('company.{companyId}.user.{userId}', function (User $user, int $companyId, int $userId) {
    return $user->id === $userId
        && $user->companies()->whereKey($companyId)->exists();
});
```

(`companies()` adalah relasi membership user-company sesuai implementasi tenant project.)

Contoh event:

```php
<?php

namespace App\Events\Employee;

use App\Http\Resources\Api\V1\Employee\EmployeeResource;
use App\Models\Employee\EmployeeModel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EmployeeUpdatedEvent implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public EmployeeModel $employee) {}

    public function broadcastOn(): array
    {
        return [
            new PrivateChannel("company.{$this->employee->company_id}.hris.employee.{$this->employee->id}"),
        ];
    }

    public function broadcastAs(): string
    {
        return 'employee.updated';
    }

    public function broadcastWith(): array
    {
        return (new EmployeeResource($this->employee))->resolve();
    }
}
```

Dispatch dari controller/service setelah data tersimpan: `EmployeeUpdatedEvent::dispatch($employee);` atau `broadcast(new EmployeeUpdatedEvent($employee))->toOthers();` jika pengirim tidak perlu menerima event-nya sendiri.

---

## 1.10 Standar AI (Laravel AI SDK)

Fitur AI memakai **Laravel AI SDK** (`laravel/ai`), bukan memanggil HTTP API provider langsung.

### 1.10.1 Konfigurasi

* API key provider hanya di `.env` (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, dst). **Dilarang** hardcode atau commit key.
* Provider dan model default diatur di `config/ai.php`, bukan ditulis di tiap agent.
* Tabel `agent_conversations` dan `agent_conversation_messages` adalah milik package (lihat pengecualian di 1.1.1).

### 1.10.2 Konvensi Agent & Tool

* Generate dengan `php artisan make:agent` (tambahkan `--structured` jika butuh output terstruktur).
* Folder: `app/Ai/Agents/<Fitur>/` dan `app/Ai/Tools/<Fitur>/`.
* Penamaan wajib bersuffix: `NamaFiturAgent` (contoh `EmployeeSummaryAgent`) dan `NamaAksiTool` (contoh `FindEmployeeTool`).
* Agent dipanggil dari controller/service, response tetap dikembalikan lewat response macro (1.5).

Aturan wajib:

* **Structured output** (`HasStructuredOutput` + `schema()`) wajib untuk hasil yang disimpan ke database atau diproses kode. Teks bebas hanya untuk ditampilkan langsung ke user.
* Hasil AI diperlakukan sebagai **input tidak tepercaya**: validasi dulu (tipe, range, enum) sebelum disimpan.
* **Tool wajib ter-scope tenant & permission**: setiap query di tool harus difilter ke company aktif dan dicek permission user, sama seperti endpoint biasa. Agent tidak boleh bisa membaca data company lain.
* Tool yang mengubah/menghapus data wajib memakai **human tool approval** dari SDK, bukan langsung dieksekusi.
* Jangan kirim data sensitif (password, token, NIK, gaji, data kesehatan) ke provider kecuali memang dibutuhkan dan sudah disetujui kebijakan perusahaan.
* Prompt yang lama (> beberapa detik) wajib async: `->queue(...)` atau `->broadcastOnQueue($prompt, new PrivateChannel(...))` untuk streaming hasil ke client lewat Reverb (channel private ber-scope tenant, lihat 1.9.3).
* Endpoint AI wajib diberi rate limiter khusus (`throttle:ai`), karena tiap request berbiaya.
* Test wajib memakai fake, **dilarang** memanggil provider asli di test: `EmployeeSummaryAgent::fake([...])`.

Contoh agent terstruktur:

```php
<?php

namespace App\Ai\Agents\Employee;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\HasStructuredOutput;
use Laravel\Ai\Promptable;
use Stringable;

class EmployeeSummaryAgent implements Agent, HasStructuredOutput
{
    use Promptable;

    public function instructions(): Stringable|string
    {
        return 'Ringkas performa karyawan berdasarkan data KPI yang diberikan. Jawab dalam Bahasa Indonesia.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'summary' => $schema->string()->required(),
            'score' => $schema->integer()->min(1)->max(10)->required(),
        ];
    }
}
```

Pemakaian di controller:

```php
$result = (new EmployeeSummaryAgent)->prompt($kpiText);

return response()->success([
    'summary' => $result['summary'],
    'score' => $result['score'],
], 'Ringkasan berhasil dibuat');
```

---

## 1.11 Standar Export/Import (Laravel Excel 4) & PDF (DomPDF)

### 1.11.1 Laravel Excel 4

* Folder & penamaan: `app/Exports/<Fitur>/NamaFiturExport.php` dan `app/Imports/<Fitur>/NamaFiturImport.php`.
* Laravel Excel 4 **fully typed**: semua method concern wajib punya return type (`query(): Builder`, `headings(): array`, `map(mixed $row): array`, dst). Class lama dari 3.1 tanpa return type akan error.
* Export wajib `FromQuery` (bukan `FromCollection` untuk data besar), dengan **eager loading** dan **scope tenant** di query.
* Export/import besar wajib queued (`ShouldQueue`, opsional `ShouldBatch`), simpan ke storage, lalu kabari user lewat notifikasi / event Reverb. Request HTTP tidak boleh menunggu file besar selesai.
* Import wajib memakai `WithValidation` (aturan sama ketatnya dengan Form Request) dan `WithChunkReading` untuk file besar.
* Job queue **tidak punya** `auth()->id()`. Kirim user ID dan company ID lewat constructor, lalu isi kolom audit secara eksplisit (trait `HasAuditColumns` memakai `??=`, jadi nilai eksplisit dipertahankan).
* Laravel 13: import queued boleh memakai attribute `#[Queue('imports')]` dan `#[Connection('redis')]`.

Contoh export:

```php
<?php

namespace App\Exports\Kategori;

use App\Models\Kategori\KategoriModel;
use Illuminate\Database\Eloquent\Builder;
use Maatwebsite\Excel\Concerns\Exportable;
use Maatwebsite\Excel\Concerns\FromQuery;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;

class KategoriExport implements FromQuery, WithHeadings, WithMapping
{
    use Exportable;

    public function query(): Builder
    {
        return KategoriModel::query()->orderBy('nama');
    }

    public function headings(): array
    {
        return ['ID', 'Nama', 'Dibuat'];
    }

    public function map(mixed $row): array
    {
        return [$row->id, $row->nama, $row->created_at?->toDateTimeString()];
    }
}
```

Contoh import (queued, audit eksplisit):

```php
<?php

namespace App\Imports\Kategori;

use App\Models\Kategori\KategoriModel;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Database\Eloquent\Model;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithChunkReading;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;

class KategoriImport implements ToModel, WithHeadingRow, WithValidation, WithChunkReading, ShouldQueue
{
    public function __construct(private int $userId) {}

    public function model(array $row): ?Model
    {
        $kategori = new KategoriModel(['nama' => $row['nama']]);
        $kategori->created_by = $this->userId; // audit tidak fillable, isi eksplisit

        return $kategori;
    }

    public function rules(): array
    {
        return ['nama' => ['required', 'string', 'max:100']];
    }

    public function chunkSize(): int
    {
        return 500;
    }
}
```

Pemakaian di controller:

```php
// Download langsung (data kecil)
return Excel::download(new KategoriExport, 'kategori.xlsx');

// Import queued
Excel::queueImport(new KategoriImport($request->user()->id), $request->file('file'));

return response()->success([], 'Import sedang diproses');
```

### 1.11.2 PDF (barryvdh/laravel-dompdf 3)

* Gunakan facade `Barryvdh\DomPDF\Facade\Pdf`.
* Template di `resources/views/pdf/<fitur>/<nama>.blade.php`, contoh `pdf/invoice/detail.blade.php`.
* Data untuk view disiapkan di controller/service (eager loaded). View PDF **dilarang** melakukan query.
* Keamanan (default DomPDF 3, **jangan diubah**): di `config/dompdf.php` bagian `options`, `enable_remote => false` dan `enable_php => false`. Gambar/logo dimuat dari path lokal (`public_path()` / `storage_path()`) atau base64, bukan URL remote.
* Jangan render HTML dari input user tanpa escape (`{{ }}`, bukan `{!! !!}`).
* PDF berat atau massal dibuat di queue job, disimpan ke storage, lalu user diberi link unduh.

Contoh:

```php
use Barryvdh\DomPDF\Facade\Pdf;

$invoice = InvoiceModel::with(['customer', 'items'])->findOrFail($id);

return Pdf::loadView('pdf.invoice.detail', ['invoice' => $invoice])
    ->setPaper('a4', 'portrait')
    ->download("invoice-{$invoice->nomor}.pdf");
```

### 1.11.3 Pengecualian Response Macro

Endpoint yang mengembalikan **file** (Excel/PDF download/stream) adalah satu-satunya pengecualian aturan 1.5: response berupa binary file, bukan JSON macro. Error pada endpoint tersebut (404, 403, 422) tetap memakai macro / format standar.

---

## 2. Konvensi Penamaan Database (Table Naming)

### 2.1 Tabel Master

Digunakan untuk data referensi atau data utama.

**Format:**

```
m_xxxx
```

**Contoh:**

* `m_kategori`
* `m_user`
* `m_role`

---

### 2.2 Tabel Transaksi

Digunakan untuk data utama yang bersifat proses atau transaksi.

**Format:**

```
t_xxxx
```

**Contoh:**

* `t_post`
* `t_order`
* `t_invoice`

---

### 2.3 Tabel Jembatan / Detail

Digunakan untuk relasi many-to-many atau detail dari tabel transaksi.

**Format:**

```
t_xxxx_det
```

**Contoh:**

* `t_post_kategori_det`
* `t_order_item_det`
* `t_invoice_det`

---

## 2.4 Standar Kolom Wajib (Audit & Soft Deletes)

Setiap tabel (master/transaksi/detail) **wajib** memiliki kolom standar untuk histori perubahan data:

### 2.4.1 Audit siapa yang melakukan aksi

Wajib menambahkan:

* `created_by` (nullable) → menyimpan user yang membuat data
* `updated_by` (nullable) → menyimpan user yang terakhir mengubah data
* `deleted_by` (nullable) → menyimpan user yang menghapus data (saat soft delete)

Catatan:

* Tipe kolom mengikuti PK user (umumnya `unsignedBigInteger`)
* Disarankan diberi index agar query audit cepat
* `deleted_by` diisi saat proses delete (karena soft delete tidak menghapus record)
* Kolom ini tetap `unsignedBigInteger` tanpa foreign key constraint, agar data audit tidak ikut terhapus/terkunci saat user dihapus.

Implementasi wajib pada CRUD:

* **Create (store)**: set `created_by = auth()->id()`
* **Update (update)**: set `updated_by = auth()->id()`
* **Delete (destroy/soft delete)**: set `deleted_by = auth()->id()` lalu lakukan soft delete
* (Opsional) **Restore**: jika data di-restore, biasanya `deleted_by` di-`null`-kan kembali (sesuai kebutuhan bisnis)

Implementasi yang disarankan: otomatisasi lewat trait model agar tidak ada endpoint yang lupa mengisi audit field. Jika trait ini dipakai, **jangan** set kolom audit manual lagi di controller.

```php
<?php

namespace App\Models\Concerns;

trait HasAuditColumns
{
    public static function bootHasAuditColumns(): void
    {
        static::creating(function ($model) {
            $model->created_by ??= auth()->id();
        });

        static::updating(function ($model) {
            $model->updated_by = auth()->id();
        });

        // Soft delete hanya meng-update deleted_at, jadi deleted_by disimpan dulu secara quiet
        static::deleting(function ($model) {
            if (method_exists($model, 'isForceDeleting') && ! $model->isForceDeleting()) {
                $model->deleted_by = auth()->id();
                $model->saveQuietly();
            }
        });

        static::restoring(function ($model) {
            $model->deleted_by = null;
        });
    }
}
```

### 2.4.2 Soft Deletes (wajib)

Wajib menambahkan kolom `deleted_at` pada migration agar data tidak benar-benar hilang.

Contoh potongan migration (template):

```php
// Audit columns
$table->unsignedBigInteger('created_by')->nullable()->index();
$table->unsignedBigInteger('updated_by')->nullable()->index();
$table->unsignedBigInteger('deleted_by')->nullable()->index();

// Soft delete
$table->softDeletes(); // deleted_at
```

---

## 2.5 Standar Dokumentasi Database (Komentar Tabel & Kolom)

Setiap migration **wajib** menambahkan komentar agar jelas:

* Tabel ini untuk apa (comment di level tabel)
* Setiap kolom ini gunanya apa (comment di level kolom)

Contoh (template):

```php
Schema::create('m_kategori', function (Blueprint $table) {
    $table->comment('Master kategori untuk pengelompokan data X/Y');

    $table->id();
    $table->string('nama')->comment('Nama kategori yang ditampilkan ke user');

    // Audit columns
    $table->unsignedBigInteger('created_by')->nullable()->comment('User yang membuat data')->index();
    $table->unsignedBigInteger('updated_by')->nullable()->comment('User yang terakhir mengubah data')->index();
    $table->unsignedBigInteger('deleted_by')->nullable()->comment('User yang menghapus data (soft delete)')->index();

    $table->timestamps();
    $table->softDeletes()->comment('Waktu soft delete (data tidak hilang permanen)');
});
```

---

## 3. Konvensi Penamaan Model

Setiap model **wajib memiliki suffix `Model`**.

### 3.1 Model Master

**Format:**

```
NamaModel
```

**Contoh:**

* `KategoriModel`
* `UserModel`

Mapping:

```
m_kategori  ->  KategoriModel
```

---

### 3.2 Model Transaksi

**Contoh:**

* `PostModel`
* `OrderModel`

Mapping:

```
t_post  ->  PostModel
```

---

### 3.3 Model Detail / Jembatan

**Contoh:**

* `DetailPostModel`
* `OrderItemModel`

Mapping:

```
t_post_kategori_det  ->  DetailPostModel
```

---

## 3.4 Standar Model (SoftDeletes)

Setiap model yang tabelnya memiliki `deleted_at` **wajib menggunakan** trait `SoftDeletes`.

Catatan:

* Pastikan `use Illuminate\Database\Eloquent\SoftDeletes;` di model
* Pastikan kolom `deleted_at` ada di migration (`$table->softDeletes()`)

---

## 3.5 Standar Definisi Model (Nama Tabel Wajib Eksplisit)

Karena nama tabel memakai prefix (`m_`, `t_`, `_det`) dan nama class memakai suffix `Model`, konvensi otomatis Laravel **tidak akan** menebak nama tabel dengan benar (`KategoriModel` akan dicari ke tabel `kategori_models`). Nama tabel **wajib** ditulis eksplisit.

Laravel 13 (direkomendasikan, PHP attributes di `Illuminate\Database\Eloquent\Attributes`):

```php
<?php

namespace App\Models\Kategori;

use App\Models\Concerns\HasAuditColumns;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

#[Table('m_kategori')]
#[Fillable(['nama'])]
class KategoriModel extends Model
{
    use HasAuditColumns;
    use SoftDeletes;
}
```

Laravel 12 (fallback, property biasa):

```php
class KategoriModel extends Model
{
    use HasAuditColumns;
    use SoftDeletes;

    protected $table = 'm_kategori';

    protected $fillable = ['nama'];
}
```

Aturan:

* Gunakan **satu gaya** per project (attribute atau property), jangan dicampur dalam satu model.
* Jika butuh cast, definisikan lewat method `casts()`, bukan property `$casts` (gaya Laravel 11+).
* Kolom audit (`created_by`, `updated_by`, `deleted_by`) **tidak boleh** masuk fillable; diisi oleh trait/controller, bukan dari request.
* Relasi `belongsToMany` ke tabel jembatan wajib menyebut nama tabel eksplisit, contoh `$this->belongsToMany(KategoriModel::class, 't_post_kategori_det', 'post_id', 'kategori_id')`.

---

## 4. Struktur Folder yang Direkomendasikan

Setiap fitur memiliki **folder sendiri** di:

* Model
* Controller
* Seeder
* Resource
* Helpers (opsional, hanya untuk logic yang reusable)

---

### 4.1 Contoh Struktur Folder

```
app/
├── Enums/
│   └── PermissionEnum.php          # katalog permission
│
├── Helpers/
│   ├── KategoriHelpers.php
│   ├── PostHelpers.php
│   ├── RbacHelpers.php
│   └── ApiErrorHelpers.php         # penyusun pesan error spesifik
│
├── Models/
│   ├── Concerns/
│   │   └── HasAuditColumns.php
│   └── Post/
│       ├── PostModel.php
│       └── DetailPostModel.php
│
├── Http/
│   ├── Controllers/
│   │   └── Api/
│   │       └── V1/
│   │           └── Post/
│   │               └── PostController.php
│   ├── Requests/
│   │   └── Post/
│   │       ├── PostStoreRequest.php
│   │       └── PostUpdateRequest.php
│   └── Resources/
│       └── Api/
│           └── V1/
│               └── Post/
│                   ├── PostResource.php
│                   └── DetailPostResource.php
│
├── Providers/
│   ├── AppServiceProvider.php
│   └── ResponseMacroServiceProvider.php
│
├── Events/
│   └── Employee/
│       └── EmployeeUpdatedEvent.php
│
├── Ai/
│   ├── Agents/
│   │   └── Employee/
│   │       └── EmployeeSummaryAgent.php
│   └── Tools/
│       └── Employee/
│           └── FindEmployeeTool.php
│
├── Exports/
│   └── Kategori/
│       └── KategoriExport.php
│
├── Imports/
│   └── Kategori/
│       └── KategoriImport.php
│
bootstrap/
├── app.php          # alias middleware + exception rendering + withBroadcasting
└── providers.php    # registrasi provider
│
routes/
├── api.php          # dari install:api
└── channels.php     # dari install:broadcasting (auth private channel)
│
resources/
└── views/
    └── pdf/
        └── invoice/
            └── detail.blade.php
│
database/
└── seeders/
    ├── Rbac/
    │   └── PermissionSeeder.php
    └── Post/
        ├── PostSeeder.php
        └── DetailPostSeeder.php
```

Catatan:

* Seeder berada di `database/seeders/` (namespace `Database\Seeders\Post`), bukan di dalam `app/`.
* Controller dan Resource dipisah per versi API lalu per fitur (`Api/V1/Post/...`), sesuai 1.3.6.

---

## 4.2 Konvensi Helpers (Reusable Logic)

Helpers digunakan untuk menyimpan logic yang **dipakai berulang** agar tidak copy-paste di Controller/Service.

Aturan:

* Folder: `app/Helpers`
* Namespace: `App\Helpers`
* Suffix class **wajib**: `Helpers`
* Penamaan: `NamaFiturHelpers` (contoh: `KategoriHelpers`, `PostHelpers`)

Contoh:

* `app/Helpers/KategoriHelpers.php` → class `KategoriHelpers`
* Isinya method-method yang paling reusable (misalnya kebutuhan `index` filtering/sorting/pagination, normalisasi input, mapping response, dll.)

Penggunaan (wajib):

* Controller dibuat **tipis**: fokus ke validasi request, pemanggilan helper/service, dan return response
* Logic yang berulang dipindahkan ke `Helpers` supaya semua endpoint konsisten dan mudah dirawat
* Helpers dapat dipanggil dari Controller (atau Service), jadi Controller tidak penuh logic

---

## 5. Contoh Implementasi Fitur Post

### 5.1 Database

* `t_post`
* `t_post_kategori_det`

---

### 5.2 Model

```
Post/
├── PostModel
└── DetailPostModel
```

---

### 5.3 Controller

```
PostController
```

Digunakan untuk:

* CRUD Post
* Relasi Post dengan Kategori
* Wajib menggunakan Form Request untuk validasi (`PostStoreRequest`, `PostUpdateRequest`)

---

### 5.4 Seeder

```
PostSeeder
DetailPostSeeder
```

---

### 5.5 API Resource

Digunakan untuk response API:

```
PostResource
DetailPostResource
```

---

## 6. Catatan Tambahan (Best Practice)

* Gunakan **singular untuk Model**; nama tabel mengikuti prefix `m_` / `t_` / `_det` (lihat bagian 2) dan wajib ditulis eksplisit di model (lihat 3.5)
* Relasi antar model menggunakan `hasMany`, `belongsTo`, `belongsToMany`
* Pisahkan logic bisnis ke **Service Layer** jika project mulai besar
* Gunakan **API Resource** untuk konsistensi response
* Standarkan **audit field**: `created_by`, `updated_by`, `deleted_by` di setiap tabel agar ada histori “siapa melakukan apa”
* Standarkan **Soft Deletes**: `deleted_at` + `SoftDeletes` trait agar data tidak hilang permanen

---

## 7. Ringkasan Singkat

| Komponen        | Aturan            |
| --------------- | ----------------- |
| Tabel Master    | `m_xxxx`          |
| Tabel Transaksi | `t_xxxx`          |
| Tabel Detail    | `t_xxxx_det`      |
| Model           | `NamaModel`       |
| Folder          | Dipisah per fitur |
| Soft Deletes    | `deleted_at` + `SoftDeletes` trait |
| Audit Field     | `created_by`, `updated_by`, `deleted_by` |
| Helpers         | `app/Helpers` + suffix `Helpers` |
| Nama tabel di Model | Wajib eksplisit: `#[Table('m_xxxx')]` (L13) / `$table` (L12) |
| Middleware & Exception | Didaftarkan di `bootstrap/app.php` |
| N+1 guard       | `Model::preventLazyLoading()` di `AppServiceProvider` |
| RBAC            | Spatie teams (`company_id`), permission dari enum, role dibuat user via `/api/v1/rbac/roles` |
| Install package | Wajib konfirmasi user dulu (0.1), command non-interaktif (0.2) |
| Pesan error     | Wajib spesifik: objek + alasan + langkah (1.5.1), dilarang pesan umum / macro tanpa argumen |
| Realtime        | Reverb, private channel `company.{id}.<modul>...`, event suffix `Event` |
| AI              | Laravel AI SDK, `app/Ai/Agents` suffix `Agent`, structured output, fake di test |
| Excel           | Laravel Excel 4 (typed), `app/Exports` / `app/Imports`, queued untuk data besar |
| PDF             | DomPDF 3, `Pdf::loadView('pdf.<fitur>.<nama>')`, remote access tetap off |

---

Dokumentasi ini dapat digunakan sebagai **prompt awal** sebelum membuat API Laravel agar seluruh tim memiliki standar yang sama.
