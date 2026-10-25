<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StorePeriodRequest;
use App\Http\Requests\Admin\UpdatePeriodRequest;
use App\Http\Resources\PeriodResource;
use App\Models\Period;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PeriodController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Period::query();

        if ($request->has('status')) {
            $query->where('status', $request->status);
        }
        if ($request->has('search')) {
            $query->where('name', 'ilike', "%{$request->search}%");
        }

        $periods = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'periods' => PeriodResource::collection($periods),
            'pagination' => [
                'current_page' => $periods->currentPage(),
                'last_page' => $periods->lastPage(),
                'per_page' => $periods->perPage(),
                'total' => $periods->total(),
            ],
        ]);
    }

    public function store(StorePeriodRequest $request): JsonResponse
    {
        $period = Period::create($request->validated());
        return $this->created(new PeriodResource($period));
    }

    public function show(int $id): JsonResponse
    {
        $period = Period::findOrFail($id);
        return $this->success(new PeriodResource($period));
    }

    public function update(UpdatePeriodRequest $request, int $id): JsonResponse
    {
        $period = Period::findOrFail($id);
        $period->update($request->validated());
        return $this->success(new PeriodResource($period->fresh()), 'Periode berhasil diperbarui.');
    }

    /**
     * Delete period and cascade placements.
     */
    public function destroy(int $id): JsonResponse
    {
        $period = Period::findOrFail($id);

        \Illuminate\Support\Facades\DB::transaction(function () use ($period) {
            foreach ($period->placements as $placement) {
                $placement->attendances()->delete();
                $placement->journals()->delete();
                $placement->leaveRequests()->delete();
                $placement->delete();
            }
            $period->delete();
        });

        return $this->success(null, 'Periode PKL berhasil dihapus.');
    }

    /**
     * Set a period as active and deactivate all other active periods.
     */
    public function activate(int $id): JsonResponse
    {
        $period = Period::findOrFail($id);

        Period::where('id', '!=', $id)
            ->where('status', 'active')
            ->update(['status' => 'inactive']);

        $period->update(['status' => 'active']);

        return $this->success(
            new PeriodResource($period->fresh()),
            "Periode '{$period->name}' berhasil diaktifkan sebagai tahun ajaran/periode aktif."
        );
    }
}
