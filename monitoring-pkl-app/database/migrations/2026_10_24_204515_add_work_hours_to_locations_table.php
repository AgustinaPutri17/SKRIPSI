<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('locations', function (Blueprint $table) {
            $table->time('check_in_start')->default('06:00:00')->after('radius');
            $table->time('check_in_time')->default('08:00:00')->after('check_in_start');
            $table->time('check_out_time')->default('16:00:00')->after('check_in_time');
            $table->time('check_out_end')->default('20:00:00')->after('check_out_time');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('locations', function (Blueprint $table) {
            $table->dropColumn([
                'check_in_start',
                'check_in_time',
                'check_out_time',
                'check_out_end',
            ]);
        });
    }
};
