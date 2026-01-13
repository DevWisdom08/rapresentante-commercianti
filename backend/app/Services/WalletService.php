<?php

namespace App\Services;

use App\Models\User;
use App\Models\Wallet;
use App\Models\Transazione;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Service per gestione Wallet e transazioni punti
 */
class WalletService
{
    /**
     * Crea wallet per nuovo utente con bonus benvenuto se cliente
     * 
     * @param User $user
     * @return Wallet
     */
    public function creaWalletNuovoUtente(User $user): Wallet
    {
        $saldoIniziale = 0.00;

        // Bonus benvenuto solo per clienti
        if ($user->isCliente()) {
            $saldoIniziale = config('app.bonus_benvenuto', 10.00);
        }

        $wallet = Wallet::create([
            'user_id' => $user->id,
            'saldo_punti' => $saldoIniziale,
            'punti_emessi' => 0.00,
            'punti_incassati' => 0.00,
            'ultimo_aggiornamento' => now()
        ]);

        // Log transazione bonus se cliente
        if ($user->isCliente() && $saldoIniziale > 0) {
            Transazione::create([
                'mittente_id' => null,
                'destinatario_id' => $user->id,
                'punti' => $saldoIniziale,
                'tipo' => 'bonus_benvenuto',
                'descrizione' => 'Bonus di benvenuto',
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent()
            ]);

            Log::info("Wallet creato per utente {$user->id} con bonus benvenuto di {$saldoIniziale} punti");
        }

        return $wallet;
    }

    /**
     * Assegna punti da esercente a cliente
     * 
     * @param int $esercenteId
     * @param int $clienteId
     * @param float $importoEuro
     * @param string|null $descrizione
     * @param array $metadata
     * @return array
     * @throws \Exception
     */
    public function assegnaPuntiCliente(
        int $esercenteId,
        int $clienteId,
        float $importoEuro,
        ?string $descrizione = null,
        array $metadata = []
    ): array {
        return DB::transaction(function () use ($esercenteId, $clienteId, $importoEuro, $descrizione, $metadata) {
            
            // Verifica esercente
            $esercente = User::find($esercenteId);
            if (!$esercente || !$esercente->isEsercente()) {
                throw new \Exception('Esercente non valido');
            }

            // Verifica cliente
            $cliente = User::find($clienteId);
            if (!$cliente || !$cliente->isCliente()) {
                throw new \Exception('Cliente non valido');
            }

            // Calcola punti usando rapporto configurato
            // Default: 10 euro = 1 punto
            $euroPerPunto = config('app.euro_per_punto', 10.00);
            $punti = $importoEuro / $euroPerPunto;

            // Limiti configurabili
            $limiteMax = config('app.limite_max_punti_transazione', 500.00);
            if ($punti > $limiteMax) {
                throw new \Exception("Limite massimo punti per transazione superato (max: {$limiteMax})");
            }

            // Ottieni wallet
            $walletCliente = $cliente->wallet;
            $walletEsercente = $esercente->wallet;

            if (!$walletCliente || !$walletEsercente) {
                throw new \Exception('Wallet non trovati');
            }

            // Aggiorna wallet cliente
            $walletCliente->aggiungiPunti($punti, 'Acquisto presso esercente');

            // Aggiorna wallet esercente (punti emessi)
            $walletEsercente->registraPuntiEmessi($punti);

            // Crea transazione
            $transazione = Transazione::creaAssegnazione(
                $esercenteId,
                $clienteId,
                $punti,
                $importoEuro,
                $descrizione,
                $metadata
            );

            Log::info("Punti assegnati: Esercente {$esercenteId} → Cliente {$clienteId}: {$punti} punti");

            return [
                'transazione_id' => $transazione->id,
                'punti_assegnati' => $punti,
                'nuovo_saldo_cliente' => $walletCliente->saldo_punti,
                'wallet_esercente' => [
                    'punti_emessi' => $walletEsercente->punti_emessi,
                    'punti_incassati' => $walletEsercente->punti_incassati,
                    'saldo' => $walletEsercente->saldo_esercente
                ]
            ];
        });
    }

