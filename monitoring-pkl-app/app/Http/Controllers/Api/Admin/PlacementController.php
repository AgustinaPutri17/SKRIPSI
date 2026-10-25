<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StorePlacementRequest;
use App\Http\Requests\Admin\UpdatePlacementRequest;
use App\Http\Resources\PlacementResource;
use App\Models\Placement;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PlacementController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Placement::with(['student', 'location', 'period', 'teacher', 'fieldSupervisor']);

        if ($request->has('student_id')) {
            $query->where('student_id', $request->student_id);
        }
        if ($request->has('location_id')) {
            $query->where('location_id', $request->location_id);
        }
        if ($request->has('period_id')) {
            $query->where('period_id', $request->period_id);
        }
        if ($request->has('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }
        if ($request->has('field_supervisor_id')) {
            $query->where('field_supervisor_id', $request->field_supervisor_id);
        }
        if ($request->has('status')) {
            $query->where('status', $request->status);
        }

        $placements = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'placements' => PlacementResource::collection($placements),
            'pagination' => [
                'current_page' => $placements->currentPage(),
                'last_page' => $placements->lastPage(),
                'per_page' => $placements->perPage(),
                'total' => $placements->total(),
            ],
        ]);
    }

    public function store(StorePlacementRequest $request): JsonResponse
    {
        $placement = Placement::create($request->validated());
        return $this->created(
            new PlacementResource($placement->load(['student', 'location', 'period', 'teacher', 'fieldSupervisor']))
        );
    }

    public function show(int $id): JsonResponse
    {
        $placement = Placement::with(['student', 'location', 'period', 'teacher', 'fieldSupervisor'])->findOrFail($id);
        return $this->success(new PlacementResource($placement));
    }

    public function update(UpdatePlacementRequest $request, int $id): JsonResponse
    {
        $placement = Placement::findOrFail($id);
        $placement->update($request->validated());
        return $this->success(
            new PlacementResource($placement->fresh(['student', 'location', 'period', 'teacher', 'fieldSupervisor'])),
            'Penempatan berhasil diperbarui.'
        );
    }

    /**
     * Deactivate placement preserving historical records.
     */
    public function destroy(int $id): JsonResponse
    {
        $placement = Placement::findOrFail($id);
        $placement->update(['status' => 'inactive']);
        return $this->success(null, 'Penempatan berhasil dinonaktifkan.');
    }

    /**
     * Toggle placement status between active and inactive.
     */
    public function toggleStatus(int $id): JsonResponse
    {
        $placement = Placement::findOrFail($id);
        $newStatus = $placement->status === 'active' ? 'inactive' : 'active';

        if ($newStatus === 'active') {
            $conflict = Placement::where('student_id', $placement->student_id)
                ->where('period_id', $placement->period_id)
                ->where('status', 'active')
                ->where('id', '!=', $placement->id)
                ->exists();

            if ($conflict) {
                return $this->error('Siswa sudah memiliki penempatan aktif lain pada periode ini.', 422);
            }
        }

        $placement->update(['status' => $newStatus]);

        return $this->success(
            new PlacementResource($placement->fresh(['student', 'location', 'period', 'teacher', 'fieldSupervisor'])),
            'Status penempatan berhasil diubah menjadi ' . ($newStatus === 'active' ? 'Aktif' : 'Nonaktif') . '.'
        );
    }
}
