<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreStudentRequest;
use App\Http\Requests\Admin\UpdateStudentRequest;
use App\Http\Resources\StudentResource;
use App\Models\Student;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StudentController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $query = Student::with('user');

        if ($request->has('class')) {
            $query->where('class', $request->class);
        }
        if ($request->has('major')) {
            $query->where('major', $request->major);
        }
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'ilike', "%{$search}%")
                  ->orWhere('nis', 'ilike', "%{$search}%");
            });
        }

        $students = $query->latest()->paginate($request->get('per_page', 15));

        return $this->success([
            'students' => StudentResource::collection($students),
            'pagination' => [
                'current_page' => $students->currentPage(),
                'last_page' => $students->lastPage(),
                'per_page' => $students->perPage(),
                'total' => $students->total(),
            ],
        ]);
    }

    public function store(StoreStudentRequest $request): JsonResponse
    {
        $student = DB::transaction(function () use ($request) {
            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => $request->password,
                'role' => 'student',
            ]);

            return Student::create([
                'user_id' => $user->id,
                'nis' => $request->nis,
                'name' => $request->name,
                'class' => $request->class,
                'major' => $request->major,
                'phone' => $request->phone,
            ]);
        });

        return $this->created(new StudentResource($student->load('user')));
    }

    public function show(int $id): JsonResponse
    {
        $student = Student::with('user')->findOrFail($id);
        return $this->success(new StudentResource($student));
    }

    public function update(UpdateStudentRequest $request, int $id): JsonResponse
    {
        $student = Student::findOrFail($id);
        $student->update($request->validated());

        // Sync name to user
        if ($request->has('name')) {
            $student->user->update(['name' => $request->name]);
        }

        return $this->success(new StudentResource($student->fresh('user')), 'Siswa berhasil diperbarui.');
    }

    /**
     * Delete student account and historical placements.
     */
    public function destroy(int $id): JsonResponse
    {
        $student = Student::findOrFail($id);
        $user = $student->user;

        DB::transaction(function () use ($student, $user) {
            foreach ($student->placements as $placement) {
                $placement->attendances()->delete();
                $placement->journals()->delete();
                $placement->leaveRequests()->delete();
                $placement->delete();
            }

            $student->delete();

            if ($user) {
                $user->tokens()->delete();
                $user->delete();
            }
        });

        return $this->success(null, 'Akun siswa berhasil dihapus.');
    }
}
