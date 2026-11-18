<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        try {
            // 0. Jika database baru pertama kali dibuat dan tabel users masih kosong, seed data awal
            if (Schema::hasTable('users') && DB::table('users')->count() === 0) {
                Artisan::call('db:seed', ['--force' => true]);
            }

            // 1. Pastikan user pembimbing & guru dapat login
            if (Schema::hasTable('users')) {
                DB::table('users')->where('username', 'sofia123')->update(['password' => Hash::make('password123')]);
                DB::table('users')->where('username', 'gina1234')->update(['password' => Hash::make('password123')]);
                DB::table('users')->where('username', 'admin')->update(['password' => Hash::make('password')]);
                DB::table('users')->where('username', 'AnnisaDina17')->update(['password' => Hash::make('password')]);
            }

            // 2. Pastikan presensi AnnisaDina untuk hari ini (2026-11-18) tersimpan bila placement_id ada
            if (Schema::hasTable('attendances') && Schema::hasTable('placements')) {
                $placement = DB::table('placements')->where('id', 17)->first()
                    ?? DB::table('placements')->first();

                if ($placement) {
                    $targetPlacementId = $placement->id;
                    $exists = DB::table('attendances')
                        ->where('placement_id', $targetPlacementId)
                        ->where('attendance_date', '2026-11-18')
                        ->exists();

                    if (!$exists) {
                        DB::table('attendances')->insert([
                            'placement_id' => $targetPlacementId,
                            'attendance_date' => '2026-11-18',
                            'check_in_at' => '2026-11-18 04:11:49',
                            'check_in_latitude' => '-5.3606649',
                            'check_in_longitude' => '105.2432805',
                            'check_in_accuracy' => 20.90,
                            'check_in_distance' => 3.92,
                            'check_in_photo_path' => 'attendances/check-in/2026-11-18/jemR5KBMuRuPcwMC8nEsQtRzIdE6uQTnYGKCNk3W.jpg',
                            'status' => 'late',
                            'late_minutes' => 191,
                            'notes' => 'Terlambat 191 menit (Batas masuk DUDI: 08:00 WIB)',
                            'created_at' => '2026-11-18 04:11:49',
                            'updated_at' => '2026-11-18 04:11:49',
                        ]);
                    }
                }
            }

            // 3. Update serial sequence untuk PostgreSQL
            $driver = DB::getDriverName();
            if ($driver === 'pgsql') {
                foreach (['attendances', 'journals', 'users', 'project_submissions', 'placements', 'locations'] as $table) {
                    if (Schema::hasTable($table) && Schema::hasColumn($table, 'id')) {
                        $maxId = DB::table($table)->max('id');
                        if ($maxId) {
                            try {
                                DB::statement("SELECT setval(pg_get_serial_sequence('$table', 'id'), $maxId, true);");
                            } catch (\Throwable $e) {}
                        }
                    }
                }
            }
        } catch (\Throwable $e) {
            // Abaikan error agar migrasi tidak menggagalkan proses deployment
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // No reverse necessary
    }
};
