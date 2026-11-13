<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class SnapshotSeeder extends Seeder
{
    public function run(): void
    {
        $file = database_path('snapshot.json');
        if (!file_exists($file)) {
            $this->command?->warn("No snapshot.json found at $file, skipping SnapshotSeeder.");
            return;
        }

        $data = json_decode(file_get_contents($file), true);
        if (!$data || !is_array($data)) {
            $this->command?->warn("Invalid snapshot.json file.");
            return;
        }

        $tables = [
            'users',
            'teachers',
            'field_supervisors',
            'students',
            'locations',
            'periods',
            'placements',
            'attendances',
            'logbooks',
            'logbook_comments',
            'location_field_supervisor',
        ];

        // Disable foreign key checks if possible
        $driver = DB::getDriverName();
        if ($driver === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = OFF;');
        } elseif ($driver === 'pgsql') {
            DB::statement('SET CONSTRAINTS ALL DEFERRED;');
        }

        foreach ($tables as $table) {
            if (!isset($data[$table]) || !is_array($data[$table]) || !Schema::hasTable($table)) {
                continue;
            }

            foreach ($data[$table] as $row) {
                // If row has an 'id', use updateOrInsert
                if (isset($row['id'])) {
                    DB::table($table)->updateOrInsert(['id' => $row['id']], $row);
                } else {
                    // Composite key or pivot table like location_field_supervisor
                    DB::table($table)->updateOrInsert($row, $row);
                }
            }

            // For postgres, update sequence to max id
            if ($driver === 'pgsql' && Schema::hasColumn($table, 'id')) {
                $maxId = DB::table($table)->max('id');
                if ($maxId) {
                    try {
                        DB::statement("SELECT setval(pg_get_serial_sequence('$table', 'id'), $maxId, true);");
                    } catch (\Throwable $e) {}
                }
            }

            $this->command?->info("✓ Seeded table $table from snapshot (" . count($data[$table]) . " rows)");
        }

        if ($driver === 'sqlite') {
            DB::statement('PRAGMA foreign_keys = ON;');
        }
    }
}

