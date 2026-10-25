<?php

namespace Tests\Feature;

use App\Models\Assessment;
use App\Models\Logbook;
use App\Models\LogbookStatusHistory;
use App\Models\ProjectReview;
use App\Models\ProjectSubmission;
use App\Services\GradeService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use InvalidArgumentException;
use Tests\CreatesTestData;
use Tests\TestCase;

class Phase2SchemaAndGradeTest extends TestCase
{
    use RefreshDatabase, CreatesTestData;

    private function placement()
    {
        [, $student] = $this->createStudentUser();
        [, $teacher] = $this->createTeacherUser();
        [, $supervisor] = $this->createSupervisorUser();

        return $this->createPlacement(
            $student,
            $this->createLocation(),
            $this->createActivePeriod(),
            $teacher,
            $supervisor
        );
    }

    // ── Central config ──

    public function test_business_rules_are_centralized_in_config(): void
    {
        $this->assertSame('Asia/Jakarta', config('pkl.timezone'));
        $this->assertSame('08:00', config('pkl.attendance.late_after'));
        $this->assertEquals(50, config('pkl.assessment.weight_dudi'));
        $this->assertEquals(50, config('pkl.assessment.weight_teacher'));
        $this->assertEquals(75, config('pkl.assessment.kkm'));
        $this->assertSame(15360, config('pkl.uploads.project_pdf_max_kb'));
        $this->assertSame('Perlu revisi', config('pkl.status_labels.logbook.rejected'));
    }

    // ── GradeService ──

    public function test_final_score_uses_configured_weights_and_kkm(): void
    {
        $result = app(GradeService::class)->calculate(80, 70);

        $this->assertEquals(75.0, $result['final_score']);
        $this->assertTrue($result['passed']);

        $this->assertFalse(app(GradeService::class)->calculate(70, 70)['passed']);
    }

    public function test_grade_calculation_follows_changed_config(): void
    {
        config(['pkl.assessment.weight_dudi' => 70, 'pkl.assessment.weight_teacher' => 30, 'pkl.assessment.kkm' => 80]);

        $result = app(GradeService::class)->calculate(90, 60);

        $this->assertEquals(81.0, $result['final_score']);
        $this->assertTrue($result['passed']);
    }

    public function test_grade_rejects_out_of_range_scores(): void
    {
        $this->expectException(InvalidArgumentException::class);

        app(GradeService::class)->calculate(101, 80);
    }

    // ── New schema ──

    public function test_existing_locations_default_to_approved(): void
    {
        $location = $this->createLocation();

        $this->assertSame('approved', $location->fresh()->approval_status);
    }

    public function test_logbook_supports_plan_and_status_history(): void
    {
        $placement = $this->placement();

        $logbook = Logbook::create([
            'placement_id' => $placement->id,
            'logbook_date' => now()->toDateString(),
            'activity' => 'Instalasi jaringan',
            'plan' => 'Memasang kabel UTP',
            'status' => 'draft',
        ]);

        LogbookStatusHistory::create([
            'logbook_id' => $logbook->id,
            'from_status' => 'draft',
            'to_status' => 'submitted',
        ]);

        $this->assertSame('Memasang kabel UTP', $logbook->fresh()->plan);
        $this->assertCount(1, $logbook->statusHistories);
    }

    public function test_project_submission_keeps_review_history(): void
    {
        $placement = $this->placement();

        $project = ProjectSubmission::create([
            'placement_id' => $placement->id,
            'title' => 'Sistem Inventaris',
            'description' => 'Aplikasi inventaris gudang',
            'status' => 'pending',
        ]);

        ProjectReview::create([
            'project_submission_id' => $project->id,
            'decision' => 'revision',
            'note' => 'Lengkapi hasil kerja.',
        ]);

        $this->assertCount(1, $project->reviews);
        $this->assertCount(1, $placement->projectSubmissions);
    }

    public function test_assessment_is_unique_per_placement_with_separate_components(): void
    {
        $placement = $this->placement();

        $assessment = Assessment::create([
            'placement_id' => $placement->id,
            'dudi_score' => 85,
            'dudi_components' => ['disiplin' => 90, 'keterampilan' => 80],
        ]);

        $this->assertNull($assessment->teacher_score);
        $this->assertFalse($assessment->isComplete());
        $this->assertSame(90, $assessment->fresh()->dudi_components['disiplin']);

        $this->expectException(\Illuminate\Database\QueryException::class);
        Assessment::create(['placement_id' => $placement->id]);
    }
}
