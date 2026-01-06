<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Seeder principale database
 */
class DatabaseSeeder extends Seeder
{
    /**
     * Seed del database dell'applicazione
     */
    public function run(): void
    {
        $this->call([
            UserSeeder::class,
        ]);

        $this->command->info('✅ Database seedato con successo!');
        $this->command->info('');
        $this->command->info('📧 Credenziali di accesso:');
        $this->command->info('');
        $this->command->info('🔑 CENTRALE (Admin):');
        $this->command->info('   Email: admin@rapresentante.it');
        $this->command->info('   Password: Password123!');
        $this->command->info('');
        $this->command->info('👔 RAPPRESENTANTE:');
        $this->command->info('   Email: rappresentante.milano@rapresentante.it');
        $this->command->info('   Password: Password123!');
        $this->command->info('');
        $this->command->info('🏪 ESERCENTI:');
        $this->command->info('   Email: panificio@test.it | Password: Password123!');
        $this->command->info('   Email: abbigliamento@test.it | Password: Password123!');
        $this->command->info('   Email: ferramenta@test.it | Password: Password123!');
        $this->command->info('');
        $this->command->info('👤 CLIENTI:');
        $this->command->info('   Email: mario.rossi@test.it | Password: Password123!');
        $this->command->info('   Email: laura.bianchi@test.it | Password: Password123!');
        $this->command->info('   Email: paolo.verdi@test.it | Password: Password123!');
    }
}

