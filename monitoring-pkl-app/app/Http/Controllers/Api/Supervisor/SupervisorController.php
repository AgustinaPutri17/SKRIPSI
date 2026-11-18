<?php

namespace App\Http\Controllers\Api\Supervisor;

use App\Http\Controllers\Controller;
use App\Http\Requests\Supervisor\StoreSupervisorLocationRequest;
use App\Http\Requests\Supervisor\UpdateSupervisorLocationRequest;
use App\Http\Requests\Supervisor\VerifyJournalRequest;
use App\Http\Resources\AttendanceResource;
use App\Http\Resources\JournalResource;
use App\Http\Resources\LocationResource;
use App\Http\Resources\StudentResource;
use App\Models\Assessment;
use App\Models\Attendance;
use App\Models\Journal;
use App\Models\Location;
use App\Models\Placement;
use App\Models\ProjectReview;
use App\Models\ProjectSubmission;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class SupervisorController extends Controller
{
    use ApiResponse;

    /**
     * Get placement IDs for the authenticated field supervisor.
     */
    private function getSupervisorPlacementIds(Request $request): array
    {
        $supervisor = $request->user()->fieldSupervisor;
        if (!$supervisor) return [];

        $directPlacementIds = $supervisor->placements()->pluck('id')->toArray();
        $locationIds = $supervisor->locations()->pluck('locations.id')->toArray();
        $locationPlacementIds = !empty($locationIds) 
            ? Placement::whereIn('location_id', $locationIds)->pluck('id')->toArray() 
            : [];

        return array_values(array_unique(array_merge($directPlacementIds, $locationPlacementIds)));
    }

    /**
     * List students under this supervisor.
     */
    public function students(Request $request): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $placements = Placement::with(['student.user', 'location', 'period', 'assessment'])
            ->where('field_supervisor_id', $supervisor->id)
            ->where('status', 'active')
            ->get();

        $students = $placements->map(function ($p) {
            $student = $p->student;
            $attendancesCount = \App\Models\Attendance::where('placement_id', $p->id)->count();
            $logbooksCount = \App\Models\Journal::where('placement_id', $p->id)->count();
            $projectsCount = \App\Models\ProjectSubmission::where('placement_id', $p->id)->count();

            $data = (new StudentResource($student))->toArray(request());
            $data['placement_id'] = $p->id;
            $data['attendances_count'] = $attendancesCount;
            $data['logbooks_count'] = $logbooksCount;
            $data['projects_count'] = $projectsCount;
            $data['status'] = $p->status;

            $assessment = $p->assessment;
            $data['assessment'] = $assessment ? [
                'id' => $assessment->id,
                'dudi_score' => $assessment->dudi_score !== null ? (float)$assessment->dudi_score : null,
                'dudi_components' => $assessment->dudi_components,
                'dudi_notes' => $assessment->dudi_notes,
                'dudi_scored_at' => $assessment->dudi_scored_at?->toIso8601String(),
                'status' => $assessment->status,
            ] : null;
            $data['dudi_score'] = $assessment && $assessment->dudi_score !== null ? (float)$assessment->dudi_score : null;

            return $data;
        })->unique('id')->values();

        return $this->success([
            'students' => $students,
        ]);
    }

    public function showStudent(Request $request, int $id): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $placement = Placement::with(['student.user'])
            ->where('field_supervisor_id', $supervisor->id)
            ->where('student_id', $id)
            ->firstOrFail();

        return $this->success(new StudentResource($placement->student));
    }

    /**
     * Get assessment detail for a student.
     */
    public function getStudentAssessment(Request $request, int $id): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $placement = Placement::with(['student.user', 'location', 'period', 'assessment'])
            ->where('field_supervisor_id', $supervisor->id)
            ->where('student_id', $id)
            ->firstOrFail();

        $assessment = $placement->assessment;

        return $this->success([
            'placement_id' => $placement->id,
            'student' => [
                'id' => $placement->student->id,
                'name' => $placement->student->name,
                'nis' => $placement->student->nis,
                'class' => $placement->student->class,
                'major' => $placement->student->major,
            ],
            'location' => $placement->location ? [
                'id' => $placement->location->id,
                'name' => $placement->location->name,
                'address' => $placement->location->address,
            ] : null,
            'assessment' => $assessment ? [
                'id' => $assessment->id,
                'dudi_score' => $assessment->dudi_score !== null ? (float)$assessment->dudi_score : null,
                'dudi_components' => $assessment->dudi_components,
                'dudi_notes' => $assessment->dudi_notes,
                'dudi_scored_at' => $assessment->dudi_scored_at?->toIso8601String(),
                'status' => $assessment->status,
            ] : null,
        ]);
    }

    /**
     * Save/update assessment from DUDI for a student.
     */
    public function saveStudentAssessment(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'dudi_score' => 'required|numeric|min:0|max:100',
            'dudi_components' => 'required|array',
            'dudi_notes' => 'nullable|string|max:2000',
        ]);

        $supervisor = $request->user()->fieldSupervisor;
        $placement = Placement::where('field_supervisor_id', $supervisor->id)
            ->where('student_id', $id)
            ->firstOrFail();

        $assessment = Assessment::firstOrNew(['placement_id' => $placement->id]);
        $assessment->dudi_score = round($request->input('dudi_score'), 2);
        $assessment->dudi_components = $request->input('dudi_components');
        $assessment->dudi_notes = $request->input('dudi_notes');
        $assessment->dudi_scored_by = $request->user()->id;
        $assessment->dudi_scored_at = now();

        if ($assessment->teacher_score !== null) {
            $wDudi = $assessment->weight_dudi ?? 0.50;
            $wTeacher = $assessment->weight_teacher ?? 0.50;
            $assessment->final_score = round(($assessment->dudi_score * $wDudi) + ($assessment->teacher_score * $wTeacher), 2);
        }

        $assessment->save();

        return $this->success([
            'message' => 'Penilaian PKL berhasil disimpan.',
            'assessment' => [
                'id' => $assessment->id,
                'dudi_score' => (float)$assessment->dudi_score,
                'dudi_components' => $assessment->dudi_components,
                'dudi_notes' => $assessment->dudi_notes,
                'dudi_scored_at' => $assessment->dudi_scored_at->toIso8601String(),
            ],
        ]);
    }

    /**
     * List locations assigned to this field supervisor.
     */
    public function locations(Request $request): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $locations = $supervisor->locations()->where('is_active', true)->get();

        return $this->success([
            'locations' => LocationResource::collection($locations),
        ]);
    }

    /**
     * Register a new authorized PKL location for this field supervisor.
     */
    public function storeLocation(StoreSupervisorLocationRequest $request): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;

        $location = Location::create($request->validated());
        $supervisor->locations()->syncWithoutDetaching([$location->id]);

        return $this->created(new LocationResource($location), 'Lokasi PKL berhasil didaftarkan.');
    }

    /**
     * Show authorized location detail for this field supervisor.
     */
    public function showLocation(Request $request, int $id): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $location = $supervisor->locations()->findOrFail($id);

        return $this->success(new LocationResource($location));
    }

    /**
     * Update authorized location data for this field supervisor.
     */
    public function updateLocation(UpdateSupervisorLocationRequest $request, int $id): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $location = $supervisor->locations()->findOrFail($id);

        $location->update($request->validated());

        return $this->success(new LocationResource($location->fresh()), 'Data lokasi PKL berhasil diperbarui.');
    }

    /**
     * List journals for supervisor's students.
     */
    public function journals(Request $request): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);

        $query = Journal::with('placement.student')
            ->whereIn('placement_id', $placementIds);

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $journals = $query->latest('logbook_date')
            ->paginate($request->get('per_page', 15));

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

    public function showJournal(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);
        $journal = Journal::with(['placement.student', 'verifier'])
            ->whereIn('placement_id', $placementIds)
            ->findOrFail($id);

        return $this->success(new JournalResource($journal));
    }

    /**
     * Approve a journal.
     */
    public function approveJournal(VerifyJournalRequest $request, int $id): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);
        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        if (!$journal->isSubmitted()) {
            return $this->error('Jurnal belum disubmit atau sudah diverifikasi.', 422);
        }

        $journal->update([
            'status' => 'approved',
            'verified_at' => now(),
            'verified_by' => $request->user()->id,
            'verification_comment' => $request->comment,
        ]);

        return $this->success(new JournalResource($journal->fresh()), 'Jurnal berhasil disetujui.');
    }

    /**
     * Reject a journal.
     */
    public function rejectJournal(VerifyJournalRequest $request, int $id): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);
        $journal = Journal::whereIn('placement_id', $placementIds)->findOrFail($id);

        if (!$journal->isSubmitted()) {
            return $this->error('Jurnal belum disubmit atau sudah diverifikasi.', 422);
        }

        $journal->update([
            'status' => 'rejected',
            'verified_at' => now(),
            'verified_by' => $request->user()->id,
            'verification_comment' => $request->comment,
        ]);

        return $this->success(new JournalResource($journal->fresh()), 'Jurnal ditolak.');
    }

    /**
     * List attendances for supervisor's students.
     */
    public function attendances(Request $request): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);

        $query = Attendance::with('placement.student')
            ->whereIn('placement_id', $placementIds);

        if ($request->has('date')) {
            $query->where('attendance_date', $request->date);
        }

        $attendances = $query->latest('attendance_date')
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

    /**
     * Supervisor dashboard.
     */
    public function dashboard(Request $request): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $placementIds = $this->getSupervisorPlacementIds($request);
        $todayWib = \Carbon\Carbon::now('Asia/Jakarta')->toDateString();
        $todayUtc = \Carbon\Carbon::now('UTC')->toDateString();
        $possibleDates = array_values(array_unique([$todayWib, $todayUtc]));

        $activePlacements = Placement::with(['student.user', 'assessment', 'location'])
            ->whereIn('id', $placementIds)
            ->where('status', 'active')
            ->get();

        $totalStudents = $activePlacements->count();

        // 1. Presensi Hari Ini per Siswa (Mencakup attendance_date WIB/UTC serta timestamp check_in_at & created_at)
        $todayAttendances = Attendance::whereIn('placement_id', $placementIds)
            ->where(function ($q) use ($possibleDates, $todayWib, $todayUtc) {
                $q->whereIn('attendance_date', $possibleDates)
                  ->orWhereDate('attendance_date', $todayWib)
                  ->orWhereDate('attendance_date', $todayUtc)
                  ->orWhereDate('check_in_at', $todayWib)
                  ->orWhereDate('check_in_at', $todayUtc)
                  ->orWhereDate('created_at', $todayWib)
                  ->orWhereDate('created_at', $todayUtc);
            })
            ->latest('id')
            ->get();

        $studentsAttendance = [];
        $presentTodayCount = 0;
        $lateTodayCount = 0;

        foreach ($activePlacements as $p) {
            $student = $p->student;
            $att = $todayAttendances->first(fn($a) => (int)$a->placement_id === (int)$p->id);
            $isPresent = $att && (!empty($att->check_in_at) || in_array($att->status, ['present', 'late', 'approved']));
            $isLate = $att?->status === 'late';
            if ($isPresent) {
                $presentTodayCount++;
                if ($isLate) $lateTodayCount++;
            }

            $checkInTimeFormatted = $att?->check_in_at 
                ? \Carbon\Carbon::parse($att->check_in_at)->timezone('Asia/Jakarta')->format('H:i') . ' WIB' 
                : null;
            $checkOutTimeFormatted = $att?->check_out_at 
                ? \Carbon\Carbon::parse($att->check_out_at)->timezone('Asia/Jakarta')->format('H:i') . ' WIB' 
                : null;

            $statusLabel = 'Belum Hadir';
            if ($att) {
                if ($att->status === 'sick') $statusLabel = 'Sakit';
                elseif ($att->status === 'permission') $statusLabel = 'Izin';
                elseif ($att->status === 'absent') $statusLabel = 'Alpa';
                elseif ($isLate) $statusLabel = 'Hadir (Terlambat)';
                elseif ($isPresent) $statusLabel = 'Hadir (Tepat Waktu)';
            }

            $studentsAttendance[] = [
                'placement_id' => $p->id,
                'student_id' => $student?->id,
                'name' => $student?->name ?? $student?->user?->name ?? 'Siswa',
                'nis' => $student?->nis ?? '-',
                'class' => $student?->class ?? '-',
                'is_present' => $isPresent,
                'status' => $att?->status ?? 'belum_hadir',
                'status_label' => $statusLabel,
                'check_in_time' => $checkInTimeFormatted,
                'check_out_time' => $checkOutTimeFormatted,
                'is_late' => $isLate,
            ];
        }

        // 2. Metrik Kehadiran & Ketepatan Waktu Historis
        $allAttendances = Attendance::whereIn('placement_id', $placementIds)->get();
        $totalAttRecords = $allAttendances->count();
        $totalPresentRecords = $allAttendances->whereIn('status', ['present', 'late', 'approved'])->count();
        $totalOnTimeRecords = $allAttendances->where('status', 'present')->count();
        $totalLateRecords = $allAttendances->where('status', 'late')->count();

        $avgAttendanceRate = $totalAttRecords > 0 ? round(($totalPresentRecords / $totalAttRecords) * 100) : 0;
        $totalCheckIns = $totalOnTimeRecords + $totalLateRecords;
        $avgOnTimeRate = $totalCheckIns > 0 ? round(($totalOnTimeRecords / $totalCheckIns) * 100) : 100;

        // 3. Ringkasan Penilaian / Nilai PKL
        $gradedCount = $activePlacements->filter(fn($p) => $p->assessment && $p->assessment->dudi_score !== null)->count();
        $ungradedCount = max(0, $totalStudents - $gradedCount);
        $avgDudiScore = $gradedCount > 0 
            ? round($activePlacements->filter(fn($p) => $p->assessment && $p->assessment->dudi_score !== null)->avg(fn($p) => $p->assessment->dudi_score), 1)
            : null;

        // 4. Logbook Menunggu Validasi (HANYA status = submitted)
        $journalsPendingCount = Journal::whereIn('placement_id', $placementIds)
            ->where('status', 'submitted')
            ->count();

        $pendingJournals = Journal::with(['placement.student'])
            ->whereIn('placement_id', $placementIds)
            ->where('status', 'submitted')
            ->latest('created_at')
            ->take(5)
            ->get();

        // 5. Projek Siswa
        $projectsCount = ProjectSubmission::whereIn('placement_id', $placementIds)->count();

        return $this->success([
            'total_students' => $totalStudents,
            'attendance_today' => $presentTodayCount,
            'attendance_today_count' => $presentTodayCount,
            'unattended_today_count' => max(0, $totalStudents - $presentTodayCount),
            'attendance_rate' => $avgAttendanceRate,
            'on_time_rate' => $avgOnTimeRate,
            'journals_pending' => $journalsPendingCount,
            'projects_count' => $projectsCount,
            'assessment_summary' => [
                'total_students' => $totalStudents,
                'graded_count' => $gradedCount,
                'ungraded_count' => $ungradedCount,
                'average_score' => $avgDudiScore,
            ],
            'students_today' => $studentsAttendance,
            'pending_journals' => JournalResource::collection($pendingJournals),
        ]);
    }

    /**
     * List project submissions from students under this supervisor.
     */
    public function getProjects(Request $request): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);

        $submissions = ProjectSubmission::with(['placement.student.user', 'reviews.reviewer'])
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
     * Detail of a student's project submission.
     */
    public function showProject(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);

        $sub = ProjectSubmission::with(['placement.student.user', 'reviews.reviewer'])
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
     * Verify (approve or request revision) a student's project submission.
     */
    public function verifyProject(Request $request, int $id): JsonResponse
    {
        $placementIds = $this->getSupervisorPlacementIds($request);

        $sub = ProjectSubmission::whereIn('placement_id', $placementIds)->findOrFail($id);

        $request->validate([
            'decision' => 'required|string|in:approved,revision,rejected',
            'note' => 'nullable|string|max:2000',
        ]);

        $decision = in_array(strtolower($request->input('decision')), ['revision', 'rejected']) ? 'revision' : 'approved';

        if ($decision === 'revision' && empty(trim($request->input('note', '')))) {
            return $this->error('Catatan evaluasi / instruktur wajib diisi saat meminta revisi projek.', 422);
        }

        $review = ProjectReview::create([
            'project_submission_id' => $sub->id,
            'reviewer_id' => $request->user()->id,
            'decision' => $decision,
            'note' => $request->input('note'),
            'created_at' => now(),
        ]);

        $sub->status = $decision;
        $sub->save();

        return $this->success([
            'submission' => $sub->fresh(['reviews.reviewer']),
            'review' => $review,
            'message' => $decision === 'approved'
                ? 'Projek siswa berhasil disetujui (ACC).'
                : 'Projek siswa dikembalikan untuk revisi beserta catatan instruktur.',
        ]);
    }
}
