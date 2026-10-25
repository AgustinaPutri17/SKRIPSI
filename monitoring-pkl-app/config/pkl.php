<?php

/*
|--------------------------------------------------------------------------
| SMART PKL business rules (single source of truth)
|--------------------------------------------------------------------------
| Values below are PROVISIONAL assumptions for conflicts found in the Figma
| design (see docs/phase1_audit.md §6). Override via .env until the school
| confirms the final policy. Never hardcode these in controllers or UI.
*/

return [

    'timezone' => env('PKL_TIMEZONE', 'Asia/Jakarta'),

    'attendance' => [
        // Check-in after this time (server time, WIB) is marked "late".
        // Figma conflict: 08:00 (student screen) vs 08:30 (admin dashboard).
        'late_after' => env('PKL_ATTENDANCE_LATE_AFTER', '08:00'),

        // Fallback geofence radius (meters) when a location does not define one.
        'default_radius' => (int) env('PKL_GEOFENCE_DEFAULT_RADIUS', 50),

        // Reject GPS fixes less precise than this (meters). null = do not enforce.
        'max_gps_accuracy' => env('PKL_MAX_GPS_ACCURACY') !== null
            ? (int) env('PKL_MAX_GPS_ACCURACY')
            : null,
    ],

    'assessment' => [
        // Provisional initial policy shown in Figma: 50% DUDI + 50% teacher, KKM 75.
        'weight_dudi' => (float) env('PKL_WEIGHT_DUDI', 50),
        'weight_teacher' => (float) env('PKL_WEIGHT_TEACHER', 50),
        'kkm' => (float) env('PKL_KKM', 75),
        'min_score' => 0,
        'max_score' => 100,
    ],

    'uploads' => [
        'disk' => env('PKL_UPLOAD_DISK', 'local'), // private disk (storage/app/private)
        'photo_max_kb' => (int) env('PKL_PHOTO_MAX_KB', 5120),
        'leave_attachment_max_kb' => (int) env('PKL_LEAVE_MAX_KB', 5120),
        // Figma mockup shows 15 MB; confirm with the school.
        'project_pdf_max_kb' => (int) env('PKL_PROJECT_PDF_MAX_KB', 15360),
    ],

    // Canonical status vocabularies (DB value => Indonesian UI label).
    'status_labels' => [
        'logbook' => [
            'draft' => 'Draft',
            'submitted' => 'Menunggu review',
            'approved' => 'Disetujui',
            'rejected' => 'Perlu revisi',
        ],
        'leave' => [
            'pending' => 'Menunggu',
            'approved' => 'Disetujui',
            'rejected' => 'Ditolak',
        ],
        'project' => [
            'draft' => 'Draft',
            'pending' => 'Menunggu verifikasi',
            'approved' => 'Disetujui',
            'revision' => 'Perlu revisi',
        ],
        'attendance_location' => [
            'within_radius' => 'Di dalam radius',
            'outside_radius' => 'Di luar radius',
        ],
    ],
];
