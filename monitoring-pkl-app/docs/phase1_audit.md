# Phase 1 — Audit & Gap Analysis (SMART PKL MVP)

Tanggal audit: 2026-10-20 · Basis: repo `monitoring-pkl-app` (Laravel 12 + Sanctum + PostgreSQL), 1 commit awal.

> **Keterbatasan:** halaman Figma hanya bisa diambil sebagai shell HTML (kanvas butuh login / Figma API token).
> Pemetaan layar di bawah mengikuti daftar layar pada spesifikasi MVP, **bukan** inspeksi frame Figma aktual.
> Perbandingan visual per-frame ditunda sampai ada akses (lihat "Blocker & keputusan").

## 1. Temuan arsitektur

| Aspek | Kondisi |
|---|---|
| Stack | Laravel 12, PHP ^8.2, Sanctum (token), PostgreSQL (`pgsql`), test memakai SQLite `:memory:` |
| Bentuk aplikasi | **API-only**. Tidak ada frontend: `resources/views` hanya `welcome.blade.php`, `resources/js/app.js` 22 byte |
| Paket tambahan | Tidak ada paket PDF/Excel (belum ada `dompdf`, `maatwebsite/excel`, dsb.) |
| Dokumentasi | `README.md` masih bawaan Laravel; hanya ada `docs/phase2_api_design.md` |
| Test | 48 test hijau (auth, otorisasi, presensi, jurnal, master data, integrasi Postgres) |

## 2. Fungsionalitas yang sudah berjalan

- **Auth:** login `username` / `email` / **NIS** / kode guru, throttle 10/menit, cek `is_active`, logout, `/me`. Password di-hash (`hashed` cast) dan `hidden` dari response.
- **RBAC:** `RoleMiddleware` (`admin|student|teacher|field_supervisor`) + query yang discope lewat `placement` (siswa/guru/pembimbing hanya melihat data miliknya; ada test lintas-akun).
- **Admin master data:** CRUD users, students, teachers, field supervisors, locations, periods, placements; hapus = nonaktifkan; reset password + revoke token; cegah placement aktif bentrok dalam satu periode; admin tidak bisa dibuat lewat endpoint user biasa.
- **Presensi:** check-in/out dengan Haversine di server, foto wajib, `accuracy` wajib, waktu pakai `now()` server, unique `(placement_id, attendance_date)` di DB, tolak check-in/out ganda.
- **Logbook (endpoint `/logbooks`; alias lama `journals` sudah dihapus):** draft → submitted → approved/rejected, edit/resubmit saat rejected, verifikasi oleh pembimbing lapangan.
- **Dashboard dasar** per role dengan angka dari query DB.
- **Skema siap tapi belum terpakai:** `activities`, `logbook_comments`, `leave_requests`, kolom verifikasi di `attendances`.

## 3. Fungsionalitas yang belum ada

| Modul | Gap |
|---|---|
| A. Admin | Tidak ada entitas **DUDI** tersendiri (hanya `locations` + `field_supervisors.organization`); tidak ada filter periode/kelas pada dashboard; tidak ada alur **persetujuan lokasi** (lokasi yang diajukan pembimbing langsung aktif) |
| B. Presensi | Lihat §4 (bug/konflik); belum ada endpoint verifikasi/koreksi pembimbing; belum ada aturan **jam batas terlambat** |
| C. Izin & Sakit | Hanya model + tabel. **Tidak ada** endpoint submit, review, unduh lampiran, maupun sinkronisasi ke rekap presensi |
| D. Logbook | Tidak ada field *rencana kegiatan*; tidak ada audit trail perubahan status; `logbook_comments` belum diekspos; guru belum bisa memberi feedback; label status belum memetakan ke "Menunggu review / Disetujui / Perlu revisi" |
| E. Projek siswa | **Belum ada sama sekali** (tabel, model, upload PDF 15 MB, verifikasi DUDI, riwayat) |
| F. Penilaian | **Belum ada** (nilai DUDI, nilai guru, nilai akhir, bobot 50:50, KKM 75, finalisasi) |
| G. Monitoring & laporan | Hanya daftar presensi mentah; tidak ada rekap, filter lengkap, maupun ekspor PDF/Excel |
| H. Profil | Hanya `PUT /student/profile`; **tidak ada** ganti password mandiri; tidak ada profil guru/pembimbing/admin |
| Pengaturan | Tidak ada tempat terpusat untuk radius, jam batas presensi, bobot nilai, KKM, batas upload |
| Frontend | Seluruh UI per role (login, dashboard, form, tabel) belum dibuat |
| Dokumentasi | Setup/migrasi/seed belum terdokumentasi; belum ada daftar perbedaan UI vs Figma |

## 4. Bug & konflik dengan spesifikasi

