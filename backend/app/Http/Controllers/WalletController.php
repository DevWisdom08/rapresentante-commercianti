<?php

namespace App\Http\Controllers;

use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Controller per gestione Wallet e transazioni
 */
class WalletController extends Controller
{
    protected $walletService;

    public function __construct(WalletService $walletService)
    {
        $this->walletService = $walletService;
    }

    /**
     * Ottieni wallet dell'utente autenticato
     * 
     * GET /api/v1/wallet
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getWallet(Request $request)
    {
        $user = $request->user();
        $wallet = $user->wallet;

        if (!$wallet) {
            return $this->errorResponse('Wallet non trovato', 'WALLET_NOT_FOUND', null, 404);
        }

        // Risposta diversa per cliente vs esercente
        if ($user->isCliente()) {
            return $this->successResponse([
                'saldo_punti' => (float) $wallet->saldo_punti,
                'ultimo_aggiornamento' => $wallet->ultimo_aggiornamento
            ]);
        }

        if ($user->isEsercente()) {
            return $this->successResponse([
                'saldo_punti' => (float) $wallet->saldo_punti,
                'punti_emessi' => (float) $wallet->punti_emessi,
                'punti_incassati' => (float) $wallet->punti_incassati,
                'saldo' => (float) $wallet->saldo_esercente,
                'ultimo_aggiornamento' => $wallet->ultimo_aggiornamento
            ]);
        }

        return $this->errorResponse('Ruolo non supporta wallet', 'ROLE_NOT_SUPPORTED', null, 400);
    }

    /**
     * Storico transazioni dell'utente autenticato
     * 
     * GET /api/v1/wallet/transazioni?page=1&limit=20&tipo=assegnazione
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTransazioni(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'page' => 'integer|min:1',
            'limit' => 'integer|min:1|max:100',
            'tipo' => 'string|in:assegnazione,pagamento,bonus_benvenuto,bonus_evento,rimborso,scadenza'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        $user = $request->user();
        $limit = $request->get('limit', 20);
        $page = $request->get('page', 1);

        try {
            $result = $this->walletService->getStoricoTransazioni($user->id, $limit, $page);

            // Formatta transazioni per risposta
            $transazioniFormatted = array_map(function($t) use ($user) {
                $formatted = [
                    'id' => $t->id,
                    'tipo' => $t->tipo,
                    'tipo_descrizione' => $t->tipo_descrizione,
                    'punti' => (float) $t->punti,
                    'importo_euro' => $t->importo_euro ? (float) $t->importo_euro : null,
                    'descrizione' => $t->descrizione,
                    'created_at' => $t->created_at
                ];

                // Aggiungi info mittente se esiste
                if ($t->mittente_id && $t->mittente_id != $user->id) {
                    $formatted['mittente'] = [
                        'id' => $t->mittente->id,
                        'nome' => $t->mittente->nome . ' ' . $t->mittente->cognome,
                        'tipo' => $t->mittente->ruolo
                    ];

                    if ($t->mittente->esercente) {
                        $formatted['mittente']['nome_negozio'] = $t->mittente->esercente->nome_negozio;
                    }
                }

                // Aggiungi info destinatario se diverso da utente corrente
                if ($t->destinatario_id != $user->id) {
                    $formatted['destinatario'] = [
                        'id' => $t->destinatario->id,
                        'nome' => $t->destinatario->nome . ' ' . $t->destinatario->cognome,
                        'tipo' => $t->destinatario->ruolo
                    ];

                    if ($t->destinatario->esercente) {
                        $formatted['destinatario']['nome_negozio'] = $t->destinatario->esercente->nome_negozio;
                    }
                }

                return $formatted;
            }, $result['data']);

            return $this->successResponse([
                'current_page' => $result['current_page'],
                'data' => $transazioniFormatted,
                'total' => $result['total'],
                'per_page' => $result['per_page'],
                'last_page' => $result['last_page']
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore recupero transazioni: ' . $e->getMessage(),
                'FETCH_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Dettaglio singola transazione
     * 
     * GET /api/v1/wallet/transazioni/{id}
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function getTransazione(Request $request, int $id)
    {
        $user = $request->user();
        $transazione = \App\Models\Transazione::with(['mittente.esercente', 'destinatario.esercente'])
            ->find($id);

        if (!$transazione) {
            return $this->errorResponse('Transazione non trovata', 'TRANSACTION_NOT_FOUND', null, 404);
        }

        // Verifica che l'utente sia coinvolto nella transazione
        if ($transazione->mittente_id != $user->id && $transazione->destinatario_id != $user->id) {
            // Se è centrale o rappresentante, può vedere tutto
            if (!$user->hasAnyRole(['centrale', 'rappresentante'])) {
                return $this->errorResponse('Non autorizzato', 'UNAUTHORIZED', null, 403);
            }
        }

        return $this->successResponse($transazione);
    }

    /**
     * Statistiche wallet (per esercenti)
     * 
     * GET /api/v1/wallet/statistiche?giorni=30
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getStatistiche(Request $request)
    {
        $user = $request->user();

        if (!$user->isEsercente()) {
            return $this->errorResponse(
                'Statistiche disponibili solo per esercenti',
                'ROLE_NOT_ALLOWED',
                null,
                403
            );
        }

        $giorni = $request->get('giorni', 30);
        
        try {
            $statistiche = $this->walletService->getStatisticheEsercente($user->id, $giorni);
            return $this->successResponse($statistiche);
        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore recupero statistiche: ' . $e->getMessage(),
                'FETCH_ERROR',
                null,
                500
            );
        }
    }
}

