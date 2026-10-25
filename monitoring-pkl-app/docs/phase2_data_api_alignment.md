# Phase 2 — Data & API Alignment (SMART PKL MVP)

Melengkapi [phase1_audit.md](phase1_audit.md). Dokumen ini mendefinisikan skema, status, aturan bisnis terpusat, dan kontrak API yang **akan** diimplementasikan di Phase 3–5. Endpoint di §4 belum ada kecuali ditandai ✅.

## 1. Perubahan yang sudah diimplementasikan

| Area | Perubahan |
|---|---|
| Config | `config/pkl.php`: jam batas presensi, radius default, bobot nilai, KKM, batas upload, label status. Semua bisa di-override lewat `.env` (`PKL_*`) |
| `locations` | `approval_status` (default `approved` agar data lama aman), `approved_by`, `approved_at`, `approval_note` |
| `attendances` | `late_minutes` |
| `logbooks` | kolom `plan` (rencana kegiatan) |
| Tabel baru | `logbook_status_histories`, `project_submissions`, `project_reviews`, `assessments` |
| Model baru | `ProjectSubmission`, `ProjectReview`, `LogbookStatusHistory`, `Assessment` (+ relasi di `Placement`, `Logbook`) |
| Service | `GradeService` — satu-satunya tempat menghitung nilai akhir (bobot & KKM dari config) |
| Migrasi | `2026_10_20_010001_align_schema_for_mvp`, `2026_10_20_010002_create_projects_and_assessments_tables` |

Terverifikasi: migrasi berjalan di PostgreSQL (`monitoring_pkl_test`); 56 test hijau.

> Menjalankan di DB dev: `php artisan migrate` (aditif, tidak menghapus data).

## 2. Konfigurasi terpusat (asumsi sementara)

| Key | Env | Default | Catatan |
|---|---|---|---|
| `pkl.attendance.late_after` | `PKL_ATTENDANCE_LATE_AFTER` | `08:00` | Konflik Figma 08:00 vs 08:30 |
| `pkl.attendance.default_radius` | `PKL_GEOFENCE_DEFAULT_RADIUS` | `50` | meter |
| `pkl.attendance.max_gps_accuracy` | `PKL_MAX_GPS_ACCURACY` | `null` | tidak dipaksa sampai disepakati |
| `pkl.assessment.weight_dudi/teacher` | `PKL_WEIGHT_DUDI/TEACHER` | `50 / 50` | perlu konfirmasi sekolah |
| `pkl.assessment.kkm` | `PKL_KKM` | `75` | perlu konfirmasi sekolah |
| `pkl.uploads.project_pdf_max_kb` | `PKL_PROJECT_PDF_MAX_KB` | `15360` | 15 MB dari Figma |
| `pkl.uploads.disk` | `PKL_UPLOAD_DISK` | `local` | disk **privat** |

## 3. Transisi status

**Logbook** (`logbooks.status`; label UI dari `pkl.status_labels.logbook`)

```
draft ──submit──▶ submitted ──approve──▶ approved (final)
                      │
                      └──reject(+catatan wajib)──▶ rejected ──edit+resubmit──▶ submitted
```
Setiap perubahan dicatat di `logbook_status_histories`. `approved` tidak dapat diubah siswa.

**Izin & sakit** (`leave_requests.status`): `pending → approved | rejected`. Pengajuan ≠ persetujuan; hanya `approved` yang memengaruhi rekap presensi.

**Projek** (`project_submissions.status`): `draft → pending → approved | revision`; `revision → pending` saat siswa mengirim ulang. Tiap keputusan disimpan di `project_reviews`.

**Penilaian** (`assessments.status`): `draft → finalized`. Final hanya bisa jika `dudi_score` dan `teacher_score` terisi; saat finalisasi bobot & KKM di-snapshot ke baris. Koreksi setelah final hanya oleh admin.

**Lokasi** (`locations.approval_status`): `pending → approved | rejected`; hanya `approved` + `is_active` yang dipakai geofence.