    /**
     * Cliente paga con punti presso esercente
     * 
     * @param int $clienteId
     * @param int $esercenteId
     * @param float $punti
     * @param string|null $descrizione
     * @param array $metadata
     * @return array
     * @throws \Exception
     */
    public function pagaConPunti(
        int $clienteId,
        int $esercenteId,
        float $punti,
        ?string $descrizione = null,
        array $metadata = []
    ): array {
        return DB::transaction(function () use ($clienteId, $esercenteId, $punti, $descrizione, $metadata) {
            
            // Verifica cliente
            $cliente = User::find($clienteId);
            if (!$cliente || !$cliente->isCliente()) {
                throw new \Exception('Cliente non valido');
            }

            // Verifica esercente
            $esercente = User::find($esercenteId);
            if (!$esercente || !$esercente->isEsercente()) {
                throw new \Exception('Esercente non valido');
            }

            // REGOLA FONDAMENTALE: Blocco stesso negozio
            $bloccoService = new BloccoStessoNegozioService();
            if (!$bloccoService->puoSpenderePunti($clienteId, $esercenteId)) {
                throw new \Exception('Non puoi spendere punti in questo negozio perché li hai guadagnati qui');
            }

            // Ottieni wallet
            $walletCliente = $cliente->wallet;
            $walletEsercente = $esercente->wallet;

            if (!$walletCliente || !$walletEsercente) {
                throw new \Exception('Wallet non trovati');
            }

            // Verifica saldo sufficiente
            if (!$walletCliente->hasSaldoSufficiente($punti)) {
                throw new \Exception("Saldo insufficiente. Disponibile: {$walletCliente->saldo_punti}, Richiesto: {$punti}");
            }

            // Aggiorna wallet cliente (sottrae punti)
            $walletCliente->rimuoviPunti($punti, 'Pagamento con punti');

            // Aggiorna wallet esercente (punti incassati + decrementa saldo)
            $walletEsercente->registraPuntiIncassati($punti);
            $walletEsercente->rimuoviPunti($punti, 'Sconto applicato per pagamento cliente');

            // Determina esercente origine (dove il cliente ha guadagnato i punti)
            $esercenteOrigineId = $this->trovaEsercenteOriginePunti($clienteId, $esercenteId);

            // Crea transazione
            $transazione = Transazione::creaPagamento(
                $clienteId,
                $esercenteId,
                $punti,
                $esercenteOrigineId,
                $descrizione,
                $metadata
            );

            Log::info("Pagamento punti: Cliente {$clienteId} → Esercente {$esercenteId}: {$punti} punti");

            return [
                'transazione_id' => $transazione->id,
                'punti_utilizzati' => $punti,
                'nuovo_saldo_cliente' => $walletCliente->saldo_punti,
                'wallet_esercente' => [
                    'punti_emessi' => $walletEsercente->punti_emessi,
                    'punti_incassati' => $walletEsercente->punti_incassati,
                    'saldo' => $walletEsercente->saldo_esercente
                ]
            ];
        });
    }

    /**
     * Assegna bonus evento a cliente
     * 
     * @param int $clienteId
     * @param int $eventoId
     * @param float $bonusPunti
     * @return array
     * @throws \Exception
     */
    public function assegnaBonusEvento(int $clienteId, int $eventoId, float $bonusPunti): array
    {
        return DB::transaction(function () use ($clienteId, $eventoId, $bonusPunti) {
            
            $cliente = User::find($clienteId);
            if (!$cliente || !$cliente->isCliente()) {
                throw new \Exception('Cliente non valido');
            }

            $wallet = $cliente->wallet;
            if (!$wallet) {
                throw new \Exception('Wallet non trovato');
            }

            // Aggiungi punti
            $wallet->aggiungiPunti($bonusPunti, 'Bonus partecipazione evento');

            // Crea transazione
            $transazione = Transazione::create([
                'mittente_id' => null,
                'destinatario_id' => $clienteId,
                'punti' => $bonusPunti,
                'tipo' => 'bonus_evento',
                'descrizione' => 'Bonus partecipazione evento',
                'metadata' => ['evento_id' => $eventoId],
                'ip_address' => request()->ip(),
                'user_agent' => request()->userAgent()
            ]);

            Log::info("Bonus evento assegnato: Cliente {$clienteId} riceve {$bonusPunti} punti da evento {$eventoId}");

            return [
                'transazione_id' => $transazione->id,
                'punti_ricevuti' => $bonusPunti,
                'nuovo_saldo' => $wallet->saldo_punti
            ];
        });
    }

