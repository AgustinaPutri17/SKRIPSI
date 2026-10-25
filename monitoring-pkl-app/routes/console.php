<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('admin:create {--username=admin} {--email=admin@monitoring-pkl.test} {--password=}', function () {
    $username = $this->option('username') ?: $this->ask('Admin Username', 'admin');
    $email = $this->option('email') ?: $this->ask('Admin Email', 'admin@monitoring-pkl.test');
    $password = $this->option('password');

    if (empty($password)) {
        $password = $this->secret('Admin Password');
    }

    if (empty($password)) {
        $this->error('Password cannot be empty.');
        return 1;
    }

    $user = \App\Models\User::updateOrCreate(
        ['username' => $username],
        [
            'name' => 'Administrator',
            'email' => $email,
            'password' => \Illuminate\Support\Facades\Hash::make($password),
            'role' => 'admin',
            'is_active' => true,
        ]
    );

    $this->info("Admin account [{$user->username}] initialized/updated successfully.");
    return 0;
})->purpose('Safely create or update the primary Admin account');

use Illuminate\Support\Facades\Schedule;

Schedule::command('attendance:mark-absent')
    ->dailyAt('17:00')
    ->description('Evaluasi harian untuk menandai siswa yang Alfa (absent) setelah jam kerja DUDI selesai.');


