<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Location submissions by supervisors need admin approval (existing rows stay approved).
        Schema::table('locations', function (Blueprint $table) {
            $table->string('approval_status', 30)->default('approved')->after('is_active');
            $table->foreignId('approved_by')->nullable()->after('approval_status')->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable()->after('approved_by');
            $table->text('approval_note')->nullable()->after('approved_at');
            $table->index('approval_status');
        });

        // Attendance: record how late a check-in was (status 'late' is derived from config).
        Schema::table('attendances', function (Blueprint $table) {
            $table->unsignedInteger('late_minutes')->nullable()->after('status');
        });

        // Logbook: activity plan field required by the design.
        Schema::table('logbooks', function (Blueprint $table) {
            $table->text('plan')->nullable()->after('description');
        });

        // Audit trail for logbook status changes.
        Schema::create('logbook_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('logbook_id')->constrained('logbooks')->cascadeOnDelete();
            $table->foreignId('changed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('from_status', 30)->nullable();
            $table->string('to_status', 30);
            $table->text('note')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['logbook_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('logbook_status_histories');

        Schema::table('logbooks', function (Blueprint $table) {
            $table->dropColumn('plan');
        });

        Schema::table('attendances', function (Blueprint $table) {
            $table->dropColumn('late_minutes');
        });

        Schema::table('locations', function (Blueprint $table) {
            $table->dropForeign(['approved_by']);
            $table->dropIndex(['approval_status']);
            $table->dropColumn(['approval_status', 'approved_by', 'approved_at', 'approval_note']);
        });
    }
};
