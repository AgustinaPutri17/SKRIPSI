<?php

namespace App\Http\Controllers\Api\Teacher;

use App\Http\Controllers\Controller;
use App\Http\Resources\AttendanceResource;
use App\Http\Resources\JournalResource;
use App\Http\Resources\LeaveRequestResource;
use App\Http\Resources\StudentResource;
use App\Models\Attendance;
use App\Models\Journal;
use App\Models\LeaveRequest;
use App\Models\Placement;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TeacherController extends Controller
{
    use ApiResponse;

    /**
     * Get placement IDs for the authenticated teacher.
     */
    private function getTeacherPlacementIds(Request $request): array
    {
        $teacher = $request->user()->teacher;
        return $teacher ? $teacher->placements()->pluck('id')->toArray() : [];
    }

    /**
     * List students under this teacher's supervision.
     */
    public function students(Request $request): JsonResponse
    {
        $teacher = $request->user()->teacher;
        if (!$teacher) {
            return $this->success(['students' => [], 'total' => 0]);
        }

        $placements = Placement::with(['student.user', 'location', 'period', 'fieldSupervisor.user'])
            ->where('teacher_id', $teacher->id)
            ->where('status', 'active')
            ->get();

        $today = now()->toDateString();

        $students = $placements->map(function ($placement) use ($today) {
            $student = $placement->student;
            if (!$student) return null;

            $attendanceToday = Attendance::where('placement_id', $placement->id)
                ->where('attendance_date', $today)
                ->first();

            $leaveToday = LeaveRequest::where('placement_id', $placement->id)
                ->where('start_date', '<=', $today)
                ->where('end_date', '>=', $today)
                ->first();

            $avatarUrl = null;
            if ($student->user && $student->user->avatar_path) {
                $avatarUrl = asset('storage/' . $student->user->avatar_path);
            }

            return [
                'id' => $student->id,
                'user_id' => $student->user_id,
                'name' => $student->user?->name ?? $student->name,
                'nis' => $student->nis,
                'nisn' => $student->nisn ?? $student->nis,
                'class' => $student->class,
                'major' => $student->major,
                'phone' => $student->phone,
                'avatar_url' => $avatarUrl,
                'placement_id' => $placement->id,
                'placement' => [
                    'id' => $placement->id,
                    'status' => $placement->status,
                    'start_date' => $placement->start_date?->toDateString(),
                    'end_date' => $placement->end_date?->toDateString(),
                    'location' => $placement->location ? [
                        'id' => $placement->location->id,
                        'name' => $placement->location->name,
                        'address' => $placement->location->address,
                    ] : null,
                    'field_supervisor' => $placement->fieldSupervisor ? [
                        'id' => $placement->fieldSupervisor->id,
                        'name' => $placement->fieldSupervisor->user?->name ?? $placement->fieldSupervisor->name,
                        'phone' => $placement->fieldSupervisor->phone,
                    ] : null,
                ],
                'location' => $placement->location ? [
                    'id' => $placement->location->id,
                    'name' => $placement->location->name,
                    'address' => $placement->location->address,
                ] : null,
                'field_supervisor' => $placement->fieldSupervisor ? [
                    'id' => $placement->fieldSupervisor->id,
                    'name' => $placement->fieldSupervisor->user?->name ?? $placement->fieldSupervisor->name,
                    'phone' => $placement->fieldSupervisor->phone,
                ] : null,
                'attendance_today' => $attendanceToday ? [
                    'id' => $attendanceToday->id,
                    'status' => $attendanceToday->status,
                    'check_in_at' => $attendanceToday->check_in_at,
                    'check_out_at' => $attendanceToday->check_out_at,
                    'check_in_photo_url' => $attendanceToday->check_in_photo_path ? asset('storage/' . $attendanceToday->check_in_photo_path) : null,
                    'check_out_photo_url' => $attendanceToday->check_out_photo_path ? asset('storage/' . $attendanceToday->check_out_photo_path) : null,
                    'notes' => $attendanceToday->notes,
                ] : null,
                'leave_today' => $leaveToday ? [
                    'id' => $leaveToday->id,
                    'type' => $leaveToday->type,
                    'status' => $leaveToday->status,
                    'reason' => $leaveToday->reason,
                    'start_date' => $leaveToday->start_date?->toDateString(),
                    'end_date' => $leaveToday->end_date?->toDateString(),
                ] : null,
            ];
        })->filter()->values();

        return $this->success([
            'students' => $students,
            'total' => $students->count(),
        ]);
    }

    /**
     * Show specific student detail.
     */
    public function showStudent(Request $request, int $id): JsonResponse
    {
        $teacher = $request->user()->teacher;
        $placement = Placement::with(['student.user', 'location', 'period', 'fieldSupervisor.user'])
            ->where('teacher_id', $teacher->id)
            ->where('student_id', $id)
            ->firstOrFail();

        return $this->success(new StudentResource($placement->student->load('user')));
    }

    /**
     * List attendances of students under this teacher.
     */
    public function attendances(Request $request): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $query = Attendance::with(['placement.student.user', 'placement.location', 'placement.fieldSupervisor.user'])
            ->whereIn('placement_id', $placementIds);

        if ($request->has('date') && !empty($request->date)) {
            $query->where('attendance_date', $request->date);
        } elseif ($request->boolean('today')) {
            $query->where('attendance_date', now()->toDateString());
        }

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        if ($request->has('student_id')) {
            $query->whereHas('placement', fn($q) => $q->where('student_id', $request->student_id));
        }

        $attendances = $query->latest('attendance_date')
            ->latest('check_in_at')
            ->paginate($request->get('per_page', 50));

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

    /**
     * List journals of students under this teacher.
     */
    public function journals(Request $request): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $query = Journal::with(['placement.student', 'placement.location', 'verifier'])
            ->whereIn('placement_id', $placementIds);

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }
        if ($request->has('student_id')) {
            $query->whereHas('placement', fn($q) => $q->where('student_id', $request->student_id));
        }

        $journals = $query->latest('logbook_date')
            ->paginate($request->get('per_page', 50));

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

    /**
     * Show specific journal detail for teacher.
     */
    public function showJournal(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);
        $journal = Journal::with(['placement.student', 'placement.location', 'verifier'])
            ->whereIn('placement_id', $placementIds)
            ->findOrFail($id);

        return $this->success(new JournalResource($journal));
    }

    /**
     * Teacher approves student logbook.
     */
    public function approveJournal(VerifyJournalRequest $request, int $id): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);
        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        $journal->update([
            'status' => 'approved',
            'verified_at' => now(),
            'verified_by' => $request->user()->id,
            'verification_comment' => $request->comment ?? 'Disetujui oleh Guru Pembimbing',
        ]);

        return $this->success(
            new JournalResource($journal->fresh(['placement.student', 'placement.location', 'verifier'])),
            'Logbook siswa berhasil di-ACC (disetujui).'
        );
    }

    /**
     * Teacher rejects student logbook with comment.
     */
    public function rejectJournal(VerifyJournalRequest $request, int $id): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);
        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        $journal->update([
            'status' => 'rejected',
            'verified_at' => now(),
            'verified_by' => $request->user()->id,
            'verification_comment' => $request->comment ?? 'Perlu revisi',
        ]);

        return $this->success(
            new JournalResource($journal->fresh(['placement.student', 'placement.location', 'verifier'])),
            'Logbook siswa dikembalikan untuk direvisi.'
        );
    }

    /**
     * Teacher adds guidance note / comment to student logbook.
     */
    public function addComment(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'comment' => 'required|string|max:1000',
        ]);

        $placementIds = $this->getTeacherPlacementIds($request);
        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        \App\Models\LogbookComment::updateOrCreate(
            [
                'logbook_id' => $journal->id,
                'user_id' => $request->user()->id,
            ],
            [
                'comment' => $request->comment,
            ]
        );

        return $this->success(
            new JournalResource($journal->fresh(['comments.user', 'placement.student', 'placement.location', 'verifier'])),
            'Catatan bimbingan berhasil disimpan dan dikirim ke siswa.'
        );
    }

    /**
     * Teacher dashboard statistics.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);
        $today = now()->toDateString();

        $totalStudents = Placement::whereIn('id', $placementIds)->where('status', 'active')->count();

        $attendanceToday = Attendance::whereIn('placement_id', $placementIds)
            ->where('attendance_date', $today)
            ->whereIn('status', ['present', 'late'])
            ->count();

        // Jumlah siswa izin/sakit hari ini (status excused di presensi ATAU permohonan izin yang aktif hari ini)
        $leaveTodayFromAttendance = Attendance::whereIn('placement_id', $placementIds)
            ->where('attendance_date', $today)
            ->where('status', 'excused')
            ->count();

        $activeLeavesCount = LeaveRequest::whereIn('placement_id', $placementIds)
            ->where('start_date', '<=', $today)
            ->where('end_date', '>=', $today)
            ->count();

        $countIzinSakit = max($leaveTodayFromAttendance, $activeLeavesCount);

        $leavePending = LeaveRequest::whereIn('placement_id', $placementIds)
            ->where('status', 'pending')
            ->count();

        $journalsPending = Journal::whereIn('placement_id', $placementIds)
            ->where('status', 'submitted')
            ->count();

        return $this->success([
            'total_students' => $totalStudents,
            'attendance_today' => $attendanceToday,
            'leave_today' => $countIzinSakit,
            'leave_pending' => $leavePending,
            'journals_pending' => $journalsPending,
        ]);
    }

    /**
     * List leave / sick requests of students under this teacher.
     */
    public function leaveRequests(Request $request): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $query = LeaveRequest::with(['placement.student.user', 'placement.location', 'placement.fieldSupervisor.user', 'reviewer'])
            ->whereIn('placement_id', $placementIds);

        if ($request->has('status') && $request->status !== 'all') {
            $query->where('status', $request->status);
        }

        $leaveRequests = $query->latest('created_at')->get();

        return $this->success([
            'leave_requests' => LeaveRequestResource::collection($leaveRequests),
            'total' => $leaveRequests->count(),
        ]);
    }

    /**
     * Teacher approves or rejects leave / sick request.
     */
    public function verifyLeaveRequest(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|in:approved,rejected',
            'note' => 'nullable|string|max:500',
        ]);

        $placementIds = $this->getTeacherPlacementIds($request);
        $leaveRequest = LeaveRequest::with(['placement.student', 'placement.location'])
            ->whereIn('placement_id', $placementIds)
            ->findOrFail($id);

        $leaveRequest->update([
            'status' => $request->status,
            'reviewed_by' => $request->user()->id,
            'reviewed_at' => now(),
            'reviewer_note' => $request->note ?? ($request->status === 'approved' ? 'Pengajuan izin/sakit disetujui.' : 'Pengajuan izin/sakit ditolak.'),
        ]);

        // Jika disetujui, otomatis sinkronkan data di tabel attendances (status = excused) untuk rentang tanggal
        if ($request->status === 'approved') {
            $startDate = $leaveRequest->start_date ? \Carbon\Carbon::parse($leaveRequest->start_date) : now();
            $endDate = $leaveRequest->end_date ? \Carbon\Carbon::parse($leaveRequest->end_date) : $startDate;

            $current = $startDate->copy();
            while ($current->lte($endDate)) {
                Attendance::updateOrCreate(
                    [
                        'placement_id' => $leaveRequest->placement_id,
                        'attendance_date' => $current->toDateString(),
                    ],
                    [
                        'status' => 'excused',
                        'notes' => 'Izin/Sakit (' . $leaveRequest->type . '): ' . ($leaveRequest->reason ?? 'Disetujui guru pembimbing'),
                    ]
                );
                $current->addDay();
            }
        }

        return $this->success(
            new LeaveRequestResource($leaveRequest->fresh(['placement.student.user', 'placement.location', 'reviewer'])),
            $request->status === 'approved' ? 'Pengajuan izin/sakit berhasil disetujui.' : 'Pengajuan izin/sakit berhasil ditolak.'
        );
    }
}

