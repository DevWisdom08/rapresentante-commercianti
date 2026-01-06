<?php

namespace App\Services;

use App\Models\Transazione;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

/**
 * Service per implementare la REGOLA FONDAMENTALE del sistema:
 * I punti guadagnati in un negozio NON possono essere spesi nello stesso negozio
 */
class BloccoStessoNegozioService
{
    /**
     * Verifica se un cliente può spendere punti presso un esercente
     * 
     * REGOLA: Cliente NON può spendere punti nell'esercente dove li ha guadagnati
     * 
     * @param int $clienteId
     * @param int $esercenteId
     * @return bool True se può spendere, False se bloccato
     */
    public function puoSpenderePunti(int $clienteId, int $esercenteId): bool
    {
        // Cache key univoca per questa coppia cliente-esercente
        $cacheKey = "blocco_negozio_{$clienteId}_{$esercenteId}";

        // Usa cache per 5 minuti (performance)
        return Cache::remember($cacheKey, 300, function () use ($clienteId, $esercenteId) {
            
            // Cerca se cliente ha MAI ricevuto punti da questo esercente
            $haRicevutoPuntiDaQui = Transazione::where('destinatario_id', $clienteId)
                ->where('mittente_id', $esercenteId)
                ->where('tipo', 'assegnazione')
                ->exists();

            if ($haRicevutoPuntiDaQui) {
                Log::warning("BLOCCO STESSO NEGOZIO: Cliente {$clienteId} ha provato a spendere punti in Esercente {$esercenteId} dove li ha guadagnati");
                return false;
            }

            return true;
        });
    }

    /**
     * Verifica avanzata: calcola quanti punti cliente può spendere presso esercente
     * 
     * Versione avanzata (opzionale per fase 2):
     * - Cliente ha 100 punti totali
     * - 70 punti da Negozio A
     * - 30 punti da Negozio B
     * - Nel Negozio A può spendere MAX 30 punti (quelli da B)
     * 
     * Per MVP: Usiamo blocco totale (più semplice)
     * 
     * @param int $clienteId
     * @param int $esercenteId
     * @return float Punti spendibili
     */
    public function calcolaPuntiSpendibili(int $clienteId, int $esercenteId): float
    {
        // Versione MVP: Blocco totale
        // Se ha ricevuto punti da questo negozio, può spendere 0
        if (!$this->puoSpenderePunti($clienteId, $esercenteId)) {
            return 0.00;
        }

        // Altrimenti può spendere tutto il suo saldo
        $wallet = \App\Models\User::find($clienteId)->wallet;
        return $wallet ? $wallet->saldo_punti : 0.00;

        /* 
         * VERSIONE AVANZATA (Fase 2 - opzionale):
         * 
         * $puntiRicevutiDaQui = Transazione::where('destinatario_id', $clienteId)
         *     ->where('mittente_id', $esercenteId)
         *     ->where('tipo', 'assegnazione')
         *     ->sum('punti');
         * 
         * $puntiGiaSpesi = Transazione::where('mittente_id', $clienteId)
         *     ->where('destinatario_id', $esercenteId)
         *     ->where('tipo', 'pagamento')
         *     ->sum('punti');
         * 
         * $puntiNonSpendibili = $puntiRicevutiDaQui - $puntiGiaSpesi;
         * $saldoTotale = $wallet->saldo_punti;
         * 
         * return max(0, $saldoTotale - $puntiNonSpendibili);
         */
    }

    /**
     * Ottieni lista esercenti dove cliente può spendere punti
     * 
     * @param int $clienteId
     * @return array Array di IDs esercenti
     */
    public function getEsercentiDisponibili(int $clienteId): array
    {
        // Trova tutti gli esercenti da cui il cliente ha ricevuto punti
        $esercentiBloccati = Transazione::where('destinatario_id', $clienteId)
            ->where('tipo', 'assegnazione')
            ->distinct('mittente_id')
            ->pluck('mittente_id')
            ->toArray();

        // Restituisci tutti gli esercenti TRANNE quelli bloccati
        return \App\Models\User::where('ruolo', 'esercente')
            ->where('attivo', true)
            ->whereNotIn('id', $esercentiBloccati)
            ->pluck('id')
            ->toArray();
    }

    /**
     * Ottieni lista esercenti bloccati per un cliente
     * 
     * @param int $clienteId
     * @return array Array di User (esercenti)
     */
    public function getEsercentiBloccati(int $clienteId): array
    {
        $esercentiIds = Transazione::where('destinatario_id', $clienteId)
            ->where('tipo', 'assegnazione')
            ->distinct('mittente_id')
            ->pluck('mittente_id')
            ->toArray();

        return \App\Models\User::whereIn('id', $esercentiIds)
            ->with('esercente')
            ->get()
            ->toArray();
    }

    /**
     * Pulisci cache blocco per cliente-esercente specifico
     * (da chiamare se cambiano le regole o per debug)
     * 
     * @param int $clienteId
     * @param int|null $esercenteId Se null, pulisce tutta la cache del cliente
     */
    public function pulisciCache(int $clienteId, ?int $esercenteId = null): void
    {
        if ($esercenteId) {
            $cacheKey = "blocco_negozio_{$clienteId}_{$esercenteId}";
            Cache::forget($cacheKey);
            Log::info("Cache blocco pulita per Cliente {$clienteId} - Esercente {$esercenteId}");
        } else {
            // Pulisci tutta la cache del cliente (tutte le coppie)
            $esercenti = \App\Models\User::where('ruolo', 'esercente')->pluck('id');
            foreach ($esercenti as $esId) {
                Cache::forget("blocco_negozio_{$clienteId}_{$esId}");
            }
            Log::info("Cache blocco pulita per tutti gli esercenti del Cliente {$clienteId}");
        }
    }

    /**
     * Ottieni report dettagliato blocchi per un cliente
     * 
     * @param int $clienteId
     * @return array
     */
    public function getReportBlocchi(int $clienteId): array
    {
        $transazioni = Transazione::where('destinatario_id', $clienteId)
            ->where('tipo', 'assegnazione')
            ->with('mittente.esercente')
            ->get()
            ->groupBy('mittente_id');

        $report = [];
        foreach ($transazioni as $esercenteId => $trans) {
            $esercente = $trans->first()->mittente;
            $totalePunti = $trans->sum('punti');

            $report[] = [
                'esercente_id' => $esercenteId,
                'nome_negozio' => $esercente->esercente->nome_negozio ?? 'N/A',
                'punti_ricevuti_totali' => (float) $totalePunti,
                'numero_transazioni' => $trans->count(),
                'ultima_assegnazione' => $trans->max('created_at'),
                'puo_spendere' => false // Bloccato perché ha ricevuto punti
            ];
        }

        return $report;
    }
}

