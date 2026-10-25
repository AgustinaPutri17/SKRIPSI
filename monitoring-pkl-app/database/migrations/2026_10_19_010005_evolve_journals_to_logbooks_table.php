<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Safely rename table without data loss
        Schema::rename('journals', 'logbooks');

        Schema::table('logbooks', function (Blueprint $table) {
            $table->renameColumn('journal_date', 'logbook_date');
            $table->renameColumn('verification_comment', 'verification_note');

            $table->foreignId('attendance_id')->nullable()->after('placement_id')->constrained('attendances')->nullOnDelete();
            $table->foreignId('activity_id')->nullable()->after('logbook_date')->constrained('activities')->nullOnDelete();
            $table->text('description')->nullable()->after('activity');

            $table->index('attendance_id');
            $table->index('activity_id');
        });
    }

    public function down(): void
    {
        Schema::table('logbooks', function (Blueprint $table) {
            $table->dropForeign(['attendance_id']);
            $table->dropForeign(['activity_id']);
            $table->dropIndex(['attendance_id']);
            $table->dropIndex(['activity_id']);

            $table->dropColumn(['attendance_id', 'activity_id', 'description']);

            $table->renameColumn('logbook_date', 'journal_date');
            $table->renameColumn('verification_note', 'verification_comment');
        });

        Schema::rename('logbooks', 'journals');
    }
};
