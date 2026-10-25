<?php

namespace Tests;

use App\Models\FieldSupervisor;
use App\Models\Location;
use App\Models\Period;
use App\Models\Placement;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;

trait CreatesTestData
{
    use RefreshDatabase;

    protected function createAdmin(): User
    {
        return User::factory()->create([
            'role' => 'admin',
            'is_active' => true,
            'username' => 'test.admin',
            'password' => Hash::make('password'),
        ]);
    }

    protected function createTeacherUser(): array
    {
        $uid = uniqid();
        $user = User::factory()->create([
            'role' => 'teacher',
            'is_active' => true,
            'username' => 'test.teacher.' . $uid,
        ]);
        $teacher = Teacher::create([
            'user_id' => $user->id,
            'teacher_code' => 'T' . $uid,
            'name' => $user->name,
        ]);
        return [$user, $teacher];
    }

    protected function createSupervisorUser(): array
    {
        $uid = uniqid();
        $user = User::factory()->create([
            'role' => 'field_supervisor',
            'is_active' => true,
            'username' => 'test.supervisor.' . $uid,
        ]);
        $supervisor = FieldSupervisor::create([
            'user_id' => $user->id,
            'name' => $user->name,
            'organization' => 'Test Company',
        ]);
        return [$user, $supervisor];
    }

    protected function createStudentUser(): array
    {
        $uid = uniqid();
        $user = User::factory()->create([
            'role' => 'student',
            'is_active' => true,
            'username' => 'test.student.' . $uid,
        ]);
        $student = Student::create([
            'user_id' => $user->id,
            'nis' => '2024' . $uid,
            'name' => $user->name,
            'class' => 'XII RPL 1',
        ]);
        return [$user, $student];
    }

    protected function createLocation(array $attrs = []): Location
    {
        return Location::create(array_merge([
            'name' => 'Test Location',
            'address' => 'Jl. Test No. 1',
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'radius' => 100,
        ], $attrs));
    }

    protected function createActivePeriod(): Period
    {
        return Period::create([
            'name' => 'Test Period',
            'start_date' => now()->subDays(10),
            'end_date' => now()->addDays(80),
            'status' => 'active',
        ]);
    }

    protected function createPlacement(Student $student, Location $location, Period $period, Teacher $teacher, ?FieldSupervisor $supervisor = null): Placement
    {
        return Placement::create([
            'student_id' => $student->id,
            'location_id' => $location->id,
            'period_id' => $period->id,
            'teacher_id' => $teacher->id,
            'field_supervisor_id' => $supervisor?->id,
            'start_date' => $period->start_date,
            'end_date' => $period->end_date,
            'status' => 'active',
        ]);
    }
}
