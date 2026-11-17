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
use App\Models\Assessment;
use App\Models\Attendance;
use App\Models\Journal;
use App\Models\LeaveRequest;
use App\Models\ProjectReview;
use App\Models\ProjectSubmission;
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
        $user = $request->user();
        $student = $user->student;
        $placement = $student?->activePlacement() ?? $student?->placements()->latest()->first();
        
        $todayWib = \Carbon\Carbon::now('Asia/Jakarta')->toDateString();
        $todayUtc = \Carbon\Carbon::now('UTC')->toDateString();
        $possibleDates = array_values(array_unique([$todayWib, $todayUtc]));

        $todayAttendance = null;
        $todayJournal = null;
        $latestJournal = null;
        $journalStats = ['total' => 0, 'draft' => 0, 'submitted' => 0, 'approved' => 0, 'rejected' => 0];
        $attendanceStats = [
            'present' => 0,
            'late' => 0,
            'sick' => 0,
            'permission' => 0,
            'absent' => 0,
            'total_present_days' => 0,
            'total_recorded_days' => 0,
            'percentage' => 0,
        ];
        $pklProgress = null;

        if ($placement) {
            $placement->load(['location', 'period', 'teacher.user', 'fieldSupervisor.user']);

            // 1. Presensi Hari Ini
            $todayAttendance = Attendance::where('placement_id', $placement->id)
                ->where(function ($q) use ($possibleDates, $todayWib) {
                    $q->whereIn('attendance_date', $possibleDates)
                      ->orWhereDate('created_at', $todayWib)
                      ->orWhereDate('check_in_at', $todayWib);
                })
                ->latest('id')
                ->first();

            // 2. Statistik Presensi & Persentase Kehadiran
            $attendances = Attendance::where('placement_id', $placement->id)->get();
            $presentCount = $attendances->whereIn('status', ['present', 'late', 'approved'])->count();
            $lateCount = $attendances->where('status', 'late')->count();
            $sickCount = $attendances->where('status', 'sick')->count();
            $permCount = $attendances->where('status', 'permission')->count();
            $absentCount = $attendances->where('status', 'absent')->count();
            $totalCount = $attendances->count();

            $startDate = $placement->start_date ? \Carbon\Carbon::parse($placement->start_date) : now();
            $endDate = $placement->end_date ? \Carbon\Carbon::parse($placement->end_date) : now()->addDays(90);

            $daysElapsed = 0;
            if (now()->greaterThanOrEqualTo($startDate)) {
                $daysElapsed = $startDate->diffInDays(now()->min($endDate)) + 1;
            }

            $percentage = $daysElapsed > 0 
                ? min(100, max(0, round(($presentCount / max(1, $daysElapsed)) * 100))) 
                : ($totalCount > 0 ? min(100, round(($presentCount / $totalCount) * 100)) : 0);

            $attendanceStats = [
                'present' => $presentCount,
                'late' => $lateCount,
                'sick' => $sickCount,
                'permission' => $permCount,
                'absent' => $absentCount,
                'total_present_days' => $presentCount,
                'total_recorded_days' => $totalCount,
                'days_elapsed' => $daysElapsed,
                'percentage' => $percentage,
            ];

            // 3. Progres PKL
            $totalPklDays = max(1, $startDate->diffInDays($endDate) + 1);
            $currentPklDay = 0;
            if (now()->greaterThanOrEqualTo($startDate)) {
                $currentPklDay = min($totalPklDays, $startDate->diffInDays(now()) + 1);
            }
            $remainingPklDays = max(0, $totalPklDays - $currentPklDay);
            $progressPercent = min(100, max(0, round(($currentPklDay / $totalPklDays) * 100)));

            $months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
            $startFormatted = $startDate->day . ' ' . ($months[$startDate->month] ?? $startDate->format('M'));
            $endFormatted = $endDate->day . ' ' . ($months[$endDate->month] ?? $endDate->format('M')) . ' ' . $endDate->year;

            $pklProgress = [
                'period_name' => $placement->period?->name ?? 'PKL',
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
                'start_formatted' => $startFormatted,
                'end_formatted' => $endFormatted,
                'total_days' => $totalPklDays,
                'current_day' => $currentPklDay,
                'remaining_days' => $remainingPklDays,
                'percentage' => $progressPercent,
            ];

            // 4. Logbook Hari Ini & Logbook Terbaru
            $placementIds = $student->placements()->pluck('id');
            $journalStats = [
                'total' => Journal::whereIn('placement_id', $placementIds)->count(),
                'draft' => Journal::whereIn('placement_id', $placementIds)->where('status', 'draft')->count(),
                'submitted' => Journal::whereIn('placement_id', $placementIds)->where('status', 'submitted')->count(),
                'approved' => Journal::whereIn('placement_id', $placementIds)->where('status', 'approved')->count(),
                'rejected' => Journal::whereIn('placement_id', $placementIds)->where('status', 'rejected')->count(),
            ];

            $todayJournal = Journal::where('placement_id', $placement->id)
                ->where(function ($q) use ($possibleDates, $todayWib) {
                    $q->whereIn('logbook_date', $possibleDates)
                      ->orWhereDate('created_at', $todayWib);
                })
                ->latest('id')
                ->first();

            $latestJournalModel = Journal::where('placement_id', $placement->id)
                ->orderByDesc('logbook_date')
                ->orderByDesc('id')
                ->first();

            if ($latestJournalModel) {
                $supervisorName = $placement->fieldSupervisor?->name 
                    ?? $placement->fieldSupervisor?->user?->name 
                    ?? 'Instruktur';
                $jDate = \Carbon\Carbon::parse($latestJournalModel->logbook_date);
                $jDateFormatted = $jDate->day . ' ' . ($months[$jDate->month] ?? $jDate->format('M')) . ' ' . $jDate->year;

                $latestJournal = [
                    'id' => $latestJournalModel->id,
                    'logbook_date' => $latestJournalModel->logbook_date?->toDateString() ?? $latestJournalModel->logbook_date,
                    'formatted_date' => $jDateFormatted,
                    'activity' => $latestJournalModel->activity ?? $latestJournalModel->description ?? '-',
                    'status' => $latestJournalModel->status,
                    'verification_note' => $latestJournalModel->verification_note,
                    'supervisor_name' => $supervisorName,
                ];
            }
        }

        return $this->success([
            'student' => [
                'id' => $student?->id,
                'name' => $student?->name ?? $user->name,
                'nis' => $student?->nis ?? '-',
                'class' => $student?->class ?? 'XII RPL 1',
                'major' => $student?->major ?? 'Rekayasa Perangkat Lunak',
                'school_name' => 'SMKN 2 Bandar Lampung',
            ],
            'placement' => $placement ? new PlacementResource($placement) : null,
            'attendance_today' => $todayAttendance ? new AttendanceResource($todayAttendance) : null,
            'attendance_stats' => $attendanceStats,
            'journal_today' => $todayJournal ? new JournalResource($todayJournal) : null,
            'journal_stats' => $journalStats,
            'latest_journal' => $latestJournal,
            'pkl_progress' => $pklProgress,
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
            'attachment' => 'required|file|mimes:jpeg,png,jpg,pdf,doc,docx|max:5120',
        ], [
            'attachment.required' => 'Bukti dokumen atau foto surat izin/sakit wajib dilampirkan.',
            'attachment.mimes' => 'Bukti berkas harus berformat PDF atau gambar (JPG, PNG).',
            'attachment.max' => 'Ukuran berkas maksimal 5 MB.',
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

    // ── Project Submissions ──

    public function getProject(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        if (!$student) {
            return $this->success([
                'projects' => [],
                'submission' => null,
            ]);
        }

        $placementIds = $student->placements()->pluck('id')->toArray();
        if (empty($placementIds)) {
            return $this->success([
                'projects' => [],
                'submission' => null,
            ]);
        }

        $submissions = ProjectSubmission::with(['reviews.reviewer'])
            ->whereIn('placement_id', $placementIds)
            ->latest('id')
            ->get();

        $projectsData = $submissions->map(function ($sub) {
            $data = $sub->toArray();
            $data['document_url'] = $sub->document_path ? asset('storage/' . $sub->document_path) : null;
            $data['reviews'] = $sub->reviews->map(function ($r) {
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
            });
            return $data;
        });

        $latestSubmission = $projectsData->first();

        return $this->success([
            'projects' => $projectsData,
            'submission' => $latestSubmission,
        ]);
    }

    public function saveProject(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        if (!$student) {
            return $this->error('Data profil siswa tidak ditemukan.', 422);
        }

        $placement = $student->activePlacement() ?? $student->placements()->latest()->first();

        if (!$placement) {
            return $this->error('Siswa belum memiliki penempatan PKL aktif.', 422);
        }

        $validated = $request->validate([
            'id' => 'nullable|integer',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'plan' => 'nullable|string',
            'result' => 'nullable|string',
            'status' => 'nullable|string|in:draft,pending,submitted,approved,revision',
            'document' => 'nullable|file|max:15360',
            'document_name' => 'nullable|string|max:255',
            'document_size' => 'nullable|integer',
        ]);

        if ($request->hasFile('document')) {
            $file = $request->file('document');
            $ext = strtolower($file->getClientOriginalExtension());
            $mime = strtolower($file->getMimeType());
            if ($ext !== 'pdf' && !str_contains($mime, 'pdf') && $mime !== 'application/octet-stream') {
                return $this->error('Berkas dokumen harus berupa file PDF.', 422);
            }
        }

        $placementIds = $student->placements()->pluck('id')->toArray();
        if ($request->filled('id') && (int)$request->input('id') > 0) {
            $submission = ProjectSubmission::whereIn('placement_id', $placementIds)->findOrFail((int)$request->input('id'));
        } else {
            $submission = new ProjectSubmission();
            $submission->placement_id = $placement->id;
        }

        $submission->title = $validated['title'];
        $submission->description = $validated['description'] ?? $validated['title'];
        $submission->plan = $validated['plan'] ?? null;
        $submission->result = $validated['result'] ?? null;

        if ($request->hasFile('document')) {
            $file = $request->file('document');
            $filename = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '_', $file->getClientOriginalName());
            $path = $file->storeAs('projects/' . $placement->id, $filename, 'public');
            $submission->document_path = $path;
            $submission->document_name = $file->getClientOriginalName();
            $submission->document_size = $file->getSize();
        } elseif ($request->filled('document_name') && !$submission->document_path) {
            $submission->document_name = $request->input('document_name');
            $submission->document_size = $request->input('document_size', 0);
        }

        $requestedStatus = strtolower($request->input('status', 'draft'));
        if (in_array($requestedStatus, ['submitted', 'pending', 'revision', 'approved'])) {
            $submission->status = 'pending';
            $submission->submitted_at = now();
        } elseif ($requestedStatus === 'draft') {
            $submission->status = 'draft';
        } else {
            $submission->status = 'pending';
            $submission->submitted_at = now();
        }

        $submission->save();

        $submission->load(['reviews.reviewer']);
        $data = $submission->toArray();
        $data['document_url'] = $submission->document_path ? asset('storage/' . $submission->document_path) : null;
        $data['reviews'] = $submission->reviews->map(function ($r) {
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
        });

        return $this->success(
            $data,
            $submission->status === 'pending'
                ? 'Projek berhasil disimpan & diajukan untuk verifikasi!'
                : 'Draf projek berhasil disimpan.',
            200
        );
    }

    public function getProjectHistory(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        if (!$student) {
            return $this->success([], 'Belum ada riwayat projek.');
        }

        $placementIds = $student->placements()->pluck('id')->toArray();
        if (empty($placementIds)) {
            return $this->success([], 'Belum ada riwayat projek.');
        }

        $submission = ProjectSubmission::with(['reviews.reviewer'])
            ->whereIn('placement_id', $placementIds)
            ->latest('id')
            ->first();

        if (!$submission) {
            return $this->success([], 'Belum ada riwayat projek.');
        }

        $reviews = $submission->reviews->map(function ($r) {
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
        });

        return $this->success([
            'submission' => array_merge($submission->toArray(), [
                'document_url' => $submission->document_path ? asset('storage/' . $submission->document_path) : null,
            ]),
            'reviews' => $reviews,
        ]);
    }

    /**
     * Get PKL assessment and notes from DU/DI for the student.
     */
    public function getAssessment(Request $request): JsonResponse
    {
        $student = $request->user()->student;
        $placement = $student?->activePlacement();

        if (!$placement) {
            return $this->error('Siswa belum memiliki penempatan PKL aktif.', 404);
        }

        $assessment = Assessment::where('placement_id', $placement->id)->first();

        if (!$assessment || $assessment->dudi_score === null) {
            return $this->success(null, 'Nilai PKL belum diinput oleh pihak DU/DI.');
        }

        return $this->success([
            'id' => $assessment->id,
            'dudi_score' => (float)$assessment->dudi_score,
            'dudi_components' => $assessment->dudi_components,
            'dudi_notes' => $assessment->dudi_notes,
            'dudi_scored_at' => $assessment->dudi_scored_at?->toIso8601String(),
            'teacher_score' => $assessment->teacher_score !== null ? (float)$assessment->teacher_score : null,
            'final_score' => $assessment->final_score !== null ? (float)$assessment->final_score : null,
            'status' => $assessment->status,
        ]);
    }
}
