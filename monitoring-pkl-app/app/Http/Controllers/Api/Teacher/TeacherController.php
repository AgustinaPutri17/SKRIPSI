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
use App\Models\ProjectReview;
use App\Models\ProjectSubmission;
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
        $todayWib = \Carbon\Carbon::now('Asia/Jakarta')->toDateString();
        $todayUtc = \Carbon\Carbon::now('UTC')->toDateString();
        $today = $todayWib;
        $possibleDates = array_values(array_unique([$todayWib, $todayUtc]));

        $activePlacements = Placement::with(['student.user', 'location'])
            ->whereIn('id', $placementIds)
            ->where('status', 'active')
            ->get();

        $totalStudents = $activePlacements->count();
        $dudiCount = $activePlacements->pluck('location_id')->unique()->filter()->count();

        $attendanceToday = Attendance::whereIn('placement_id', $placementIds)
            ->where(function ($q) use ($possibleDates, $todayWib, $todayUtc) {
                $q->whereIn('attendance_date', $possibleDates)
                  ->orWhereDate('attendance_date', $todayWib)
                  ->orWhereDate('attendance_date', $todayUtc)
                  ->orWhereDate('check_in_at', $todayWib)
                  ->orWhereDate('check_in_at', $todayUtc)
                  ->orWhereDate('created_at', $todayWib)
                  ->orWhereDate('created_at', $todayUtc);
            })
            ->where(function ($q) {
                $q->whereNotNull('check_in_at')
                  ->orWhereIn('status', ['present', 'late', 'approved']);
            })
            ->count();

        // Jumlah siswa izin/sakit hari ini (status excused di presensi ATAU permohonan izin yang aktif hari ini)
        $leaveTodayFromAttendance = Attendance::whereIn('placement_id', $placementIds)
            ->where(function ($q) use ($possibleDates, $todayWib, $todayUtc) {
                $q->whereIn('attendance_date', $possibleDates)
                  ->orWhereDate('attendance_date', $todayWib)
                  ->orWhereDate('attendance_date', $todayUtc);
            })
            ->where('status', 'excused')
            ->count();

        $activeLeavesCount = LeaveRequest::whereIn('placement_id', $placementIds)
            ->where('start_date', '<=', $todayWib)
            ->where('end_date', '>=', $todayWib)
            ->count();

        $countIzinSakit = max($leaveTodayFromAttendance, $activeLeavesCount);

        $leavePending = LeaveRequest::whereIn('placement_id', $placementIds)
            ->where('status', 'pending')
            ->count();

        $journalsPending = Journal::whereIn('placement_id', $placementIds)
            ->where('status', 'submitted')
            ->count();

        // 1. Rata-rata Kehadiran Bulan Ini
        $monthStart = now()->startOfMonth()->toDateString();
        $monthEnd = now()->endOfMonth()->toDateString();
        $totalMonthlyRecords = Attendance::whereIn('placement_id', $placementIds)
            ->whereBetween('attendance_date', [$monthStart, $monthEnd])
            ->count();
        $presentMonthlyRecords = Attendance::whereIn('placement_id', $placementIds)
            ->whereBetween('attendance_date', [$monthStart, $monthEnd])
            ->whereIn('status', ['present', 'late'])
            ->count();
        $monthlyAttendanceRate = $totalMonthlyRecords > 0 ? (int) round(($presentMonthlyRecords / $totalMonthlyRecords) * 100) : 0;

        // 2. Kehadiran Minggu Ini (Senin s/d Jumat)
        $startOfWeek = now()->startOfWeek();
        $weeklyAttendance = [];
        $dayNames = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'];
        for ($i = 0; $i < 5; $i++) {
            $dayDate = $startOfWeek->copy()->addDays($i)->toDateString();
            $isFuture = $dayDate > $today;
            $count = $isFuture ? null : Attendance::whereIn('placement_id', $placementIds)
                ->where('attendance_date', $dayDate)
                ->whereIn('status', ['present', 'late'])
                ->count();
            $weeklyAttendance[] = [
                'day' => $dayNames[$i],
                'date' => $dayDate,
                'count' => $count,
                'total' => $totalStudents,
                'is_today' => $dayDate === $today,
                'is_future' => $isFuture,
            ];
        }

        // 3. Item "Perlu Perhatian"
        $attentionItems = [];
        $attendedPlacementIdsToday = Attendance::whereIn('placement_id', $placementIds)
            ->where('attendance_date', $today)
            ->pluck('placement_id')
            ->toArray();

        $currentTime = now();
        foreach ($activePlacements as $p) {
            if (!in_array($p->id, $attendedPlacementIdsToday)) {
                $checkInTimeStr = $p->location?->check_in_time ? substr($p->location->check_in_time, 0, 5) : '08:00';
                $limitTime = \Carbon\Carbon::parse($today . ' ' . $checkInTimeStr);
                // Siswa belum absen masuk dan telah melewati batas jam masuk
                if ($currentTime->gt($limitTime)) {
                    $attentionItems[] = [
                        'type' => 'late_unattended',
                        'student_id' => $p->student_id,
                        'student_name' => $p->student?->user?->name ?? 'Siswa',
                        'student_phone' => $p->student?->phone ?? $p->student?->user?->phone,
                        'location_name' => $p->location?->name ?? 'DU/DI',
                        'check_in_limit' => $checkInTimeStr,
                        'message' => "Belum absen masuk · lewat batas {$checkInTimeStr}",
                        'action' => 'hubungi',
                    ];
                }
            }
        }

        // Pengajuan izin/sakit yang menunggu persetujuan
        $pendingLeaves = LeaveRequest::with(['placement.student.user'])
            ->whereIn('placement_id', $placementIds)
            ->where('status', 'pending')
            ->latest()
            ->take(5)
            ->get();
        foreach ($pendingLeaves as $l) {
            $attentionItems[] = [
                'type' => 'pending_leave',
                'id' => $l->id,
                'student_name' => $l->placement?->student?->user?->name ?? 'Siswa',
                'leave_type' => $l->type === 'sick' ? 'sakit' : 'izin',
                'message' => 'Pengajuan ' . ($l->type === 'sick' ? 'sakit' : 'izin') . ' menunggu persetujuan',
                'action' => 'tinjau',
            ];
        }

        // Logbook yang belum diulas guru
        if ($journalsPending > 0) {
            $attentionItems[] = [
                'type' => 'pending_logbooks',
                'count' => $journalsPending,
                'student_name' => "{$journalsPending} logbook belum diulas",
                'message' => 'Menunggu catatan dan verifikasi guru pembimbing',
                'action' => 'lihat',
            ];
        }

        // 4. Aktivitas Terbaru
        $recentActivities = Attendance::with(['placement.student.user', 'placement.location'])
            ->whereIn('placement_id', $placementIds)
            ->latest('attendance_date')
            ->latest('check_in_at')
            ->take(6)
            ->get()
            ->map(function ($a) {
                $time = $a->check_in_at ? \Carbon\Carbon::parse($a->check_in_at)->format('H:i') . ' WIB' : 'Belum absen';
                return [
                    'id' => $a->id,
                    'type' => 'attendance',
                    'student_name' => $a->placement?->student?->user?->name ?? 'Siswa',
                    'location_name' => $a->placement?->location?->name ?? 'DU/DI',
                    'time' => $time,
                    'date' => $a->attendance_date?->toDateString(),
                    'status' => $a->status,
                    'status_label' => $a->status === 'present' ? 'Hadir Tepat Waktu' : ($a->status === 'late' ? 'Terlambat' : 'Izin/Sakit'),
                ];
            });

        // 5. Progres Logbook per Siswa
        $studentLogbookProgress = $activePlacements->map(function ($p) {
            $journals = Journal::where('placement_id', $p->id)->get();
            return [
                'student_id' => $p->student_id,
                'student_name' => $p->student?->user?->name ?? 'Siswa',
                'location_name' => $p->location?->name ?? 'DU/DI',
                'total_filled' => $journals->count(),
                'approved' => $journals->where('status', 'approved')->count(),
                'rejected' => $journals->where('status', 'rejected')->count(),
                'pending' => $journals->where('status', 'submitted')->count(),
            ];
        });

        return $this->success([
            'total_students' => $totalStudents,
            'dudi_count' => $dudiCount,
            'attendance_today' => $attendanceToday,
            'leave_today' => $countIzinSakit,
            'leave_pending' => $leavePending,
            'journals_pending' => $journalsPending,
            'unattended_today' => max(0, $totalStudents - $attendanceToday - $countIzinSakit),
            'monthly_attendance_rate' => $monthlyAttendanceRate,
            'weekly_attendance' => $weeklyAttendance,
            'attention_items' => $attentionItems,
            'recent_activities' => $recentActivities,
            'student_logbook_progress' => $studentLogbookProgress,
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

    /**
     * Get list of project submissions of students supervised by this teacher.
     */
    public function getProjects(Request $request): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $submissions = ProjectSubmission::with(['placement.student.user', 'placement.location', 'reviews.reviewer'])
            ->whereIn('placement_id', $placementIds)
            ->where('status', '!=', 'draft')
            ->latest('updated_at')
            ->get();

        $data = $submissions->map(function ($sub) {
            $student = $sub->placement?->student;
            return [
                'id' => $sub->id,
                'placement_id' => $sub->placement_id,
                'student' => $student ? [
                    'id' => $student->id,
                    'name' => $student->user->name ?? $student->name,
                    'nis' => $student->nis,
                    'class' => $student->class,
                    'major' => $student->major,
                    'location' => $sub->placement?->location?->name,
                ] : null,
                'title' => $sub->title,
                'description' => $sub->description,
                'plan' => $sub->plan,
                'result' => $sub->result,
                'document_name' => $sub->document_name,
                'document_size' => $sub->document_size,
                'document_url' => $sub->document_name ? url('/api/projects/' . $sub->id . '/document') : ($sub->document_path ? asset('storage/' . $sub->document_path) : null),
                'status' => $sub->status,
                'submitted_at' => $sub->submitted_at?->toIso8601String(),
                'updated_at' => $sub->updated_at?->toIso8601String(),
                'reviews' => $sub->reviews->map(function ($r) {
                    $role = $r->reviewer?->role;
                    return [
                        'id' => $r->id,
                        'decision' => $r->decision,
                        'note' => $r->note,
                        'reviewer_name' => $r->reviewer?->name,
                        'reviewer_role' => $role,
                        'reviewer_role_label' => $role === 'teacher' ? 'Guru Pembimbing Sekolah' : 'Pembimbing Lapangan (DU/DI)',
                        'created_at' => $r->created_at?->toIso8601String(),
                    ];
                }),
            ];
        });

        return $this->success($data);
    }

    /**
     * Detail of a student's project submission for teacher.
     */
    public function showProject(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $sub = ProjectSubmission::with(['placement.student.user', 'placement.location', 'reviews.reviewer'])
            ->whereIn('placement_id', $placementIds)
            ->findOrFail($id);

        $student = $sub->placement?->student;

        return $this->success([
            'id' => $sub->id,
            'placement_id' => $sub->placement_id,
            'student' => $student ? [
                'id' => $student->id,
                'name' => $student->user->name ?? $student->name,
                'nis' => $student->nis,
                'class' => $student->class,
                'major' => $student->major,
                'location' => $sub->placement?->location?->name,
            ] : null,
            'title' => $sub->title,
            'description' => $sub->description,
            'plan' => $sub->plan,
            'result' => $sub->result,
            'document_name' => $sub->document_name,
            'document_size' => $sub->document_size,
            'document_url' => $sub->document_name ? url('/api/projects/' . $sub->id . '/document') : ($sub->document_path ? asset('storage/' . $sub->document_path) : null),
            'status' => $sub->status,
            'submitted_at' => $sub->submitted_at?->toIso8601String(),
            'updated_at' => $sub->updated_at?->toIso8601String(),
            'reviews' => $sub->reviews->map(function ($r) {
                $role = $r->reviewer?->role;
                return [
                    'id' => $r->id,
                    'decision' => $r->decision,
                    'note' => $r->note,
                    'reviewer_name' => $r->reviewer?->name,
                    'reviewer_role' => $role,
                    'reviewer_role_label' => $role === 'teacher' ? 'Guru Pembimbing Sekolah' : 'Pembimbing Lapangan (DU/DI)',
                    'created_at' => $r->created_at?->toIso8601String(),
                ];
            }),
        ]);
    }

    /**
     * Berikan catatan bimbingan atau masukan guru pembimbing pada projek siswa.
     */
    public function reviewProject(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getTeacherPlacementIds($request);

        $sub = ProjectSubmission::whereIn('placement_id', $placementIds)->findOrFail($id);

        $request->validate([
            'note' => 'required|string|max:2000',
            'decision' => 'nullable|string|in:noted,approved,revision',
        ]);

        $decision = $request->input('decision', 'noted');

        $review = ProjectReview::create([
            'project_submission_id' => $sub->id,
            'reviewer_id' => $request->user()->id,
            'decision' => $decision,
            'note' => $request->input('note'),
            'created_at' => now(),
        ]);

        return $this->success([
            'submission' => $sub->fresh(['reviews.reviewer']),
            'review' => $review,
            'message' => 'Catatan bimbingan projek berhasil dikirim ke siswa.',
        ]);
    }
}

