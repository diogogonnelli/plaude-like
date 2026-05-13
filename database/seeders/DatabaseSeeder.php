<?php

namespace Database\Seeders;

use App\Modules\Identity\Models\Profile;
use App\Modules\Identity\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $this->call(ProfileSeeder::class);

        $adminProfile = Profile::where('code', 'admin')->first();

        if (!User::where('email', 'admin@sonora.app')->exists()) {
            User::create([
                'email' => 'admin@sonora.app',
                'full_name' => 'Administrador',
                'profile_id' => $adminProfile->id,
                'password' => 'password',
                'is_active' => true,
            ]);
        }
    }
}
