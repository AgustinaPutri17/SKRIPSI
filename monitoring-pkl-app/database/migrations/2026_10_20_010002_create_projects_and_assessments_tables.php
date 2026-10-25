<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // ── Module E: internship project submission & verification ──
        Schema::create('project_submissions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('placement_id')->constrained('placements')->cascadeOnDelete();
            $table->string('title');
            $table->text('description');
            $table->text('plan')->nullable();
            $table->text('result')->nullable();
            $table->string('document_path')->nullable();
            $table->string('document_name')->nullable();
            $table->unsignedBigInteger('document_size')->nullable(); // bytes
            $table->string('status', 30)->default('draft'); // draft, pending, approved, revision
            $table->timestamp('submitted_at')->nullable();
            $table->timestamps();

            $table->index(['placement_id', 'status']);
        });

        // Verification history (one row per decision).
        Schema::create('project_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('project_submission_id')->constrained('project_submissions')->cascadeOnDelete();
            $table->foreignId('reviewer_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('decision', 30); // approved, revision
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index('project_submission_id');
        });

        // ── Module F: assessments (separate DUDI & teacher components) ──
        Schema::create('assessments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('placement_id')->unique()->constrained('placements')->cascadeOnDelete();

            $table->decimal('dudi_score', 5, 2)->nullable();
            $table->json('dudi_components')->nullable();
            $table->text('dudi_notes')->nullable();
            $table->foreignId('dudi_scored_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('dudi_scored_at')->nullable();

            $table->decimal('teacher_score', 5, 2)->nullable();
            $table->json('teacher_components')->nullable();
            $table->text('teacher_notes')->nullable();
            $table->foreignId('teacher_scored_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('teacher_scored_at')->nullable();

            // Computed by the backend only; weights/KKM snapshotted at finalization.
            $table->decimal('final_score', 5, 2)->nullable();
            $table->decimal('weight_dudi', 5, 2)->nullable();
            $table->decimal('weight_teacher', 5, 2)->nullable();
            $table->decimal('kkm', 5, 2)->nullable();
            $table->string('status', 30)->default('draft'); // draft, finalized
            $table->foreignId('finalized_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('finalized_at')->nullable();
            $table->timestamps();

            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('assessments');
        Schema::dropIfExists('project_reviews');
        Schema::dropIfExists('project_submissions');
    }
};
