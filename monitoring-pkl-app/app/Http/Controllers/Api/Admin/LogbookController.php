<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\JournalResource;
use App\Models\Logbook;
use App\Traits\ApiResponse;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class LogbookController extends Controller
{
    use ApiResponse;

    /**
     * List all student logbooks with filters and recap statistics.
     */
    public function index(Request $request): JsonResponse
    {
        $query = Logbook::with([
            'placement.student.user',
            'placement.location',
            'placement.teacher.user',
            'verifier',
            'attendance',
        ]);

        // Search by student name, NIS, location name, or activity
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('placement.student', function ($sq) use ($search) {
                    $sq->where('name', 'ilike', "%{$search}%")
                       ->orWhere('nis', 'ilike', "%{$search}%");
                })->orWhereHas('placement.location', function ($lq) use ($search) {
                    $lq->where('name', 'ilike', "%{$search}%");
                })->orWhere('activity', 'ilike', "%{$search}%")
                  ->orWhere('description', 'ilike', "%{$search}%");
            });
        }

        // Filter by status
        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        // Filter by date
        if ($request->filled('date')) {
            $query->whereDate('logbook_date', $request->date);
        }

        // Filter by date range
        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('logbook_date', [$request->start_date, $request->end_date]);
        } elseif ($request->filled('start_date')) {
            $query->whereDate('logbook_date', '>=', $request->start_date);
        } elseif ($request->filled('end_date')) {
            $query->whereDate('logbook_date', '<=', $request->end_date);
        }

        // Filter by location
        if ($request->filled('location_id')) {
            $query->whereHas('placement', fn($q) => $q->where('location_id', $request->location_id));
        }

        // Calculate summary stats
        $summaryQuery = clone $query;
        $total = $summaryQuery->count();
        $approved = (clone $query)->where('status', 'approved')->count();
        $submitted = (clone $query)->where('status', 'submitted')->count();
        $rejected = (clone $query)->where('status', 'rejected')->count();
        $draft = (clone $query)->where('status', 'draft')->count();

        $logbooks = $query->latest('logbook_date')
            ->latest('id')
            ->paginate($request->get('per_page', 50));

        return $this->success([
            'logbooks' => JournalResource::collection($logbooks),
            'summary' => [
                'total' => $total,
                'approved' => $approved,
                'submitted' => $submitted,
                'rejected' => $rejected,
                'draft' => $draft,
            ],
            'pagination' => [
                'current_page' => $logbooks->currentPage(),
                'last_page' => $logbooks->lastPage(),
                'per_page' => $logbooks->perPage(),
                'total' => $logbooks->total(),
            ],
        ]);
    }

    /**
     * Delete a logbook record.
     */
    public function destroy(int $id): JsonResponse
    {
        $logbook = Logbook::findOrFail($id);
        $logbook->delete();

        return $this->success(null, 'Data logbook/jurnal berhasil dihapus.');
    }

    /**
     * Export logbook recap as CSV (Excel compatible).
     */
    public function export(Request $request): StreamedResponse
    {
        $query = Logbook::with([
            'placement.student',
            'placement.location',
            'placement.teacher',
            'verifier',
        ]);

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->whereHas('placement.student', function ($sq) use ($search) {
                    $sq->where('name', 'ilike', "%{$search}%")
                       ->orWhere('nis', 'ilike', "%{$search}%");
                })->orWhereHas('placement.location', function ($lq) use ($search) {
                    $lq->where('name', 'ilike', "%{$search}%");
                })->orWhere('activity', 'ilike', "%{$search}%")
                  ->orWhere('description', 'ilike', "%{$search}%");
            });
        }

        if ($request->filled('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->filled('date')) {
            $query->whereDate('logbook_date', $request->date);
        }

        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('logbook_date', [$request->start_date, $request->end_date]);
        }

        if ($request->filled('location_id')) {
            $query->whereHas('placement', fn($q) => $q->where('location_id', $request->location_id));
        }

        $records = $query->latest('logbook_date')->latest('id')->get();

        $headers = [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Content-Disposition' => 'attachment; filename="rekap_logbook_' . date('Ymd_His') . '.csv"',
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
                'Hari',
                'Tanggal',
                'NIS',
                'Nama Siswa',
                'Kelas / Jurusan',
                'DU/DI (Mitra Industri)',
                'Aktivitas / KD',
                'Deskripsi Pekerjaan',
                'Hasil Kegiatan',
                'Kendala',
                'Status Verifikasi',
                'Catatan Pembimbing / Reviewer',
                'Guru Pembimbing',
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
                $teacher = $item->placement?->teacher;

                $dateObj = $item->logbook_date ? Carbon::parse($item->logbook_date) : null;
                $dayName = $dateObj ? ($days[$dateObj->format('l')] ?? $dateObj->format('l')) : '-';
                $dateStr = $dateObj ? '="' . $dateObj->format('d/m/y') . '"' : '-';

                $statusMap = [
                    'approved' => 'Disetujui',
                    'submitted' => 'Menunggu Verifikasi',
                    'rejected' => 'Revisi / Ditolak',
                    'draft' => 'Draft',
                ];
                $statusText = $statusMap[$item->status] ?? ucfirst((string) $item->status);

                fputcsv($handle, [
                    $no++,
                    $dayName,
                    $dateStr,
                    $student?->nis ?? '-',
                    $student?->name ?? 'Siswa',
                    $student?->class ?? $student?->major ?? 'RPL',
                    $location?->name ?? '-',
                    $item->activity ?? '-',
                    $item->description ?? '-',
                    $item->result ?? '-',
                    $item->obstacles ?? '-',
                    $statusText,
                    $item->verification_note ?? '-',
                    $teacher?->name ?? '-',
                ]);
            }

            fclose($handle);
        };

        return response()->stream($callback, 200, $headers);
    }
}

