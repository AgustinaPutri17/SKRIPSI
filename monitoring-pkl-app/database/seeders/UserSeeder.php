<?php

namespace Database\Seeders;

use App\Models\FieldSupervisor;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        // ── Admin ──────────────────────────────────────────
        $adminUsername = env('ADMIN_INITIAL_USERNAME', 'admin');
        $adminEmail = env('ADMIN_INITIAL_EMAIL', 'admin@monitoring-pkl.test');
        $adminPassword = env('ADMIN_INITIAL_PASSWORD', 'password');

        User::firstOrCreate(
            ['username' => $adminUsername],
            [
                'name' => 'Administrator',
                'email' => $adminEmail,
                'password' => Hash::make($adminPassword),
                'role' => 'admin',
                'is_active' => true,
            ]
        );

        // ── Teachers ───────────────────────────────────────
        $teacher1User = User::firstOrCreate(
            ['username' => 'guru.budi'],
            [
                'name' => 'Budi Santoso',
                'email' => 'budi@monitoring-pkl.test',
                'password' => Hash::make('password'),
                'role' => 'teacher',
                'is_active' => true,
            ]
        );

        Teacher::firstOrCreate(
            ['user_id' => $teacher1User->id],
            [
                'teacher_code' => 'GT001',
                'name' => 'Budi Santoso',
                'phone' => '081234567890',
            ]
        );

        $teacher2User = User::firstOrCreate(
            ['username' => 'guru.siti'],
            [
                'name' => 'Siti Rahayu',
                'email' => 'siti@monitoring-pkl.test',
                'password' => Hash::make('password'),
                'role' => 'teacher',
                'is_active' => true,
            ]
        );

        Teacher::firstOrCreate(
            ['user_id' => $teacher2User->id],
            [
                'teacher_code' => 'GT002',
                'name' => 'Siti Rahayu',
                'phone' => '081234567891',
            ]
        );

        // ── Field Supervisors ──────────────────────────────
        $supervisor1User = User::firstOrCreate(
            ['username' => 'pembimbing.agus'],
            [
                'name' => 'Agus Wijaya',
                'email' => 'agus@perusahaan-a.test',
                'password' => Hash::make('password'),
                'role' => 'field_supervisor',
                'is_active' => true,
            ]
        );

        FieldSupervisor::firstOrCreate(
            ['user_id' => $supervisor1User->id],
            [
                'name' => 'Agus Wijaya',
                'phone' => '082345678901',
                'organization' => 'PT. Maju Bersama',
            ]
        );

        $supervisor2User = User::firstOrCreate(
            ['username' => 'pembimbing.rina'],
            [
                'name' => 'Rina Kusuma',
                'email' => 'rina@perusahaan-b.test',
                'password' => Hash::make('password'),
                'role' => 'field_supervisor',
                'is_active' => true,
            ]
        );

        FieldSupervisor::firstOrCreate(
            ['user_id' => $supervisor2User->id],
            [
                'name' => 'Rina Kusuma',
                'phone' => '082345678902',
                'organization' => 'CV. Teknologi Nusantara',
            ]
        );

        // ── Students ───────────────────────────────────────
        // Demo/dummy data only. 'password' is optional; if omitted the
        // STUDENT_INITIAL_PASSWORD env value (default: "password") is used.
        $studentData = [
            [
                'username' => 'siswa.andi',
                'name' => 'Andi Pratama',
                'nis' => '2024001',
                'class' => 'XII RPL 1',
                'major' => 'Rekayasa Perangkat Lunak',
                'phone' => '083456789012',
                'password' => 'andi2024',
            ],
            [
                'username' => 'siswa.dewi',
                'name' => 'Dewi Lestari',
                'nis' => '2024002',
                'class' => 'XII RPL 1',
                'major' => 'Rekayasa Perangkat Lunak',
                'phone' => '083456789013',
                'password' => 'dewi2024',
            ],
            [
                'username' => 'siswa.reza',
                'name' => 'Reza Firmansyah',
                'nis' => '2024003',
                'class' => 'XII TKJ 1',
                'major' => 'Teknik Komputer Jaringan',
                'phone' => '083456789014',
                'password' => 'reza2024',
            ],
            [
                'username' => 'siswa.maya',
                'name' => 'Maya Anggraini',
                'nis' => '2024004',
                'class' => 'XII TKJ 1',
                'major' => 'Teknik Komputer Jaringan',
                'phone' => '083456789015',
                'password' => 'maya2024',
            ],
        ];

        $defaultStudentPassword = env('STUDENT_INITIAL_PASSWORD', 'password');

        foreach ($studentData as $data) {
            $user = User::firstOrCreate(
                ['username' => $data['username']],
                [
                    'name' => $data['name'],
                    'email' => null,
                    'password' => Hash::make($data['password'] ?? $defaultStudentPassword),
                    'role' => 'student',
                    'is_active' => true,
                ]
            );

            Student::firstOrCreate(
                ['user_id' => $user->id],
                [
                    'nis' => $data['nis'],
                    'name' => $data['name'],
                    'class' => $data['class'],
                    'major' => $data['major'],
                    'phone' => $data['phone'],
                ]
            );
        }

        $this->command->info('✓ Users seeded successfully.');
        $this->command->info('  Admin/teacher/supervisor password: "password"');
        $this->command->info('  admin       → admin');
        $this->command->info('  teacher     → guru.budi / guru.siti');
        $this->command->info('  supervisor  → pembimbing.agus / pembimbing.rina');
        $this->command->info('  student     → siswa.andi/andi2024, siswa.dewi/dewi2024, siswa.reza/reza2024, siswa.maya/maya2024');
    }
}
