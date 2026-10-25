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
use App\Models\Attendance;
use App\Models\Journal;
use App\Models\Location;
use App\Models\Placement;
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
        return $supervisor->placements()->pluck('id')->toArray();
    }

    /**
     * List students under this supervisor.
     */
    public function students(Request $request): JsonResponse
    {
        $supervisor = $request->user()->fieldSupervisor;
        $placements = Placement::with(['student.user', 'location', 'period'])
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
        $placementIds = $this->getSupervisorPlacementIds($request);
        $today = now()->toDateString();

        return $this->success([
            'total_students' => Placement::whereIn('id', $placementIds)->where('status', 'active')->count(),
            'attendance_today' => Attendance::whereIn('placement_id', $placementIds)
                ->where('attendance_date', $today)->count(),
            'journals_pending' => Journal::whereIn('placement_id', $placementIds)
                ->where('status', 'submitted')->count(),
        ]);
    }
}