**Presensi:** hasil lokasi disimpan sebagai `check_*_location_status` = `within_radius | outside_radius`; `status` = `present | late`; `verification_status` = `pending | approved | rejected`.

## 4. Kontrak API target

Semua response mengikuti format `{success, message, data}`; 422 untuk validasi; 403 untuk akses lintas data; waktu server `Asia/Jakarta`.

| Modul | Endpoint | Role | Status |
|---|---|---|---|
| Auth | `POST /login`, `POST /logout`, `GET /me` | semua | ✅ |
| Auth | `PUT /me/password` (password lama + baru) | semua | Phase 3 |
| Profil | `GET/PUT /me/profile` (field terbatas per role; NIS/kode guru read-only) | semua | Phase 3 (siswa ✅ sebagian) |
| Admin | Users (`GET /admin/users`, `GET/PUT/DELETE …/{id}`, `POST …/{id}/reset-password`) + CRUD students/teachers/field-supervisors/locations/periods/placements | admin | ✅ |
| Admin | `POST /admin/locations/{id}/approve\|reject` | admin | Phase 3 |
| Presensi | `POST /student/attendances/check-in\|check-out` (simpan status `outside_radius` & `late`) | siswa | ✅ perlu revisi Phase 3 |
| Presensi | `POST /supervisor/attendances/{id}/verify` | pembimbing lapangan | Phase 3 |
| Presensi | `GET /attendances/{id}/photo/{in\|out}` (stream, terotorisasi) | siswa pemilik, pembimbing, guru, admin | Phase 3 |
| Izin | `GET/POST /student/leave-requests`, `GET /leave-requests/{id}/attachment` | siswa | Phase 4 |
| Izin | `GET /supervisor/leave-requests`, `POST …/{id}/review` | pembimbing lapangan | Phase 4 |
| Logbook | `/student/logbooks…` | siswa | ✅ (+`plan`, riwayat di Phase 4) |
| Logbook | `POST /supervisor/logbooks/{id}/approve\|reject` | pembimbing lapangan | ✅ |
| Logbook | `GET/POST /logbooks/{id}/comments` | siswa, guru, pembimbing | Phase 4 |
| Projek | `GET/POST /student/projects`, `PUT …/{id}`, `POST …/{id}/submit`, `GET …/{id}/document` | siswa | Phase 4 |
| Projek | `GET /supervisor/projects`, `POST …/{id}/review` | pembimbing lapangan | Phase 4 |
| Nilai | `PUT /supervisor/assessments/{placement}` (komponen DUDI) | pembimbing lapangan | Phase 4 |
| Nilai | `PUT /teacher/assessments/{placement}` (komponen guru) | guru | Phase 4 |
| Nilai | `POST /admin/assessments/{placement}/finalize`, `GET /student/assessment` | admin / siswa | Phase 4 |
| Laporan | `GET /reports/attendance-summary`, `GET /reports/export?format=pdf\|xlsx` | admin, guru, pembimbing (discope) | Phase 5 |

Aturan lintas modul: semua query discope lewat `placement` (siswa → miliknya, guru → `teacher_id`, pembimbing → `field_supervisor_id`); tidak ada id dari klien yang dipercaya tanpa cek kepemilikan.

## 5. Gap yang masih terbuka

- Presensi masih menolak di luar radius dan belum mengisi status/terlambat (Phase 3, memakai config baru).
- Foto/lampiran masih di disk `public`; perlu pindah ke disk privat + endpoint stream (Phase 3).
- `phase2_api_design.md` (dokumen lama) masih berisi endpoint yang belum ada; dokumen ini adalah acuan terbaru untuk status implementasi.
- Seed lokasi masih Jakarta; akan diganti ke Bandar Lampung bersama data demo konsisten (Phase 3).
- Keputusan masih menunggu: stack frontend, akses Figma, konfirmasi aturan bisnis (lihat phase1_audit §6, §8).
