<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Wallet;
use App\Models\Rappresentante;
use App\Models\Esercente;
use App\Models\Transazione;

/**
 * Seeder utenti di test
 */
class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $password = Hash::make('Password123!');

        // 1. UTENTE CENTRALE (Admin)
        $centrale = User::create([
            'email' => 'admin@rapresentante.it',
            'password' => $password,
            'nome' => 'Admin',
            'cognome' => 'Centrale',
            'telefono' => '+393001234567',
            'ruolo' => 'centrale',
            'email_verified_at' => now(),
            'attivo' => true
        ]);
        $this->command->info('✓ Creato utente CENTRALE');

        // 2. RAPPRESENTANTE MILANO
        $rappresentanteUser = User::create([
            'email' => 'rappresentante.milano@rapresentante.it',
            'password' => $password,
            'nome' => 'Marco',
            'cognome' => 'Rossetti',
            'telefono' => '+393001234568',
            'ruolo' => 'rappresentante',
            'email_verified_at' => now(),
            'attivo' => true
        ]);

        $rappresentante = Rappresentante::create([
            'user_id' => $rappresentanteUser->id,
            'nome_zona' => 'Milano Centro',
            'provincia' => 'MI',
            'comuni_coperti' => ['Milano', 'Sesto San Giovanni', 'Cinisello Balsamo'],
            'num_esercenti' => 0,
            'num_clienti' => 0,
            'data_nomina' => now()->subMonths(6),
            'note' => 'Zona pilota del progetto'
        ]);
        $this->command->info('✓ Creato RAPPRESENTANTE Milano');

        // 3. ESERCENTI (3 negozi)
        $esercenti = [];

        // Esercente 1: Panificio
        $esercenteUser1 = User::create([
            'email' => 'panificio@test.it',
            'password' => $password,
            'nome' => 'Giovanni',
            'cognome' => 'Panettieri',
            'telefono' => '+393001234569',
            'ruolo' => 'esercente',
            'email_verified_at' => now(),
            'attivo' => true
        ]);

        $wallet1 = Wallet::create([
            'user_id' => $esercenteUser1->id,
            'saldo_punti' => 0,
            'punti_emessi' => 0,
            'punti_incassati' => 0
        ]);

        $esercente1 = Esercente::create([
            'user_id' => $esercenteUser1->id,
            'rappresentante_id' => $rappresentante->id,
            'nome_negozio' => 'Panificio Da Giovanni',
            'partita_iva' => '12345678901',
            'indirizzo' => 'Via Roma 10',
            'citta' => 'Milano',
            'cap' => '20121',
            'provincia' => 'MI',
            'telefono_negozio' => '+390212345678',
            'categoria' => 'alimentari',
            'descrizione' => 'Pane fresco e focacce artigianali dal 1950',
            'attivo' => true,
            'data_adesione' => now()->subMonths(3)
        ]);
        $esercenti[] = $esercenteUser1;
        $this->command->info('✓ Creato ESERCENTE: Panificio');

        // Esercente 2: Abbigliamento
        $esercenteUser2 = User::create([
            'email' => 'abbigliamento@test.it',
            'password' => $password,
            'nome' => 'Laura',
            'cognome' => 'Modistini',
            'telefono' => '+393001234570',
            'ruolo' => 'esercente',
            'email_verified_at' => now(),
            'attivo' => true
        ]);

        $wallet2 = Wallet::create([
            'user_id' => $esercenteUser2->id,
            'saldo_punti' => 0,
            'punti_emessi' => 0,
            'punti_incassati' => 0
        ]);

        $esercente2 = Esercente::create([
            'user_id' => $esercenteUser2->id,
            'rappresentante_id' => $rappresentante->id,
            'nome_negozio' => 'Abbigliamento Moda Laura',
            'partita_iva' => '12345678902',
            'indirizzo' => 'Via Garibaldi 25',
            'citta' => 'Milano',
            'cap' => '20121',
            'provincia' => 'MI',
            'telefono_negozio' => '+390212345679',
            'categoria' => 'abbigliamento',
            'descrizione' => 'Abbigliamento uomo e donna, marchi italiani',
            'attivo' => true,
            'data_adesione' => now()->subMonths(3)
        ]);
        $esercenti[] = $esercenteUser2;
        $this->command->info('✓ Creato ESERCENTE: Abbigliamento');

        // Esercente 3: Ferramenta
        $esercenteUser3 = User::create([
            'email' => 'ferramenta@test.it',
            'password' => $password,
            'nome' => 'Paolo',
            'cognome' => 'Martelli',
            'telefono' => '+393001234571',
            'ruolo' => 'esercente',
            'email_verified_at' => now(),
            'attivo' => true
        ]);

        $wallet3 = Wallet::create([
            'user_id' => $esercenteUser3->id,
            'saldo_punti' => 0,
            'punti_emessi' => 0,
            'punti_incassati' => 0
        ]);

        $esercente3 = Esercente::create([
            'user_id' => $esercenteUser3->id,
            'rappresentante_id' => $rappresentante->id,
            'nome_negozio' => 'Ferramenta Martelli',
            'partita_iva' => '12345678903',
            'indirizzo' => 'Via Dante 15',
            'citta' => 'Milano',
            'cap' => '20121',
            'provincia' => 'MI',
            'telefono_negozio' => '+390212345680',
            'categoria' => 'casa_arredamento',
            'descrizione' => 'Ferramenta e articoli per la casa',
            'attivo' => true,
            'data_adesione' => now()->subMonths(3)
        ]);
        $esercenti[] = $esercenteUser3;
        $this->command->info('✓ Creato ESERCENTE: Ferramenta');

        // 4. CLIENTI (5 clienti di test)
        $clienti = [];

        for ($i = 1; $i <= 5; $i++) {
            $nomi = ['Mario', 'Laura', 'Paolo', 'Giulia', 'Andrea'];
            $cognomi = ['Rossi', 'Bianchi', 'Verdi', 'Neri', 'Gialli'];

            $clienteUser = User::create([
                'email' => strtolower($nomi[$i-1]) . '.' . strtolower($cognomi[$i-1]) . '@test.it',
                'password' => $password,
                'nome' => $nomi[$i-1],
                'cognome' => $cognomi[$i-1],
                'telefono' => '+39300123457' . (1 + $i),
                'ruolo' => 'cliente',
                'email_verified_at' => now(),
                'attivo' => true
            ]);

            // Wallet con bonus benvenuto
            $wallet = Wallet::create([
                'user_id' => $clienteUser->id,
                'saldo_punti' => 10.00,
                'punti_emessi' => 0,
                'punti_incassati' => 0
            ]);

            // Transazione bonus benvenuto
            Transazione::create([
                'mittente_id' => null,
                'destinatario_id' => $clienteUser->id,
                'punti' => 10.00,
                'tipo' => 'bonus_benvenuto',
                'descrizione' => 'Bonus di benvenuto',
                'created_at' => now()->subMonths(2)
            ]);

            $clienti[] = $clienteUser;
        }
        $this->command->info('✓ Creati 5 CLIENTI con bonus benvenuto');

        // 5. TRANSAZIONI DI TEST (simulare attività)
        
        // Cliente 1 acquista al panificio
        $wallet = Wallet::where('user_id', $clienti[0]->id)->first();
        $wallet->update(['saldo_punti' => $wallet->saldo_punti + 25.00]);
        
        $walletEsercente = Wallet::where('user_id', $esercenti[0]->id)->first();
        $walletEsercente->update(['punti_emessi' => 25.00]);

        Transazione::create([
            'mittente_id' => $esercenti[0]->id,
            'destinatario_id' => $clienti[0]->id,
            'punti' => 25.00,
            'importo_euro' => 25.00,
            'tipo' => 'assegnazione',
            'esercente_origine_id' => $esercenti[0]->id,
            'descrizione' => 'Acquisto pane e focacce',
            'created_at' => now()->subDays(10)
        ]);

        // Cliente 1 spende punti in abbigliamento
        $wallet->update(['saldo_punti' => $wallet->saldo_punti - 20.00]);
        
        $walletEsercente2 = Wallet::where('user_id', $esercenti[1]->id)->first();
        $walletEsercente2->update([
            'punti_incassati' => 20.00,
            'saldo_punti' => $walletEsercente2->saldo_punti - 20.00
        ]);

        Transazione::create([
            'mittente_id' => $clienti[0]->id,
            'destinatario_id' => $esercenti[1]->id,
            'punti' => 20.00,
            'tipo' => 'pagamento',
            'esercente_origine_id' => $esercenti[0]->id,
            'descrizione' => 'Pagamento con punti per maglietta',
            'created_at' => now()->subDays(5)
        ]);

        // Cliente 2 acquista in ferramenta
        $wallet2 = Wallet::where('user_id', $clienti[1]->id)->first();
        $wallet2->update(['saldo_punti' => $wallet2->saldo_punti + 50.00]);
        
        $walletEsercente3 = Wallet::where('user_id', $esercenti[2]->id)->first();
        $walletEsercente3->update(['punti_emessi' => 50.00]);

        Transazione::create([
            'mittente_id' => $esercenti[2]->id,
            'destinatario_id' => $clienti[1]->id,
            'punti' => 50.00,
            'importo_euro' => 50.00,
            'tipo' => 'assegnazione',
            'esercente_origine_id' => $esercenti[2]->id,
            'descrizione' => 'Acquisto utensili',
            'created_at' => now()->subDays(7)
        ]);

        $this->command->info('✓ Create transazioni di test');
        
        // Aggiorna contatori rappresentante
        $rappresentante->update([
            'num_esercenti' => 3,
            'num_clienti' => 5
        ]);

        $this->command->info('✓ Seed completato con successo!');
    }
}

