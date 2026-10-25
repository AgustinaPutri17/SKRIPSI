<?php

namespace Tests\Feature;

use App\Models\Journal;
use Tests\CreatesTestData;
use Tests\TestCase;

class JournalTest extends TestCase
{
    use CreatesTestData;

    private function setupStudentWithPlacement(): array
    {
        [$studentUser, $student] = $this->createStudentUser();
        [$teacherUser, $teacher] = $this->createTeacherUser();
        [$supervisorUser, $supervisor] = $this->createSupervisorUser();
        $location = $this->createLocation();
        $period = $this->createActivePeriod();
        $placement = $this->createPlacement($student, $location, $period, $teacher, $supervisor);

        return [
            'studentUser' => $studentUser,
            'student' => $student,
            'supervisorUser' => $supervisorUser,
            'supervisor' => $supervisor,
            'placement' => $placement,
            'token' => $studentUser->createToken('test')->plainTextToken,
            'supervisorToken' => $supervisorUser->createToken('test')->plainTextToken,
        ];
    }

    public function test_student_can_create_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $response = $this->withToken($data['token'])->postJson('/api/student/logbooks', [
            'journal_date' => now()->toDateString(),
            'activity' => 'Belajar Laravel Framework',
            'result' => 'Memahami routing dan controller',
            'start_time' => '08:00',
            'end_time' => '17:00',
        ]);

        $response->assertStatus(201)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.activity', 'Belajar Laravel Framework');
    }

    public function test_student_can_submit_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Test Activity',
            'status' => 'draft',
        ]);

        $response = $this->withToken($data['token'])->postJson("/api/student/logbooks/{$journal->id}/submit");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'submitted');
    }

    public function test_student_cannot_edit_approved_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Test Activity',
            'status' => 'approved',
        ]);

        $response = $this->withToken($data['token'])->putJson("/api/student/logbooks/{$journal->id}", [
            'activity' => 'Updated Activity',
        ]);

        $response->assertStatus(422)
            ->assertJson(['success' => false]);
    }

    public function test_student_can_edit_rejected_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Original Activity',
            'status' => 'rejected',
        ]);

        $response = $this->withToken($data['token'])->putJson("/api/student/logbooks/{$journal->id}", [
            'activity' => 'Corrected Activity',
        ]);

        $response->assertStatus(200)
            ->assertJson(['success' => true])
            ->assertJsonPath('data.activity', 'Corrected Activity');
    }

    public function test_student_can_resubmit_rejected_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Fixed Activity',
            'status' => 'rejected',
        ]);

        $response = $this->withToken($data['token'])->postJson("/api/student/logbooks/{$journal->id}/submit");

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'submitted');
    }

    public function test_supervisor_can_approve_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Test Activity',
            'status' => 'submitted',
        ]);

        $response = $this->withToken($data['supervisorToken'])->postJson("/api/supervisor/logbooks/{$journal->id}/approve", [
            'comment' => 'Bagus, teruskan!',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'approved')
            ->assertJsonPath('data.verification_comment', 'Bagus, teruskan!');
    }

    public function test_supervisor_can_reject_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Test Activity',
            'status' => 'submitted',
        ]);

        $response = $this->withToken($data['supervisorToken'])->postJson("/api/supervisor/logbooks/{$journal->id}/reject", [
            'comment' => 'Kurang detail, mohon diperbaiki.',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('data.status', 'rejected');
    }

    public function test_supervisor_cannot_verify_another_supervisors_journal(): void
    {
        $data = $this->setupStudentWithPlacement();

        $journal = Journal::create([
            'placement_id' => $data['placement']->id,
            'journal_date' => now()->toDateString(),
            'activity' => 'Test Activity',
            'status' => 'submitted',
        ]);

        // Create another supervisor with unique username
        [$otherSupervisorUser, $otherSupervisor] = $this->createSupervisorUser();
        $otherSupervisorUser->update(['username' => 'other.supervisor.' . uniqid()]);
        $otherToken = $otherSupervisorUser->createToken('test')->plainTextToken;

        $response = $this->withToken($otherToken)->postJson("/api/supervisor/logbooks/{$journal->id}/approve");

        $response->assertStatus(404);
    }

    public function test_teacher_cannot_see_another_teachers_student(): void
    {
        $data = $this->setupStudentWithPlacement();

        // Create second teacher with unique username and code
        [$otherTeacherUser, $otherTeacher] = $this->createTeacherUser();
        $otherTeacherUser->update(['username' => 'other.teacher.' . uniqid()]);
        $otherTeacher->update(['teacher_code' => 'T' . uniqid()]);
        $otherToken = $otherTeacherUser->createToken('test')->plainTextToken;

        // Get student ID from first placement
        $studentId = $data['placement']->student_id;

        $response = $this->withToken($otherToken)->getJson("/api/teacher/students/{$studentId}");
        $response->assertStatus(404);
    }
}
