<?php

namespace Tests\Feature;

use Tests\CreatesTestData;
use Tests\TestCase;

class AuthorizationTest extends TestCase
{
    use CreatesTestData;

    public function test_student_cannot_access_admin_endpoints(): void
    {
        [$studentUser] = $this->createStudentUser();
        $token = $studentUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/admin/users');
        $response->assertStatus(403);
    }

    public function test_teacher_cannot_access_admin_endpoints(): void
    {
        [$teacherUser] = $this->createTeacherUser();
        $token = $teacherUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/admin/users');
        $response->assertStatus(403);
    }

    public function test_supervisor_cannot_access_admin_endpoints(): void
    {
        [$supervisorUser] = $this->createSupervisorUser();
        $token = $supervisorUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/admin/users');
        $response->assertStatus(403);
    }

    public function test_student_cannot_access_teacher_endpoints(): void
    {
        [$studentUser] = $this->createStudentUser();
        $token = $studentUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/teacher/students');
        $response->assertStatus(403);
    }

    public function test_student_cannot_access_supervisor_endpoints(): void
    {
        [$studentUser] = $this->createStudentUser();
        $token = $studentUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/supervisor/students');
        $response->assertStatus(403);
    }

    public function test_teacher_cannot_access_student_endpoints(): void
    {
        [$teacherUser] = $this->createTeacherUser();
        $token = $teacherUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/student/profile');
        $response->assertStatus(403);
    }

    public function test_admin_can_access_all_admin_endpoints(): void
    {
        $admin = $this->createAdmin();
        $token = $admin->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->getJson('/api/admin/users');
        $response->assertStatus(200);
    }
}
