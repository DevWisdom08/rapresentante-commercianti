<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Esercente;
use App\Services\WalletService;
use App\Services\BloccoStessoNegozioService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

/**
 * Controller per funzionalità Esercenti
 */
class EsercenteController extends Controller
{
    protected $walletService;
    protected $bloccoService;

    public function __construct(WalletService $walletService, BloccoStessoNegozioService $bloccoService)
    {
        $this->walletService = $walletService;
        $this->bloccoService = $bloccoService;
    }

    /**
     * Assegna punti a un cliente
     * 
     * POST /api/v1/esercente/assegna-punti
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function assegnaPunti(Request $request)
    {
        $esercente = $request->user();

        if (!$esercente->isEsercente()) {
            return $this->errorResponse('Solo esercenti possono assegnare punti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'cliente_email' => 'required_without:cliente_id|email',
            'cliente_id' => 'required_without:cliente_email|integer',
            'importo_euro' => 'required|numeric|min:0.01|max:10000',
            'descrizione' => 'nullable|string|max:500',
            'metadata' => 'nullable|array'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            // Trova cliente
            if ($request->has('cliente_email')) {
                $cliente = User::where('email', $request->cliente_email)
                    ->where('ruolo', 'cliente')
                    ->first();
            } else {
                $cliente = User::where('id', $request->cliente_id)
                    ->where('ruolo', 'cliente')
                    ->first();
            }

            if (!$cliente) {
                return $this->errorResponse('Cliente non trovato', 'CLIENT_NOT_FOUND', null, 404);
            }

            // Assegna punti
            $result = $this->walletService->assegnaPuntiCliente(
                $esercente->id,
                $cliente->id,
                $request->importo_euro,
                $request->descrizione,
                $request->metadata ?? []
            );

            return $this->successResponse(
                $result,
                'Punti assegnati con successo',
                201
            );

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore assegnazione punti: ' . $e->getMessage(),
                'ASSIGNMENT_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Accetta pagamento con punti da cliente
     * 
     * POST /api/v1/esercente/accetta-punti
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function accettaPunti(Request $request)
    {
        $esercente = $request->user();

        if (!$esercente->isEsercente()) {
            return $this->errorResponse('Solo esercenti possono accettare punti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'cliente_id' => 'required|integer|exists:users,id',
            'punti' => 'required|numeric|min:0.01|max:10000',
            'descrizione' => 'nullable|string|max:500',
            'metadata' => 'nullable|array'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            // Verifica blocco stesso negozio
            if (!$this->bloccoService->puoSpenderePunti($request->cliente_id, $esercente->id)) {
                return $this->errorResponse(
                    'Il cliente non può spendere punti in questo negozio perché li ha guadagnati qui',
                    'SAME_STORE_BLOCK',
                    null,
                    403
                );
            }

            // Processa pagamento
            $result = $this->walletService->pagaConPunti(
                $request->cliente_id,
                $esercente->id,
                $request->punti,
                $request->descrizione,
                $request->metadata ?? []
            );

            return $this->successResponse(
                $result,
                'Pagamento con punti completato'
            );

        } catch (\Exception $e) {
            $errorCode = 'PAYMENT_ERROR';
            $statusCode = 500;

            // Gestione errori specifici
            if (str_contains($e->getMessage(), 'Saldo insufficiente')) {
                $errorCode = 'INSUFFICIENT_POINTS';
                $statusCode = 400;
            } elseif (str_contains($e->getMessage(), 'non può spendere punti')) {
                $errorCode = 'SAME_STORE_BLOCK';
                $statusCode = 403;
            }

            return $this->errorResponse(
                $e->getMessage(),
                $errorCode,
                null,
                $statusCode
            );
        }
    }

    /**
     * Dashboard esercente
     * 
     * GET /api/v1/esercente/dashboard
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function dashboard(Request $request)
    {
        $esercente = $request->user();

        if (!$esercente->isEsercente()) {
            return $this->errorResponse('Solo esercenti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $statistiche = $this->walletService->getStatisticheEsercente($esercente->id, 30);

            // Ultimi clienti
            $ultimiClienti = \App\Models\Transazione::where('mittente_id', $esercente->id)
                ->where('tipo', 'assegnazione')
                ->with('destinatario')
                ->orderBy('created_at', 'desc')
                ->limit(10)
                ->get()
                ->map(function($t) {
                    return [
                        'nome' => $t->destinatario->nome . ' ' . $t->destinatario->cognome,
                        'email' => $t->destinatario->email,
                        'punti_assegnati' => (float) $t->punti,
                        'importo_euro' => (float) $t->importo_euro,
                        'data' => $t->created_at
                    ];
                });

            // Trend ultima settimana
            $trendSettimana = [];
            for ($i = 6; $i >= 0; $i--) {
                $data = now()->subDays($i)->format('Y-m-d');
                
                $emessi = \App\Models\Transazione::where('mittente_id', $esercente->id)
                    ->where('tipo', 'assegnazione')
                    ->whereDate('created_at', $data)
                    ->sum('punti');

                $incassati = \App\Models\Transazione::where('destinatario_id', $esercente->id)
                    ->where('tipo', 'pagamento')
                    ->whereDate('created_at', $data)
                    ->sum('punti');

                $trendSettimana[] = [
                    'giorno' => $data,
                    'emessi' => (float) $emessi,
                    'incassati' => (float) $incassati
                ];
            }

            return $this->successResponse([
                'wallet' => $statistiche['wallet'],
                'statistiche' => $statistiche['statistiche_periodo'],
                'ultimi_clienti' => $ultimiClienti,
                'trend_settimana' => $trendSettimana
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore caricamento dashboard: ' . $e->getMessage(),
                'DASHBOARD_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Lista esercenti della stessa zona
     * 
     * GET /api/v1/esercente/lista-zona
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function listaZona(Request $request)
    {
        $user = $request->user();

        // Accessibile a clienti ed esercenti
        if (!$user->hasAnyRole(['cliente', 'esercente'])) {
            return $this->errorResponse('Non autorizzato', 'UNAUTHORIZED', null, 403);
        }

        try {
            // Trova esercenti attivi
            $esercenti = Esercente::attivi()
                ->with('user')
                ->get()
                ->map(function($e) {
                    return [
                        'id' => $e->user->id,
                        'nome_negozio' => $e->nome_negozio,
                        'categoria' => $e->categoria,
                        'categoria_formattata' => $e->categoria_formattata,
                        'indirizzo' => $e->indirizzo_completo,
                        'telefono' => $e->telefono_negozio,
                        'descrizione' => $e->descrizione,
                        'logo_url' => $e->logo_url
                    ];
                });

            return $this->successResponse($esercenti->toArray());

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore caricamento esercenti: ' . $e->getMessage(),
                'FETCH_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Verifica se cliente può spendere punti
     * 
     * POST /api/v1/esercente/verifica-cliente
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verificaCliente(Request $request)
    {
        $esercente = $request->user();

        if (!$esercente->isEsercente()) {
            return $this->errorResponse('Solo esercenti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'cliente_id' => 'required|integer|exists:users,id'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            $cliente = User::find($request->cliente_id);
            
            if (!$cliente || !$cliente->isCliente()) {
                return $this->errorResponse('Cliente non valido', 'INVALID_CLIENT', null, 400);
            }

            $puoSpendere = $this->bloccoService->puoSpenderePunti($cliente->id, $esercente->id);
            $puntiSpendibili = $this->bloccoService->calcolaPuntiSpendibili($cliente->id, $esercente->id);

            return $this->successResponse([
                'cliente' => [
                    'id' => $cliente->id,
                    'nome' => $cliente->nome . ' ' . $cliente->cognome,
                    'email' => $cliente->email
                ],
                'wallet' => [
                    'saldo_totale' => (float) $cliente->wallet->saldo_punti,
                    'punti_spendibili_qui' => (float) $puntiSpendibili
                ],
                'puo_spendere' => $puoSpendere,
                'motivo_blocco' => !$puoSpendere ? 'Punti guadagnati in questo negozio' : null
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore verifica cliente: ' . $e->getMessage(),
                'VERIFICATION_ERROR',
                null,
                500
            );
        }
    }
}

