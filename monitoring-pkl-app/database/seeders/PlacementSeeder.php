<?php

namespace Database\Seeders;

use App\Models\FieldSupervisor;
use App\Models\Location;
use App\Models\Period;
use App\Models\Placement;
use App\Models\Student;
use App\Models\Teacher;
use Illuminate\Database\Seeder;

class PlacementSeeder extends Seeder
{
    public function run(): void
    {
        $activePeriod = Period::where('status', 'active')->first();
        $students = Student::all();
        $teachers = Teacher::all();
        $supervisors = FieldSupervisor::all();
        $locations = Location::all();

        if (!$activePeriod || $students->isEmpty() || $teachers->isEmpty() || $locations->isEmpty()) {
            $this->command->warn('⚠ Skipping PlacementSeeder: missing required data.');
            return;
        }

        $placements = [
            [
                'student_id' => $students[0]->id,  // Andi
                'location_id' => $locations[0]->id, // PT. Maju Bersama
                'teacher_id' => $teachers[0]->id,   // Budi
                'field_supervisor_id' => $supervisors[0]->id, // Agus
            ],
            [
                'student_id' => $students[1]->id,  // Dewi
                'location_id' => $locations[0]->id, // PT. Maju Bersama
                'teacher_id' => $teachers[0]->id,   // Budi
                'field_supervisor_id' => $supervisors[0]->id, // Agus
            ],
            [
                'student_id' => $students[2]->id,  // Reza
                'location_id' => $locations[1]->id, // CV. Teknologi Nusantara
                'teacher_id' => $teachers[1]->id,   // Siti
                'field_supervisor_id' => $supervisors[1]->id, // Rina
            ],
            [
                'student_id' => $students[3]->id,  // Maya
                'location_id' => $locations[1]->id, // CV. Teknologi Nusantara
                'teacher_id' => $teachers[1]->id,   // Siti
                'field_supervisor_id' => $supervisors[1]->id, // Rina
            ],
        ];

        foreach ($placements as $data) {
            Placement::firstOrCreate(
                [
                    'student_id' => $data['student_id'],
                    'period_id' => $activePeriod->id,
                ],
                [
                    ...$data,
                    'start_date' => $activePeriod->start_date,
                    'end_date' => $activePeriod->end_date,
                    'status' => 'active',
                ]
            );
        }

        $this->command->info('✓ Placements seeded successfully.');
        $this->command->info('  4 students placed in active period: ' . $activePeriod->name);
    }
}
