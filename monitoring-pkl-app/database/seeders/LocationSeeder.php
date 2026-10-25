<?php

namespace Database\Seeders;

use App\Models\FieldSupervisor;
use App\Models\Location;
use Illuminate\Database\Seeder;

class LocationSeeder extends Seeder
{
    public function run(): void
    {
        $locations = [
            [
                'name' => 'PT. Maju Bersama',
                'address' => 'Jl. Sudirman No. 123, Jakarta Pusat, DKI Jakarta',
                'latitude' => -6.208763,
                'longitude' => 106.845599,
                'radius' => 100,
            ],
            [
                'name' => 'CV. Teknologi Nusantara',
                'address' => 'Jl. Gatot Subroto No. 45, Jakarta Selatan, DKI Jakarta',
                'latitude' => -6.227945,
                'longitude' => 106.800626,
                'radius' => 150,
            ],
            [
                'name' => 'PT. Digital Indonesia',
                'address' => 'Jl. Thamrin No. 67, Jakarta Pusat, DKI Jakarta',
                'latitude' => -6.193033,
                'longitude' => 106.823246,
                'radius' => 100,
            ],
        ];

        foreach ($locations as $data) {
            $location = Location::firstOrCreate(
                ['name' => $data['name']],
                [
                    'address' => $data['address'],
                    'latitude' => $data['latitude'],
                    'longitude' => $data['longitude'],
                    'radius' => $data['radius'],
                    'is_active' => true,
                ]
            );

            // Link matching supervisor if exists
            if ($data['name'] === 'PT. Maju Bersama') {
                $spv = FieldSupervisor::where('name', 'Agus Wijaya')->first();
                if ($spv) {
                    $location->fieldSupervisors()->syncWithoutDetaching([$spv->id]);
                }
            } elseif ($data['name'] === 'CV. Teknologi Nusantara') {
                $spv = FieldSupervisor::where('name', 'Rina Kusuma')->first();
                if ($spv) {
                    $location->fieldSupervisors()->syncWithoutDetaching([$spv->id]);
                }
            }
        }

        $this->command->info('✓ Locations seeded successfully.');
    }
}
