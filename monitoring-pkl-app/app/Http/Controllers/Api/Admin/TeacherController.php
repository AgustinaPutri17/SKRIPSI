<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreTeacherRequest;
use App\Http\Requests\Admin\UpdateTeacherRequest;
use App\Http\Resources\TeacherResource;
use App\Models\Teacher;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TeacherController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Teacher::with('user');

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('teacher_code', 'ilike', "%{$search}%");
            });
        }

        $teachers = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'teachers' => TeacherResource::collection($teachers),
            'pagination' => [
                'current_page' => $teachers->currentPage(),
                'last_page' => $teachers->lastPage(),
                'per_page' => $teachers->perPage(),
                'total' => $teachers->total(),
            ],
        ]);
    }

    public function store(StoreTeacherRequest $request): JsonResponse
    {
        $teacher = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => $request->password,
                'role' => 'teacher',
            ]);

            return Teacher::create([
                'user_id' => $user->id,
                'teacher_code' => $request->teacher_code,
                'name' => $request->name,
                'phone' => $request->phone,
            ]);
        });

        return $this->created(new TeacherResource($teacher->load('user')));
    }

    public function show(int $id): JsonResponse
    {
        $teacher = Teacher::with('user')->findOrFail($id);
        return $this->success(new TeacherResource($teacher));
    }

    public function update(UpdateTeacherRequest $request, int $id): JsonResponse
    {
        $teacher = Teacher::findOrFail($id);
        $teacher->update($request->validated());

        if ($request->has('name')) {
            $teacher->user->update(['name' => $request->name]);
        }

        return $this->success(new TeacherResource($teacher->fresh('user')), 'Guru berhasil diperbarui.');
    }

    /**
     * Delete teacher account and cascade.
     */
    public function destroy(int $id): JsonResponse
    {
        $teacher = Teacher::findOrFail($id);
        $user = $teacher->user;

        DB::transaction(function () use ($teacher, $user) {
            foreach ($teacher->placements as $placement) {
                $placement->attendances()->delete();
                $placement->journals()->delete();
                $placement->leaveRequests()->delete();
                $placement->delete();
            }

            $teacher->delete();

            if ($user) {
                $user->tokens()->delete();
                $user->delete();
            }
        });

        return $this->success(null, 'Akun guru pembimbing berhasil dihapus.');
    }
}