1. **Presensi di luar radius tidak tersimpan.** `AttendanceService` melempar exception 422 sebelum menyimpan apa pun → tidak ada jejak audit, dan bertentangan dengan `docs/phase2_api_design.md` (yang menyimpan `outside_radius`) serta kebutuhan status *rejected/invalid*.
2. **Kolom status presensi tidak pernah diisi.** `check_in_location_status`, `check_out_location_status`, `completeness_status`, `verification_status` tidak diset oleh service (hanya default DB), sehingga indikator "lokasi terverifikasi" tidak berdasar data.
3. **Tidak ada status `late`.** Enum `late` ada, tetapi service selalu mengisi `present` — tidak ada aturan jam batas.
4. **Foto presensi disimpan di disk `public`** (`attendances/check-in/...`) → bisa diakses lewat URL tanpa otorisasi; bertentangan dengan "lampiran/bukti privat harus dilindungi". Berlaku juga untuk foto logbook dan (nanti) lampiran izin.
5. **Dokumen vs kode tidak sinkron.** `phase2_api_design.md` menyebut `/supervisor/attendances/{id}/verify`, `/leave-requests`, `/teacher/logbooks/{id}/comments`, dll.; rute nyata masih `approve`/`reject` dan tidak ada endpoint tersebut.
6. **Pencarian memakai `ilike`** (khusus PostgreSQL) di controller admin, sementara test berjalan di SQLite → jalur pencarian tidak teruji.
7. **Data seed bertentangan dengan konteks sekolah:** `LocationSeeder` memakai lokasi Jakarta, sedangkan spesifikasi menyebut contoh sekolah di Bandar Lampung.
8. **`StudentResource` aman dari NISN/NIK/NIP** (hanya `nis`) — sudah sesuai; tidak ada kolom NISN di skema.
9. **Rate limit login 10/menit** berlaku juga pada test; test yang melakukan banyak login perlu menonaktifkan throttle.

## 5. Pemetaan layar → fitur (per role)

| Role | Layar (spesifikasi) | Endpoint tersedia | Endpoint perlu dibuat |
|---|---|---|---|
| Semua | Login, ganti password, profil | `POST /login`, `/me`, `/logout` | `PUT /me/password`, `GET/PUT /me/profile` per role |
| Admin | Dashboard | `GET /admin/dashboard` | filter periode/kelas |
| Admin | Master Siswa / Guru / DUDI | CRUD siswa, guru, field-supervisors, locations | entitas/resource **DUDI**, filter & validasi lanjutan |
| Admin | Akun & kredensial | users CRUD, reset-password | — |
| Admin | Penempatan | placements CRUD | assign pembimbing per DUDI, persetujuan lokasi |
| Admin | Laporan & ekspor | — | semua |
| Siswa | Dashboard | `GET /student/dashboard` | ringkasan izin, projek, nilai |
| Siswa | Presensi masuk/keluar/riwayat | check-in, check-out, list, show | simpan status invalid, jam batas, foto privat |
| Siswa | Izin & Sakit | — | submit, list, detail, lampiran |
| Siswa | Logbook | CRUD + submit | rencana kegiatan, riwayat status, komentar |
| Siswa | Projek | — | semua |
| Siswa | Nilai | — | tampil hasil akhir |
| Guru | Monitoring bimbingan, rekap hadir | students, attendances, journals | rekap, review/feedback logbook, izin, penilaian ujian/laporan |
| Pembimbing lapangan/DUDI | Monitoring presensi & izin | students, attendances, journals approve/reject | verifikasi presensi, review izin, verifikasi projek, penilaian DUDI |

## 6. Aturan bisnis yang belum jelas (butuh konfirmasi sekolah)

| # | Konflik / pertanyaan | Asumsi sementara (dipusatkan di config) |
|---|---|---|
| 1 | Jam batas presensi 08:00 (layar siswa) vs 08:30 (dashboard admin) | `attendance.late_after = 08:00` (configurable) |
| 2 | Total siswa/guru/DUDI berbeda antar layar | Selalu dihitung dari DB, tidak ada angka statis |
| 3 | Lokasi contoh Jakarta vs sekolah Bandar Lampung | Seed demo dipindah ke Bandar Lampung |
| 4 | Label NISN di Figma | Semua label & field memakai **NIS** |
| 5 | Bobot nilai 50:50 & KKM 75 | `assessment.weight_dudi = 50`, `weight_teacher = 50`, `kkm = 75` (configurable) |
| 6 | Batas PDF projek 15 MB | `uploads.project_pdf_max_kb = 15360` sampai dikonfirmasi |
| 7 | Siapa yang menyetujui izin (pembimbing lapangan, guru, atau admin)? | Pembimbing lapangan, sesuai dokumen Phase 2 |
| 8 | Siapa yang menyetujui logbook (guru atau pembimbing lapangan)? | Pembimbing lapangan menyetujui; guru memberi komentar |
| 9 | Presensi di luar radius: ditolak atau disimpan sebagai *invalid*? | Disimpan dengan status `outside_radius` agar teraudit |
| 10 | Stack frontend (Blade + Vite, atau SPA terpisah)? | **Perlu keputusan** |

## 7. Urutan implementasi yang diusulkan

1. **Fondasi (Phase 2):** config terpusat (`config/pkl.php`), migrasi tambahan (status presensi, izin, projek, penilaian, audit trail), disk privat + endpoint unduh terotorisasi.
2. **Core (Phase 3):** perbaiki presensi (simpan status lokasi/terlambat/invalid, jam batas), ganti password, entitas DUDI & alur persetujuan lokasi, seed demo Bandar Lampung.
3. **Alur harian (Phase 4):** izin & sakit → logbook (rencana, audit trail, komentar) → projek → penilaian.
4. **Pelaporan (Phase 5):** rekap, filter, ekspor PDF/Excel, dashboard dari DB.
5. **UI:** setelah keputusan stack dan akses Figma, bangun layar per role.
6. **Verifikasi (Phase 6):** test otorisasi lintas-role, presensi ganda, data tak valid, revisi; dokumentasikan setup.

## 8. Blocker & keputusan yang dibutuhkan

- **Akses Figma:** berikan Figma personal access token, atau ekspor frame (PNG/PDF) per role, agar pemetaan dan perbandingan UI akurat.
- **Stack frontend:** Blade + Vite (satu repo) atau SPA terpisah?
- **Konfirmasi aturan bisnis** pada §6 (terutama #1, #5, #7, #8).
