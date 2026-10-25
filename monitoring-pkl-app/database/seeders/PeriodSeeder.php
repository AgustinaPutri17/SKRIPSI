<?php

namespace Database\Seeders;

use App\Models\Period;
use Illuminate\Database\Seeder;

class PeriodSeeder extends Seeder
{
    public function run(): void
    {
        Period::firstOrCreate(
            ['name' => 'PKL Semester Ganjil 2024/2025'],
            [
                'start_date' => '2024-07-01',
                'end_date' => '2024-09-30',
                'status' => 'completed',
            ]
        );

        Period::firstOrCreate(
            ['name' => 'PKL Semester Genap 2024/2025'],
            [
                'start_date' => now()->subDays(30)->toDateString(),
                'end_date' => now()->addDays(60)->toDateString(),
                'status' => 'active',
            ]
        );

        Period::firstOrCreate(
            ['name' => 'PKL Semester Ganjil 2025/2026'],
            [
                'start_date' => now()->addMonths(3)->toDateString(),
                'end_date' => now()->addMonths(6)->toDateString(),
                'status' => 'inactive',
            ]
        );

        $this->command->info('✓ Periods seeded successfully.');
    }
}
