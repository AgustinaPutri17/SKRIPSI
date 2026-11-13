<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\AttendanceResource;
use App\Models\Attendance;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AttendanceController extends Controller
{
    use ApiResponse;

    /**
     * List all student attendances with filters and recap statistics.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Attendance::with([
            'placement.student.user',
            'placement.location',
            'placement.teacher.user',
            'placement.period',
            'verifier',
        ]);

        // Search by student name, NIS, or location name
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('placement.student', function ($sq) use ($search) {
                    $sq->where('name', 'ilike', "%{$search}%")
                       ->orWhere('nis', 'ilike', "%{$search}%");
                })->orWhereHas('placement.location', function ($lq) use ($search) {
                    $lq->where('name', 'ilike', "%{$search}%");
                });
            });
        }

        // Filter by status
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        // Filter by specific date
        if ($request->filled('date')) {
            $query->whereDate('attendance_date', $request->date);
        }

        // Filter by date range
        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('attendance_date', [$request->start_date, $request->end_date]);
        } elseif ($request->filled('start_date')) {
            $query->whereDate('attendance_date', '>=', $request->start_date);
        } elseif ($request->filled('end_date')) {
            $query->whereDate('attendance_date', '<=', $request->end_date);
        }

        // Filter by location
        if ($request->filled('location_id')) {
            $query->whereHas('placement', fn($q) => $q->where('location_id', $request->location_id));
        }

        // Calculate summary stats
        $summaryQuery = clone $query;
        $total = $summaryQuery->count();
        $present = (clone $query)->where('status', 'present')->count();
        $late = (clone $query)->where('status', 'late')->count();
        $sick = (clone $query)->where('status', 'sick')->count();
        $leave = (clone $query)->where('status', 'leave')->count();
        $absent = (clone $query)->where('status', 'absent')->count();

        $attendances = $query->latest('attendance_date')
            ->latest('check_in_at')
            ->paginate($request->get('per_page', 50));

        return $this->success([
            'attendances' => AttendanceResource::collection($attendances),
            'summary' => [
                'total' => $total,
                'present' => $present,
                'late' => $late,
                'sick' => $sick,
                'leave' => $leave,
                'absent' => $absent,
            ],
            'pagination' => [
                'current_page' => $attendances->currentPage(),
                'last_page' => $attendances->lastPage(),
                'per_page' => $attendances->perPage(),
                'total' => $attendances->total(),
            ],
        ]);
    }

    /**
     * Delete an attendance record.
     */
    public function destroy(int $id): JsonResponse
    {
        $attendance = Attendance::findOrFail($id);
        $attendance->delete();

        return $this->success(null, 'Data presensi berhasil dihapus.');
    }

    /**
     * Export attendance recap as CSV (Excel compatible).
     */
    public function export(Request $request): StreamedResponse
    {
        $query = Attendance::with([
            'placement.student',
            'placement.location',
            'placement.teacher',
        ]);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('placement.student', function ($sq) use ($search) {
                    $sq->where('name', 'ilike', "%{$search}%")
                       ->orWhere('nis', 'ilike', "%{$search}%");
                })->orWhereHas('placement.location', function ($lq) use ($search) {
                    $lq->where('name', 'ilike', "%{$search}%");
                });
            });
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('date')) {
            $query->whereDate('attendance_date', $request->date);
        }

        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('attendance_date', [$request->start_date, $request->end_date]);
        }

        if ($request->filled('location_id')) {
            $query->whereHas('placement', fn($q) => $q->where('location_id', $request->location_id));
        }

        $records = $query->latest('attendance_date')->latest('check_in_at')->get();

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="rekap_kehadiran_' . date('Ymd_His') . '.csv"',
            'Pragma' => 'no-cache',
            'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
            'Expires' => '0',
        ];

        $callback = function () use ($records) {
            $handle = fopen('php://output', 'w');

            // UTF-8 BOM for Excel compatibility
            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            // Header row
            fputcsv($handle, [
                'No',
                'Hari / Tanggal',
                'NIS',
                'Nama Siswa',
                'Kelas / Jurusan',
                'DU/DI (Mitra Industri)',
                'Jam Masuk',
                'Jam Pulang',
                'Status Kehadiran',
                'Keterangan',
            ]);

            $no = 1;
            $days = [
                'Sunday' => 'Minggu',
                'Monday' => 'Senin',
                'Tuesday' => 'Selasa',
                'Wednesday' => 'Rabu',
                'Thursday' => 'Kamis',
                'Friday' => 'Jumat',
                'Saturday' => 'Sabtu',
            ];

            foreach ($records as $item) {
                $student = $item->placement?->student;
                $location = $item->placement?->location;

                $dateObj = $item->attendance_date ? Carbon::parse($item->attendance_date) : null;
                $dayName = $dateObj ? ($days[$dateObj->format('l')] ?? $dateObj->format('l')) : '-';
                $hariTanggalStr = $dateObj ? ($dayName . ', ' . $dateObj->format('d/m/y')) : '-';

                $checkInTime = $item->check_in_at ? Carbon::parse($item->check_in_at)->format('H:i:s') : '-';
                $checkOutTime = $item->check_out_at ? Carbon::parse($item->check_out_at)->format('H:i:s') : '-';

                $rawNotes = (string) ($item->notes ?? '');
                if ($item->status === 'excused') {
                    $statusText = stripos($rawNotes, '(sick)') !== false ? 'Sakit' : 'Izin';
                } else {
                    $statusMap = [
                        'present' => 'Hadir Tepat Waktu',
                        'late' => 'Terlambat',
                        'sick' => 'Sakit',
                        'leave' => 'Izin',
                        'absent' => 'Alpha',
                    ];
                    $statusText = $statusMap[$item->status] ?? ucfirst((string) $item->status);
                }

                // Bersihkan keterangan agar tidak mengulang info menit terlambat atau prefix sistem
                $cleanNotes = '-';
                if (trim($rawNotes) !== '') {
                    if (str_starts_with($rawNotes, 'Terlambat ')) {
                        $cleanNotes = '-';
                    } elseif (preg_match('/^Izin\/Sakit\s*\([^)]+\):\s*(.+)$/i', $rawNotes, $m)) {
                        $cleanNotes = trim($m[1]);
                    } else {
                        $cleanNotes = $rawNotes;
                    }
                }

                fputcsv($handle, [
                    $no++,
                    $hariTanggalStr,
                    $student?->nis ?? '-',
                    $student?->name ?? 'Siswa',
                    $student?->class ?? $student?->major ?? 'RPL',
                    $location?->name ?? '-',
                    $checkInTime,
                    $checkOutTime,
                    $statusText,
                    $cleanNotes,
                ]);
            }

            fclose($handle);
        };

        return response()->stream($callback, 200, $headers);
    }
}

