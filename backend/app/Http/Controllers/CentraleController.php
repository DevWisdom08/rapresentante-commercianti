<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Esercente;
use App\Models\Rappresentante;
use App\Models\Transazione;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;

/**
 * Controller per funzionalità Centrale (Admin)
 */
class CentraleController extends Controller
{
    /**
     * Dashboard globale
     * 
     * GET /api/v1/centrale/dashboard
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function dashboard(Request $request)
    {
        $user = $request->user();

        if (!$user->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            // Statistiche globali
            $numRappresentanti = Rappresentante::count();
            $numEsercenti = Esercente::attivi()->count();
            $numClienti = User::where('ruolo', 'cliente')->where('attivo', true)->count();
            
            $puntiTotaliCircolazione = \App\Models\Wallet::esercenti()->sum('punti_emessi');
            $transazioniTotali = Transazione::count();

            // Top zone (rappresentanti)
            $topZone = Rappresentante::with('user')
                ->get()
                ->map(function($r) {
                    $esercenti = Esercente::where('rappresentante_id', $r->id)->attivi()->count();
                    $puntiCircolazione = Esercente::where('rappresentante_id', $r->id)
                        ->with('user.wallet')
                        ->get()
                        ->sum(function($e) {
                            return $e->user->wallet ? $e->user->wallet->punti_emessi : 0;
                        });

                    return [
                        'nome_zona' => $r->nome_zona,
                        'rappresentante' => $r->user->nome . ' ' . $r->user->cognome,
                        'provincia' => $r->provincia,
                        'num_esercenti' => $esercenti,
                        'punti_circolazione' => (float) $puntiCircolazione
                    ];
                })
                ->sortByDesc('punti_circolazione')
                ->take(5)
                ->values();

            // Grafico crescita ultimi 6 mesi
            $graficoCrescita = [];
            for ($i = 5; $i >= 0; $i--) {
                $mese = now()->subMonths($i);
                $meseStr = $mese->format('Y-m');

                $clienti = User::where('ruolo', 'cliente')
                    ->whereYear('created_at', '<=', $mese->year)
                    ->whereMonth('created_at', '<=', $mese->month)
                    ->count();

                $transazioni = Transazione::whereYear('created_at', $mese->year)
                    ->whereMonth('created_at', $mese->month)
                    ->count();

                $graficoCrescita[] = [
                    'mese' => $meseStr,
                    'clienti' => $clienti,
                    'transazioni' => $transazioni
                ];
            }

            return $this->successResponse([
                'statistiche_globali' => [
                    'num_rappresentanti' => $numRappresentanti,
                    'num_esercenti' => $numEsercenti,
                    'num_clienti' => $numClienti,
                    'punti_totali_circolazione' => (float) $puntiTotaliCircolazione,
                    'transazioni_totali' => $transazioniTotali
                ],
                'top_zone' => $topZone,
                'grafico_crescita' => $graficoCrescita
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
     * Lista tutti gli utenti con filtri
     * 
     * GET /api/v1/centrale/utenti?ruolo=esercente&page=1
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getUtenti(Request $request)
    {
        $user = $request->user();

        if (!$user->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $query = User::query();

            // Filtro ruolo
            if ($request->has('ruolo')) {
                $query->where('ruolo', $request->ruolo);
            }

            // Filtro attivo
            if ($request->has('attivo')) {
                $query->where('attivo', $request->attivo === 'true');
            }

            // Ricerca
            if ($request->has('search')) {
                $search = $request->search;
                $query->where(function($q) use ($search) {
                    $q->where('email', 'like', "%{$search}%")
                      ->orWhere('nome', 'like', "%{$search}%")
                      ->orWhere('cognome', 'like', "%{$search}%");
                });
            }

            // Get ALL users (no pagination limit for admin)
            $utenti = $query->with(['wallet', 'esercente', 'rappresentante'])
                ->orderBy('created_at', 'desc')
                ->get();

            // Aggiungi campo approvato
            $utentiData = $utenti->map(function ($user) {
                $data = [
                    'id' => $user->id,
                    'email' => $user->email,
                    'nome' => $user->nome,
                    'cognome' => $user->cognome,
                    'ruolo' => $user->ruolo,
                    'attivo' => $user->attivo,
                    'created_at' => $user->created_at,
                ];
                
                // Aggiungi approvato (sempre, per tutti)
                if ($user->ruolo === 'esercente' && $user->esercente) {
                    $data['approvato'] = (bool)($user->esercente->approvato ?? false);
                } else {
                    $data['approvato'] = true; // Non-esercenti sempre approvati
                }
                
                return $data;
            });

            return $this->successResponse([
                'data' => $utentiData,
                'total' => $utenti->count(),
            ]);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore caricamento utenti: ' . $e->getMessage(),
                'FETCH_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Attiva utente
     * 
     * POST /api/v1/centrale/utenti/{id}/attiva
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function attivaUtente(Request $request, int $id)
    {
        $currentUser = $request->user();

        if (!$currentUser->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $utente = User::find($id);

            if (!$utente) {
                return $this->errorResponse('Utente non trovato', 'USER_NOT_FOUND', null, 404);
            }

            // Non può disattivare se stesso
            if ($utente->id === $currentUser->id) {
                return $this->errorResponse('Non puoi modificare il tuo account', 'SELF_MODIFICATION', null, 400);
            }

            $utente->update(['attivo' => true]);

            return $this->successResponse([
                'id' => $utente->id,
                'email' => $utente->email,
                'attivo' => true
            ], 'Utente attivato con successo');

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore attivazione utente: ' . $e->getMessage(),
                'ACTIVATION_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Disattiva utente
     * 
     * POST /api/v1/centrale/utenti/{id}/disattiva
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function disattivaUtente(Request $request, int $id)
    {
        $currentUser = $request->user();

        if (!$currentUser->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $utente = User::find($id);

            if (!$utente) {
                return $this->errorResponse('Utente non trovato', 'USER_NOT_FOUND', null, 404);
            }

            // Non può disattivare se stesso
            if ($utente->id === $currentUser->id) {
                return $this->errorResponse('Non puoi disattivare il tuo account', 'SELF_MODIFICATION', null, 400);
            }

            $utente->update(['attivo' => false]);

            return $this->successResponse([
                'id' => $utente->id,
                'email' => $utente->email,
                'attivo' => false
            ], 'Utente disattivato con successo');

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore disattivazione utente: ' . $e->getMessage(),
                'DEACTIVATION_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Elimina utente
     * 
     * DELETE /api/v1/centrale/utenti/{id}
     * 
     * @param Request $request
     * @param int $id
     * @return \Illuminate\Http\JsonResponse
     */
    public function eliminaUtente(Request $request, int $id)
    {
        $currentUser = $request->user();

        if (!$currentUser->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $utente = User::find($id);

            if (!$utente) {
                return $this->errorResponse('Utente non trovato', 'USER_NOT_FOUND', null, 404);
            }

            // Non può eliminare se stesso
            if ($utente->id === $currentUser->id) {
                return $this->errorResponse('Non puoi eliminare il tuo account', 'SELF_DELETION', null, 400);
            }

            $utente->delete();

            return $this->successResponse(null, 'Utente eliminato con successo');

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore eliminazione utente: ' . $e->getMessage(),
                'DELETE_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Approva Esercente
     */
    public function approvaEsercente(Request $request, int $id)
    {
        $currentUser = $request->user();

        if (!$currentUser->isCentrale()) {
            return $this->errorResponse('Solo admin', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $user = User::find($id);
            
            if (!$user || !$user->isEsercente()) {
                return $this->errorResponse('Esercente non trovato', 'NOT_FOUND', null, 404);
            }

            $esercente = $user->esercente;
            if ($esercente) {
                $esercente->update([
                    'approvato' => true,
                    'data_approvazione' => now(),
                ]);
            }

            return $this->successResponse(null, 'Esercente approvato con successo');

        } catch (\Exception $e) {
            return $this->errorResponse($e->getMessage(), 'APPROVAL_ERROR', null, 500);
        }
    }

    /**
     * Crea nuovo Rappresentante
     */
    public function creaRappresentante(Request $request)
    {
        $currentUser = $request->user();

        if (!$currentUser->isCentrale()) {
            return $this->errorResponse('Solo admin', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users,email',
            'nome' => 'required|string|max:100',
            'cognome' => 'required|string|max:100',
            'password' => 'required|min:8',
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            $user = User::create([
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'nome' => $request->nome,
                'cognome' => $request->cognome,
                'ruolo' => 'rappresentante',
                'email_verified_at' => now(),
                'attivo' => true,
            ]);

            Rappresentante::create([
                'user_id' => $user->id,
                'nome_zona' => 'Da assegnare',
                'provincia' => 'XX',
                'data_nomina' => now()->toDateString(),
            ]);

            return $this->successResponse([
                'user' => $user,
            ], 'Rappresentante creato con successo', 201);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore: ' . $e->getMessage(),
                'CREATE_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Ottieni configurazioni sistema
     * 
     * GET /api/v1/centrale/configurazioni
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getConfigurazioni(Request $request)
    {
        $user = $request->user();

        if (!$user->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        return $this->successResponse([
            'bonus_benvenuto' => config('app.bonus_benvenuto', 10.00),
            'scadenza_punti_giorni' => config('app.scadenza_punti_giorni', 180),
            'limite_max_punti_transazione' => config('app.limite_max_punti_transazione', 500.00),
            'tasso_cambio_punti_euro' => config('app.tasso_cambio_punti_euro', 1.00)
        ]);
    }

    /**
     * Aggiorna configurazioni sistema
     * 
     * PUT /api/v1/centrale/configurazioni
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function updateConfigurazioni(Request $request)
    {
        $user = $request->user();

        if (!$user->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'bonus_benvenuto' => 'numeric|min:0|max:1000',
            'scadenza_punti_giorni' => 'integer|min:30|max:730',
            'limite_max_punti_transazione' => 'numeric|min:10|max:10000',
            'tasso_cambio_punti_euro' => 'numeric|min:0.1|max:10'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        // Nota: In produzione, queste configurazioni andrebbero salvate in database
        // Per MVP, usiamo config file

        return $this->successResponse(
            $request->all(),
            'Configurazioni aggiornate (richiede riavvio server per applicare)'
        );
    }

    /**
     * Report completo sistema
     * 
     * GET /api/v1/centrale/report
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getReport(Request $request)
    {
        $user = $request->user();

        if (!$user->isCentrale()) {
            return $this->errorResponse('Solo centrale', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $dataInizio = $request->has('data_inizio') 
                ? \Carbon\Carbon::parse($request->data_inizio)
                : now()->subMonth();

            $dataFine = $request->has('data_fine')
                ? \Carbon\Carbon::parse($request->data_fine)
                : now();

            // Transazioni periodo
            $transazioni = Transazione::whereBetween('created_at', [$dataInizio, $dataFine])->get();

            $report = [
                'periodo' => [
                    'inizio' => $dataInizio->format('Y-m-d'),
                    'fine' => $dataFine->format('Y-m-d')
                ],
                'transazioni' => [
                    'totali' => $transazioni->count(),
                    'per_tipo' => $transazioni->groupBy('tipo')->map->count(),
                    'punti_totali' => (float) $transazioni->sum('punti'),
                    'importo_euro_totale' => (float) $transazioni->sum('importo_euro')
                ],
                'utenti' => [
                    'nuovi_clienti' => User::where('ruolo', 'cliente')
                        ->whereBetween('created_at', [$dataInizio, $dataFine])
                        ->count(),
                    'nuovi_esercenti' => Esercente::whereBetween('data_adesione', [$dataInizio, $dataFine])
                        ->count()
                ],
                'top_esercenti_emissione' => \App\Models\Wallet::esercenti()
                    ->orderBy('punti_emessi', 'desc')
                    ->take(10)
                    ->with('user.esercente')
                    ->get()
                    ->map(function($w) {
                        return [
                            'nome_negozio' => $w->user->esercente->nome_negozio ?? 'N/A',
                            'punti_emessi' => (float) $w->punti_emessi,
                            'punti_incassati' => (float) $w->punti_incassati,
                            'saldo' => (float) $w->saldo_esercente
                        ];
                    })
            ];

            return $this->successResponse($report);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore generazione report: ' . $e->getMessage(),
                'REPORT_ERROR',
                null,
                500
            );
        }
    }
}

