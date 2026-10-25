<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->string('check_in_location_status', 30)->nullable()->after('check_in_distance');
            $table->string('check_out_location_status', 30)->nullable()->after('check_out_distance');

            $table->string('completeness_status', 30)->default('in_progress')->after('notes');
            $table->string('verification_status', 30)->default('pending')->after('completeness_status');
            $table->foreignId('verified_by')->nullable()->after('verification_status')->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable()->after('verified_by');
            $table->text('verification_note')->nullable()->after('verified_at');

            $table->index('completeness_status');
            $table->index('verification_status');
        });
    }

    public function down(): void
    {
        Schema::table('attendances', function (Blueprint $table) {
            $table->dropForeign(['verified_by']);
            $table->dropIndex(['completeness_status']);
            $table->dropIndex(['verification_status']);

            $table->dropColumn([
                'check_in_location_status',
                'check_out_location_status',
                'completeness_status',
                'verification_status',
                'verified_by',
                'verified_at',
                'verification_note',
            ]);
        });
    }
};