    /**
     * Trova l'esercente presso cui il cliente ha guadagnato i punti
     * (per tracking origine punti)
     * 
     * @param int $clienteId
     * @param int $esercenteEscluso
     * @return int|null
     */
    private function trovaEsercenteOriginePunti(int $clienteId, int $esercenteEscluso): ?int
    {
        $transazione = Transazione::where('destinatario_id', $clienteId)
            ->where('tipo', 'assegnazione')
            ->where('mittente_id', '!=', $esercenteEscluso)
            ->orderBy('created_at', 'desc')
            ->first();

        return $transazione ? $transazione->mittente_id : null;
    }

    /**
     * Ottieni storico transazioni utente
     * 
     * @param int $userId
     * @param int $limit
     * @param int $page
     * @return array
     */
    public function getStoricoTransazioni(int $userId, int $limit = 20, int $page = 1): array
    {
        $query = Transazione::perUtente($userId)
            ->with(['mittente', 'destinatario'])
            ->piuRecenti();

        $transazioni = $query->paginate($limit, ['*'], 'page', $page);

        return [
            'current_page' => $transazioni->currentPage(),
            'data' => $transazioni->items(),
            'total' => $transazioni->total(),
            'per_page' => $transazioni->perPage(),
            'last_page' => $transazioni->lastPage()
        ];
    }

    /**
     * Calcola statistiche wallet esercente
     * 
     * @param int $esercenteId
     * @param int $giorniIndietro
     * @return array
     */
    public function getStatisticheEsercente(int $esercenteId, int $giorniIndietro = 30): array
    {
        $esercente = User::find($esercenteId);
        if (!$esercente || !$esercente->isEsercente()) {
            throw new \Exception('Esercente non valido');
        }

        $wallet = $esercente->wallet;
        $dataInizio = now()->subDays($giorniIndietro);

        $puntiEmessiPeriodo = Transazione::where('mittente_id', $esercenteId)
            ->where('tipo', 'assegnazione')
            ->where('created_at', '>=', $dataInizio)
            ->sum('punti');

        $puntiIncassatiPeriodo = Transazione::where('destinatario_id', $esercenteId)
            ->where('tipo', 'pagamento')
            ->where('created_at', '>=', $dataInizio)
            ->sum('punti');

        $clientiUnici = Transazione::where('mittente_id', $esercenteId)
            ->where('tipo', 'assegnazione')
            ->where('created_at', '>=', $dataInizio)
            ->distinct('destinatario_id')
            ->count();

        $transazioniTotali = Transazione::where(function($q) use ($esercenteId) {
                $q->where('mittente_id', $esercenteId)
                  ->orWhere('destinatario_id', $esercenteId);
            })
            ->where('created_at', '>=', $dataInizio)
            ->count();

        return [
            'wallet' => [
                'punti_emessi' => $wallet->punti_emessi,
                'punti_incassati' => $wallet->punti_incassati,
                'saldo' => $wallet->saldo_esercente
            ],
            'statistiche_periodo' => [
                'clienti_unici' => $clientiUnici,
                'punti_emessi' => (float) $puntiEmessiPeriodo,
                'punti_incassati' => (float) $puntiIncassatiPeriodo,
                'transazioni_totali' => $transazioniTotali
            ]
        ];
    }
}

