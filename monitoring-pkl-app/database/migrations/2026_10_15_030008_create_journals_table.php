<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('journals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('placement_id')->constrained('placements')->cascadeOnDelete();
            $table->date('journal_date');
            $table->time('start_time')->nullable();
            $table->time('end_time')->nullable();
            $table->text('activity');
            $table->text('result')->nullable();
            $table->text('obstacles')->nullable();
            $table->string('photo_path')->nullable();
            $table->enum('status', ['draft', 'submitted', 'approved', 'rejected'])->default('draft');
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('verified_at')->nullable();
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('verification_comment')->nullable();
            $table->timestamps();

            $table->index(['placement_id', 'journal_date']);
            $table->index('status');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('journals');
    }
};
