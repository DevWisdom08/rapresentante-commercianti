<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\WalletService;
use App\Services\BloccoStessoNegozioService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

/**
 * Controller per transazioni unificate (sconta + genera punti)
 */
class TransazioneController extends Controller
{
    protected $walletService;
    protected $bloccoService;

    public function __construct(WalletService $walletService, BloccoStessoNegozioService $bloccoService)
    {
        $this->walletService = $walletService;
        $this->bloccoService = $bloccoService;
    }

    /**
     * Transazione unificata: cliente usa sconto e genera nuovi punti
     * 
     * POST /api/v1/transazione/unificata
     * 
     * Body: {
     *   "cliente_id": 123,
     *   "categorie": [
     *     {"nome": "Alimentari", "importo": 50.00, "sconto_max_percentuale": 30},
     *     {"nome": "Bevande", "importo": 30.00, "sconto_max_percentuale": 20}
     *   ]
     * }
     */
    public function transazioneUnificata(Request $request)
    {
        $esercente = $request->user();

        if (!$esercente->isEsercente()) {
            return $this->errorResponse('Solo esercenti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'cliente_id' => 'required|integer|exists:users,id',
            'categorie' => 'required|array|min:1',
            'categorie.*.nome' => 'required|string',
            'categorie.*.importo' => 'required|numeric|min:0.01',
            'categorie.*.sconto_max_percentuale' => 'required|integer|min:0|max:100',
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            $cliente = User::find($request->cliente_id);
            
            if (!$cliente || !$cliente->isCliente()) {
                return $this->errorResponse('Cliente non valido', 'INVALID_CLIENT', null, 400);
            }

            // Calcola totale acquisto
            $totaleAcquisto = collect($request->categorie)->sum('importo');

            // Calcola sconto massimo applicabile per categoria
            $scontoMaxTotale = 0;
            $dettaglioCategorie = [];
            
            foreach ($request->categorie as $cat) {
                $importoCat = $cat['importo'];
                $percentuale = $cat['sconto_max_percentuale'];
                $scontoMaxCat = ($importoCat * $percentuale) / 100;
                $scontoMaxTotale += $scontoMaxCat;
                
                $dettaglioCategorie[] = [
                    'nome' => $cat['nome'],
                    'importo' => $importoCat,
                    'sconto_max_percentuale' => $percentuale,
                    'sconto_max_euro' => round($scontoMaxCat, 2),
                ];
            }

            // Verifica punti disponibili cliente
            $walletCliente = $cliente->wallet;
            $puntiDisponibili = $walletCliente ? $walletCliente->saldo_punti : 0;

            // Verifica blocco stesso negozio
            $puoSpendere = $this->bloccoService->puoSpenderePunti($cliente->id, $esercente->id);
            $puntiSpendibili = $puoSpendere ? min($puntiDisponibili, $scontoMaxTotale) : 0;

            // Calcola importo da pagare
            $scontoApplicato = $puntiSpendibili;
            $importoDaPagare = $totaleAcquisto - $scontoApplicato;

            // Genera nuovi punti sull'importo pagato
            // Usa rapporto configurato: X euro = 1 punto
            $euroPerPunto = config('app.euro_per_punto', 10.00);
            $nuoviPuntiGenerati = $importoDaPagare / $euroPerPunto;

            // Esegui transazione in database
            DB::transaction(function () use (
                $cliente, $esercente, $puntiSpendibili, $importoDaPagare, 
                $nuoviPuntiGenerati, $totaleAcquisto, $dettaglioCategorie
            ) {
                $walletCliente = $cliente->wallet;
                $walletEsercente = $esercente->wallet;

                // 1. Se cliente usa punti, sottrai e registra pagamento
                if ($puntiSpendibili > 0) {
                    $walletCliente->rimuoviPunti($puntiSpendibili, 'Pagamento con punti');
                    $walletEsercente->registraPuntiIncassati($puntiSpendibili);
                    $walletEsercente->rimuoviPunti($puntiSpendibili, 'Sconto applicato');

                    \App\Models\Transazione::creaPagamento(
                        $cliente->id,
                        $esercente->id,
                        $puntiSpendibili,
                        $esercente->id,
                        'Pagamento con sconto',
                        ['categorie' => $dettaglioCategorie]
                    );
                }

                // 2. Genera nuovi punti per importo pagato in contanti
                if ($nuoviPuntiGenerati > 0) {
                    $walletCliente->aggiungiPunti($nuoviPuntiGenerati, 'Acquisto presso esercente');
                    $walletEsercente->registraPuntiEmessi($nuoviPuntiGenerati);

                    \App\Models\Transazione::creaAssegnazione(
                        $esercente->id,
                        $cliente->id,
                        $nuoviPuntiGenerati,
                        $importoDaPagare,
                        'Nuovi punti da acquisto',
                        ['categorie' => $dettaglioCategorie]
                    );
                }
            });

            return $this->successResponse([
                'riepilogo' => [
                    'totale_acquisto' => round($totaleAcquisto, 2),
                    'sconto_applicato' => round($scontoApplicato, 2),
                    'importo_da_pagare' => round($importoDaPagare, 2),
                    'nuovi_punti_generati' => round($nuoviPuntiGenerati, 2),
                ],
                'dettaglio_categorie' => $dettaglioCategorie,
                'cliente' => [
                    'nome' => $cliente->nome . ' ' . $cliente->cognome,
                    'punti_prima' => round($puntiDisponibili, 2),
                    'punti_usati' => round($puntiSpendibili, 2),
                    'punti_generati' => round($nuoviPuntiGenerati, 2),
                    'nuovo_saldo' => round($puntiDisponibili - $puntiSpendibili + $nuoviPuntiGenerati, 2),
                ],
                'blocco_stesso_negozio' => !$puoSpendere,
            ], 'Transazione completata con successo');

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore transazione: ' . $e->getMessage(),
                'TRANSACTION_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Anteprima calcolo transazione (senza salvare)
     */
    public function anteprimaTransazione(Request $request)
    {
        $esercente = $request->user();

        $validator = Validator::make($request->all(), [
            'cliente_id' => 'required|integer|exists:users,id',
            'categorie' => 'required|array|min:1',
            'categorie.*.importo' => 'required|numeric|min:0.01',
            'categorie.*.sconto_max_percentuale' => 'required|integer|min:0|max:100',
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            $cliente = User::find($request->cliente_id);
            
            // Calcoli
            $totaleAcquisto = collect($request->categorie)->sum('importo');
            $scontoMaxTotale = 0;
            
            foreach ($request->categorie as $cat) {
                $scontoMaxTotale += ($cat['importo'] * $cat['sconto_max_percentuale']) / 100;
            }

            $walletCliente = $cliente->wallet;
            $puntiDisponibili = $walletCliente ? $walletCliente->saldo_punti : 0;
            $puoSpendere = $this->bloccoService->puoSpenderePunti($cliente->id, $esercente->id);
            $puntiSpendibili = $puoSpendere ? min($puntiDisponibili, $scontoMaxTotale) : 0;
            $scontoApplicato = $puntiSpendibili;
            $importoDaPagare = $totaleAcquisto - $scontoApplicato;
            
            // Usa rapporto configurato per nuovi punti
            $euroPerPunto = config('app.euro_per_punto', 10.00);
            $nuoviPuntiGenerati = round($importoDaPagare / $euroPerPunto, 2);

            return $this->successResponse([
                'totale_acquisto' => round($totaleAcquisto, 2),
                'sconto_max_applicabile' => round($scontoMaxTotale, 2),
                'punti_disponibili_cliente' => round($puntiDisponibili, 2),
                'punti_utilizzabili' => round($puntiSpendibili, 2),
                'sconto_applicato' => round($scontoApplicato, 2),
                'importo_da_pagare' => round($importoDaPagare, 2),
                'nuovi_punti_generati' => round($nuoviPuntiGenerati, 2),
                'nuovo_saldo_cliente' => round($puntiDisponibili - $puntiSpendibili + $nuoviPuntiGenerati, 2),
                'puo_usare_sconto' => $puoSpendere,
                'motivo_blocco' => !$puoSpendere ? 'Punti guadagnati in questo negozio' : null,
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 'PREVIEW_ERROR', null, 500);
        }
    }
}

