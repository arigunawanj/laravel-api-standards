---
name: laravel-api-standards
description: Architect, implement, and review Laravel APIs following strict enterprise standards for multi-tenancy, naming conventions (m_, t_, Model suffix), folder structures, and mandatory audit fields. Use when creating or modifying Laravel models, controllers, migrations, or when performing code reviews to ensure strict adherence to the defined schema.
---

# Dokumentasi Awalan Laravel API (Naming Convention & Struktur Folder)

Dokumentasi ini digunakan sebagai **standar awal (awalan / prompt)** dalam membuat API menggunakan **Laravel**, agar struktur project rapi, konsisten, dan mudah dikembangkan.

---

## 1. Tujuan

* Menyeragamkan **penamaan database, model, controller, seeder, dan resource**
* Memudahkan maintenance dan scaling API
* Memisahkan **master data**, **transaksi**, dan **tabel jembatan (detail)** secara jelas
* Menambahkan standar **Soft Deletes**, **audit field (created_by/updated_by/deleted_by)**, dan **Helpers** untuk kode reusable
* Menstandarkan **multi-company (tenant)**, **plan/modul**, dan **RBAC (role/permission)** untuk platform enterprise

---

## 1.1 Stack Tambahan (Package Wajib)

Backend ini menggunakan Laravel + beberapa package tambahan:

* **Sanctum**: API authentication (Bearer token)
* **DOMPDF**: export PDF (`barryvdh/laravel-dompdf`)
* **Laravel Excel**: export/import Excel (`maatwebsite/excel`)

Catatan:

* Config package berada di `config/dompdf.php` dan `config/excel.php` (hasil publish).

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

### 1.3.3 Module Gating (Plan/Entitlement)

Setiap modul di-gate dengan middleware:

* `module:<moduleKey>` (contoh `module:hris`, `module:finance`)

Jika modul tidak aktif untuk company, API mengembalikan **403**.

### 1.3.4 Permission Check (RBAC)

RBAC pada project Laravel ini menggunakan package **Spatie Laravel Permission (v7)**.

Referensi:

* https://spatie.be/docs/laravel-permission/v7/introduction

Permission check per endpoint:

* `permission:<permissionKey>` (contoh `permission:hris.employee.view`)

Catatan:

* Jika membership `is_owner = true` maka bypass permission.
* Assign role/permission mengikuti pola Spatie (`assignRole`, `givePermissionTo`).
* Permission check gunakan kemampuan native Laravel/Gate yang terintegrasi (`can`) sesuai integrasi Spatie.

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
  * Default `return true;` jika authorization sudah ditangani middleware (`auth`, `company`, `permission`)
* Method `rules()`:
  * Semua rule validasi didefinisikan di sini (required, string, max, exists, unique, array, dst)
* Method `messages()` (opsional):
  * Digunakan untuk custom pesan validasi agar konsisten
* Method `prepareForValidation()` (opsional):
  * Digunakan untuk normalisasi data sebelum validasi (trim, cast, mapping key, dst)

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

* Jika validasi gagal, response harus **422 Unprocessable Entity** dengan format default Laravel:

```json
{
  "message": "The given data was invalid.",
  "errors": {
    "nama_field": [
      "Pesan error validasi"
    ]
  }
}
```

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
* Khusus Laravel 12+:
  * Wajib daftarkan `\App\Providers\ResponseMacroServiceProvider::class` di file `bootstrap/providers.php`.
  * Tanpa registrasi ini, macro `response()->success(...)` dan macro lainnya tidak akan aktif.

Contoh `bootstrap/providers.php` (Laravel 12+):

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

Contoh implementasi controller:

```php
public function show(string $id)
{
    try {
        $pendaftaran = PendaftaranModel::with(['peserta', 'merchandise.merchandise', 'kategoriLomba'])
            ->findOrFail($id);

        return response()->success(
            new PendaftaranResource($pendaftaran),
            'Data pendaftaran berhasil diambil'
        );
    } catch (\Exception $e) {
        return response()->notFound(['message' => 'Pendaftaran tidak ditemukan']);
    }
}
```

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
  * Model wajib punya `$fillable` yang jelas.
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
* Batasi masa berlaku token (TTL) sesuai kebijakan keamanan (disarankan pendek untuk akses token).
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

Implementasi wajib pada CRUD:

* **Create (store)**: set `created_by = auth()->id()`
* **Update (update)**: set `updated_by = auth()->id()`
* **Delete (destroy/soft delete)**: set `deleted_by = auth()->id()` lalu lakukan soft delete
* (Opsional) **Restore**: jika data di-restore, biasanya `deleted_by` di-`null`-kan kembali (sesuai kebutuhan bisnis)

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
t_post_kategori  ->  DetailPostModel
```

---

## 3.4 Standar Model (SoftDeletes)

Setiap model yang tabelnya memiliki `deleted_at` **wajib menggunakan** trait `SoftDeletes`.

Catatan:

* Pastikan `use Illuminate\Database\Eloquent\SoftDeletes;` di model
* Pastikan kolom `deleted_at` ada di migration (`$table->softDeletes()`)

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
├── Helpers/
│   ├── KategoriHelpers.php
│   └── PostHelpers.php
│
├── Models/
│   └── Post/
│       ├── PostModel.php
│       └── DetailPostModel.php
│
├── Http/
│   └── Controllers/
│       └── Post/
│           └── PostController.php
│
├── Http/
│   └── Resources/
│       └── Post/
│           ├── PostResource.php
│           └── DetailPostResource.php
│
├── Database/
│   └── Seeders/
│       └── Post/
│           ├── PostSeeder.php
│           └── DetailPostSeeder.php
```

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
* `t_post_kategori`

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

* Gunakan **singular untuk Model**, **plural untuk table (opsional sesuai kesepakatan)**
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

---

Dokumentasi ini dapat digunakan sebagai **prompt awal** sebelum membuat API Laravel agar seluruh tim memiliki standar yang sama.
