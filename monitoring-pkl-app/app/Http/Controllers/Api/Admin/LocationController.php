<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreLocationRequest;
use App\Http\Requests\Admin\UpdateLocationRequest;
use App\Http\Resources\LocationResource;
use App\Models\Location;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LocationController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Location::with('fieldSupervisors.user');

        if ($request->has('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('address', 'ilike', "%{$search}%");
            });
        }

        $locations = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'locations' => LocationResource::collection($locations),
            'pagination' => [
                'current_page' => $locations->currentPage(),
                'last_page' => $locations->lastPage(),
                'per_page' => $locations->perPage(),
                'total' => $locations->total(),
            ],
        ]);
    }

    public function store(StoreLocationRequest $request): JsonResponse
    {
        $location = Location::create($request->safe()->except('field_supervisor_ids'));

        if ($request->has('field_supervisor_ids')) {
            $location->fieldSupervisors()->sync($request->field_supervisor_ids);
        }

        return $this->created(new LocationResource($location->load('fieldSupervisors.user')));
    }

    public function show(int $id): JsonResponse
    {
        $location = Location::with('fieldSupervisors.user')->findOrFail($id);
        return $this->success(new LocationResource($location));
    }

    public function update(UpdateLocationRequest $request, int $id): JsonResponse
    {
        $location = Location::findOrFail($id);
        $location->update($request->safe()->except('field_supervisor_ids'));

        if ($request->has('field_supervisor_ids')) {
            $location->fieldSupervisors()->sync($request->field_supervisor_ids);
        }

        return $this->success(new LocationResource($location->fresh('fieldSupervisors.user')), 'Lokasi berhasil diperbarui.');
    }

    /**
     * Delete location and associated placements.
     */
    public function destroy(int $id): JsonResponse
    {
        $location = Location::findOrFail($id);

        \Illuminate\Support\Facades\DB::transaction(function () use ($location) {
            foreach ($location->placements as $placement) {
                $placement->attendances()->delete();
                $placement->journals()->delete();
                $placement->leaveRequests()->delete();
                $placement->delete();
            }

            // Hapus juga akun pembimbing DU/DI yang terhubung ke mitra ini
            $supervisors = $location->fieldSupervisors()->get();
            $location->fieldSupervisors()->detach();

            foreach ($supervisors as $supervisor) {
                // Jika pembimbing ini tidak terhubung ke lokasi mitra lain, hapus akunnya permanen
                if ($supervisor->locations()->count() === 0) {
                    $supervisor->placements()->update(['field_supervisor_id' => null]);
                    if ($supervisor->user) {
                        $supervisor->user->tokens()->delete();
                        $supervisor->user->delete();
                    }
                    $supervisor->delete();
                }
            }

            $location->delete();
        });

        return $this->success(null, 'Lokasi mitra DU/DI berhasil dihapus.');
    }
}
