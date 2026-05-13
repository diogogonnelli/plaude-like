<?php

namespace Database\Seeders;

use App\Modules\Identity\Models\Profile;
use Illuminate\Database\Seeder;

class ProfileSeeder extends Seeder
{
    public function run(): void
    {
        Profile::updateOrCreate(
            ['code' => 'admin'],
            [
                'name' => 'Administrador',
                'description' => 'Acesso administrativo completo ao backoffice.',
                'is_system' => true,
            ]
        );

        Profile::updateOrCreate(
            ['code' => 'user'],
            [
                'name' => 'Usuário',
                'description' => 'Usuário padrão do produto.',
                'is_system' => true,
            ]
        );
    }
}
