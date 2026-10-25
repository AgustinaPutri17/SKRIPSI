<?php

namespace App\Http\Controllers\Api\Student;

use App\Http\Controllers\Controller;
use App\Http\Requests\Student\CheckInRequest;
use App\Http\Requests\Student\CheckOutRequest;
use App\Http\Requests\Student\StoreJournalRequest;
use App\Http\Requests\Student\UpdateJournalRequest;
use App\Http\Requests\Student\UpdateProfileRequest;
use App\Http\Resources\AttendanceResource;
use App\Http\Resources\JournalResource;
use App\Http\Resources\LeaveRequestResource;
use App\Http\Resources\PlacementResource;
use App\Http\Resources\StudentResource;
use App\Models\Attendance;
use App\Models\Journal;
use App\Models\LeaveRequest;
use App\Services\AttendanceService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected AttendanceService $attendanceService
    ) {}

    // ── Profile ──

    public function profile(Request $request): JsonResponse
    {
        $student = $request->user()->student;

        if (!$student) {
            return $this->error('Profil siswa tidak ditemukan.', 404);
        }

        return $this->success(new StudentResource($student->load('user')));
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $student = $request->user()->student;

        if (!$student) {
            return $this->error('Profil siswa tidak ditemukan.', 404);
        }

        $student->update($request->validated());
        return $this->success(new StudentResource($student->fresh('user')), 'Profil berhasil diperbarui.');
    }

    // ── Placement ──

    public function placement(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Tidak ada penempatan aktif.', 404);
        }

        return $this->success(new PlacementResource(
            $placement->load(['location', 'period', 'teacher', 'fieldSupervisor'])
        ));
    }

    // ── Attendance ──

    public function attendances(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Tidak ada penempatan aktif.', 404);
        }

        $attendances = Attendance::where('placement_id', $placement->id)
            ->latest('attendance_date')
            ->paginate($request->get('per_page', 15));

        return $this->success([
            'attendances' => AttendanceResource::collection($attendances),
            'pagination' => [
                'current_page' => $attendances->currentPage(),
                'last_page' => $attendances->lastPage(),
                'per_page' => $attendances->perPage(),
                'total' => $attendances->total(),
            ],
        ]);
    }

    public function showAttendance(Request $request, int $id): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $attendance = Attendance::whereIn('placement_id', $placementIds)->findOrFail($id);

        return $this->success(new AttendanceResource($attendance));
    }

    public function checkIn(CheckInRequest $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Tidak ada penempatan aktif.', 422);
        }

        try {
            $attendance = $this->attendanceService->checkIn(
                $placement,
                $request->latitude,
                $request->longitude,
                $request->accuracy,
                $request->file('photo')
            );

            return $this->success(new AttendanceResource($attendance), 'Check-in berhasil.');
        } catch (\Exception $e) {
            $code = (int) $e->getCode();
            $status = ($code >= 400 && $code < 600) ? $code : 422;
            return $this->error($e->getMessage(), $status);
        }
    }

    public function checkOut(CheckOutRequest $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Tidak ada penempatan aktif.', 422);
        }

        try {
            $attendance = $this->attendanceService->checkOut(
                $placement,
                $request->latitude,
                $request->longitude,
                $request->accuracy,
                $request->file('photo')
            );

            return $this->success(new AttendanceResource($attendance), 'Check-out berhasil.');
        } catch (\Exception $e) {
            $code = (int) $e->getCode();
            $status = ($code >= 400 && $code < 600) ? $code : 422;
            return $this->error($e->getMessage(), $status);
        }
    }

    // ── Journal ──

    public function journals(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $query = Journal::whereIn('placement_id', $placementIds);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $journals = $query->latest('logbook_date')->paginate($request->get('per_page', 15));

        return $this->success([
            'journals' => JournalResource::collection($journals),
            'pagination' => [
                'current_page' => $journals->currentPage(),
                'last_page' => $journals->lastPage(),
                'per_page' => $journals->perPage(),
                'total' => $journals->total(),
            ],
        ]);
    }

    public function storeJournal(StoreJournalRequest $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Tidak ada penempatan aktif.', 422);
        }

        $data = $request->validated();
        $data['placement_id'] = $placement->id;
        $data['logbook_date'] = $request->getLogbookDate();

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $request->file('photo')->store('journals/' . now()->toDateString(), 'public');
        }

        // Remove 'photo' key as we stored it as 'photo_path'
        unset($data['photo']);

        // Tautkan dengan data presensi siswa hari ini jika ada
        $todayAttendance = Attendance::where('placement_id', $placement->id)
            ->whereDate('attendance_date', $data['logbook_date'])
            ->first();

        if ($todayAttendance) {
            $data['attendance_id'] = $todayAttendance->id;
        }

        $data['status'] = 'draft';

        $journal = Journal::create($data);

        return $this->created(new JournalResource($journal->fresh()));
    }

    public function showJournal(Request $request, int $id): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        return $this->success(new JournalResource($journal));
    }

    public function updateJournal(UpdateJournalRequest $request, int $id): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        if (!$journal->isEditable()) {
            return $this->error('Jurnal yang sudah diverifikasi tidak dapat diubah.', 422);
        }

        $data = $request->validated();

        if ($request->hasFile('photo')) {
            $data['photo_path'] = $request->file('photo')->store('journals/' . now()->toDateString(), 'public');
        }
        unset($data['photo']);

        $journal->update($data);

        return $this->success(new JournalResource($journal->fresh()), 'Jurnal berhasil diperbarui.');
    }

    public function destroyJournal(Request $request, int $id): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        if (!$journal->isEditable()) {
            return $this->error('Jurnal yang sudah diverifikasi tidak dapat dihapus.', 422);
        }

        $journal->delete();
        return $this->success(null, 'Jurnal berhasil dihapus.');
    }

    public function submitJournal(Request $request, int $id): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        if (!$journal->isEditable()) {
            return $this->error('Jurnal tidak dapat disubmit.', 422);
        }

        $updateData = [
            'status' => 'submitted',
            'submitted_at' => now(),
        ];

        // Tautkan otomatis attendance_id dari presensi jika belum ada
        if (!$journal->attendance_id) {
            $date = ($journal->logbook_date ?? $journal->journal_date)?->toDateString();
            $att = Attendance::where('placement_id', $journal->placement_id)
                ->whereDate('attendance_date', $date)
                ->first();
            if ($att) {
                $updateData['attendance_id'] = $att->id;
            }
        }

        $journal->update($updateData);

        return $this->success(new JournalResource($journal->fresh()), 'Jurnal berhasil disubmit.');
    }

    // ── Dashboard ──

    public function dashboard(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();
        $today = now()->toDateString();

        $todayAttendance = null;
        $journalStats = ['total' => 0, 'draft' => 0, 'submitted' => 0, 'approved' => 0, 'rejected' => 0];

        if ($placement) {
            $todayAttendance = Attendance::where('placement_id', $placement->id)
                ->where('attendance_date', $today)
                ->first();

            $placementIds = $student->placements()->pluck('id');
            $journalStats = [
                'total' => Journal::whereIn('placement_id', $placementIds)->count(),
                'draft' => Journal::whereIn('placement_id', $placementIds)->where('status', 'draft')->count(),
                'submitted' => Journal::whereIn('placement_id', $placementIds)->where('status', 'submitted')->count(),
                'approved' => Journal::whereIn('placement_id', $placementIds)->where('status', 'approved')->count(),
                'rejected' => Journal::whereIn('placement_id', $placementIds)->where('status', 'rejected')->count(),
            ];
        }

        return $this->success([
            'placement' => $placement ? new PlacementResource($placement->load(['location', 'period'])) : null,
            'attendance_today' => $todayAttendance ? new AttendanceResource($todayAttendance) : null,
            'journal_stats' => $journalStats,
        ]);
    }

    // ── Leave Requests (Izin & Sakit) ──

    public function leaveRequests(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placementIds = $student->placements()->pluck('id');

        $leaveRequests = LeaveRequest::with(['placement.student', 'placement.location', 'reviewer'])
            ->whereIn('placement_id', $placementIds)
            ->latest('created_at')
            ->get();

        return $this->success([
            'leave_requests' => LeaveRequestResource::collection($leaveRequests),
            'total' => $leaveRequests->count(),
        ]);
    }

    public function storeLeaveRequest(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Siswa belum memiliki penempatan PKL aktif.', 422);
        }

        $validated = $request->validate([
            'type' => 'required|string|in:sick,permission,urgent,sakit,izin',
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'reason' => 'required|string|max:1000',
            'attachment' => 'nullable|file|mimes:jpeg,png,jpg,pdf|max:5120',
        ]);

        $attachmentPath = null;
        if ($request->hasFile('attachment')) {
            $attachmentPath = $request->file('attachment')->store('leave-attachments/' . date('Y-m-d'), 'public');
        }

        $leaveRequest = LeaveRequest::create([
            'placement_id' => $placement->id,
            'type' => in_array(strtolower($validated['type']), ['sick', 'sakit']) ? 'sick' : 'permission',
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'],
            'reason' => $validated['reason'],
            'attachment_path' => $attachmentPath,
            'status' => 'pending',
        ]);

        return $this->success(
            new LeaveRequestResource($leaveRequest->load(['placement.student', 'placement.location'])),
            'Pengajuan izin/sakit berhasil dikirim ke Guru Pembimbing & Instruktur.',
            201
        );
    }
}
