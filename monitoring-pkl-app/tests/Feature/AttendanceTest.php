<?php

namespace Tests\Feature;

use App\Models\Attendance;
use App\Models\Student;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\CreatesTestData;
use Tests\TestCase;

class AttendanceTest extends TestCase
{
    use CreatesTestData;

    private function setupStudent(): array
    {
        Storage::fake('public');

        [$studentUser, $student] = $this->createStudentUser();
        [$teacherUser, $teacher] = $this->createTeacherUser();
        [$supervisorUser, $supervisor] = $this->createSupervisorUser();

        $location = $this->createLocation([
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'radius' => 500, // wide radius for testing
        ]);
        $period = $this->createActivePeriod();
        $placement = $this->createPlacement($student, $location, $period, $teacher, $supervisor);

        $token = $studentUser->createToken('test')->plainTextToken;

        return [$token, $placement, $location, $student];
    }

    // ── Check-in ───────────────────────────────────

    public function test_student_can_check_in_when_within_radius(): void
    {
        [$token] = $this->setupStudent();

        $response = $this->withToken($token)->postJson('/api/student/attendances/check-in', [
            'latitude' => -6.208763,  // exactly on location
            'longitude' => 106.845599,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkin.jpg'),
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.check_in_at', fn($v) => !is_null($v));
    }

    public function test_check_in_fails_when_outside_radius(): void
    {
        Storage::fake('public');

        [$studentUser, $student] = $this->createStudentUser();
        [$teacherUser, $teacher] = $this->createTeacherUser();
        $location = $this->createLocation([
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'radius' => 10, // very tight radius
        ]);
        $period = $this->createActivePeriod();
        $this->createPlacement($student, $location, $period, $teacher);
        $token = $studentUser->createToken('test')->plainTextToken;

        $response = $this->withToken($token)->postJson('/api/student/attendances/check-in', [
            'latitude' => -6.300000,  // far away (~10km)
            'longitude' => 106.900000,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkin.jpg'),
        ]);

        // Controller returns 422 when outside radius
        $response->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_student_cannot_check_in_twice_on_same_day(): void
    {
        [$token, $placement] = $this->setupStudent();

        // First check-in
        Attendance::create([
            'placement_id' => $placement->id,
            'attendance_date' => now()->toDateString(),
            'check_in_at' => now(),
            'check_in_latitude' => -6.208763,
            'check_in_longitude' => 106.845599,
            'check_in_accuracy' => 10,
            'check_in_distance' => 0,
            'check_in_photo_path' => 'test/photo.jpg',
            'status' => 'present',
        ]);

        // Attempt second check-in
        $response = $this->withToken($token)->postJson('/api/student/attendances/check-in', [
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkin2.jpg'),
        ]);

        $response->assertJson(['success' => false]);
        $this->assertStringContainsString('sudah melakukan check-in', $response->json('message'));
    }

    // ── Check-out ──────────────────────────────────

    public function test_student_can_check_out_after_check_in(): void
    {
        [$token, $placement] = $this->setupStudent();

        // Create check-in record first
        Attendance::create([
            'placement_id' => $placement->id,
            'attendance_date' => now()->toDateString(),
            'check_in_at' => now()->subHours(4),
            'check_in_latitude' => -6.208763,
            'check_in_longitude' => 106.845599,
            'check_in_accuracy' => 10,
            'check_in_distance' => 0,
            'check_in_photo_path' => 'test/photo.jpg',
            'status' => 'present',
        ]);

        $response = $this->withToken($token)->postJson('/api/student/attendances/check-out', [
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkout.jpg'),
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.check_out_at', fn($v) => !is_null($v));
    }

    public function test_student_cannot_check_out_without_check_in(): void
    {
        [$token] = $this->setupStudent();

        $response = $this->withToken($token)->postJson('/api/student/attendances/check-out', [
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkout.jpg'),
        ]);

        $response->assertJson(['success' => false]);
        $this->assertStringContainsString('belum melakukan check-in', $response->json('message'));
    }

    public function test_student_cannot_check_out_twice(): void
    {
        [$token, $placement] = $this->setupStudent();

        // Create attendance with both check-in and check-out already done
        Attendance::create([
            'placement_id' => $placement->id,
            'attendance_date' => now()->toDateString(),
            'check_in_at' => now()->subHours(8),
            'check_in_photo_path' => 'test/ci.jpg',
            'check_in_latitude' => -6.208763,
            'check_in_longitude' => 106.845599,
            'check_in_accuracy' => 10,
            'check_in_distance' => 0,
            'check_out_at' => now()->subHours(1),
            'check_out_photo_path' => 'test/co.jpg',
            'check_out_latitude' => -6.208763,
            'check_out_longitude' => 106.845599,
            'check_out_accuracy' => 10,
            'check_out_distance' => 0,
            'status' => 'present',
        ]);

        // Attempt second checkout
        $response = $this->withToken($token)->postJson('/api/student/attendances/check-out', [
            'latitude' => -6.208763,
            'longitude' => 106.845599,
            'accuracy' => 10,
            'photo' => UploadedFile::fake()->image('checkout2.jpg'),
        ]);

        $response->assertStatus(422)
            ->assertJson(['success' => false]);
        $this->assertStringContainsString('sudah melakukan check-out', $response->json('message'));
    }

    // ── IDOR prevention ────────────────────────────

    public function test_student_cannot_see_another_students_attendance(): void
    {
        Storage::fake('public');

        // Setup student 1 with attendance
        [$studentUser1, $student1] = $this->createStudentUser();
        [$teacherUser, $teacher] = $this->createTeacherUser();
        $location = $this->createLocation();
        $period = $this->createActivePeriod();
        $placement1 = $this->createPlacement($student1, $location, $period, $teacher);
        $attendance = Attendance::create([
            'placement_id' => $placement1->id,
            'attendance_date' => now()->toDateString(),
            'check_in_at' => now(),
            'check_in_photo_path' => 'test.jpg',
            'check_in_latitude' => -6.2,
            'check_in_longitude' => 106.8,
            'check_in_accuracy' => 10,
            'check_in_distance' => 0,
            'status' => 'present',
        ]);

        // Student 2 tries to access student 1's attendance
        $studentUser2 = \App\Models\User::factory()->create([
            'role' => 'student',
            'username' => 'student2_unique_' . uniqid(),
        ]);
        Student::create([
            'user_id' => $studentUser2->id,
            'nis' => '9999' . uniqid(),
            'name' => 'Student 2',
            'class' => 'XII',
        ]);
        $token2 = $studentUser2->createToken('test')->plainTextToken;

        $response = $this->withToken($token2)->getJson('/api/student/attendances/' . $attendance->id);
        $response->assertStatus(404);
    }
}
