<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreFieldSupervisorRequest;
use App\Http\Requests\Admin\UpdateFieldSupervisorRequest;
use App\Http\Resources\FieldSupervisorResource;
use App\Models\FieldSupervisor;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FieldSupervisorController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = FieldSupervisor::with('user');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('organization', 'ilike', "%{$search}%");
            });
        }

        $supervisors = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'field_supervisors' => FieldSupervisorResource::collection($supervisors),
            'pagination' => [
                'current_page' => $supervisors->currentPage(),
                'last_page' => $supervisors->lastPage(),
                'per_page' => $supervisors->perPage(),
                'total' => $supervisors->total(),
            ],
        ]);
    }

    public function store(StoreFieldSupervisorRequest $request): JsonResponse
    {
        $supervisor = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => $request->password,
                'role' => 'field_supervisor',
            ]);

            return FieldSupervisor::create([
                'user_id' => $user->id,
                'name' => $request->name,
                'phone' => $request->phone,
                'organization' => $request->organization,
            ]);
        });

        return $this->created(new FieldSupervisorResource($supervisor->load('user')));
    }

    public function show(int $id): JsonResponse
    {
        $supervisor = FieldSupervisor::with('user')->findOrFail($id);
        return $this->success(new FieldSupervisorResource($supervisor));
    }

    public function update(UpdateFieldSupervisorRequest $request, int $id): JsonResponse
    {
        $supervisor = FieldSupervisor::findOrFail($id);
        $supervisor->update($request->validated());

        if ($request->has('name')) {
            $supervisor->user->update(['name' => $request->name]);
        }

        return $this->success(new FieldSupervisorResource($supervisor->fresh('user')), 'Pembimbing lapangan berhasil diperbarui.');
    }

    /**
     * Deactivate field supervisor account without deleting historical records.
     */
    public function destroy(int $id): JsonResponse
    {
        $supervisor = FieldSupervisor::findOrFail($id);

        $supervisor->user->update(['is_active' => false]);
        $supervisor->user->tokens()->delete();

        return $this->success(null, 'Akun pembimbing lapangan berhasil dinonaktifkan.');
    }
}
