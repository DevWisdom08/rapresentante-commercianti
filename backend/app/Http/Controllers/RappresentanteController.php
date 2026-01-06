<?php

namespace App\Http\Controllers;

use App\Models\Rappresentante;
use App\Models\Esercente;
use App\Models\Evento;
use App\Models\Transazione;
use App\Services\WalletService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

/**
 * Controller per funzionalità Rappresentanti
 */
class RappresentanteController extends Controller
{
    protected $walletService;

    public function __construct(WalletService $walletService)
    {
        $this->walletService = $walletService;
    }

    /**
     * Dashboard rappresentante con KPI zona
     * 
     * GET /api/v1/rappresentante/dashboard
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function dashboard(Request $request)
    {
        $user = $request->user();

        if (!$user->isRappresentante()) {
            return $this->errorResponse('Solo rappresentanti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $rappresentante = $user->rappresentante;

            if (!$rappresentante) {
                return $this->errorResponse('Dati rappresentante non trovati', 'DATA_NOT_FOUND', null, 404);
            }

            // KPI Zona
            $esercentiZona = Esercente::where('rappresentante_id', $rappresentante->id)
                ->attivi()
                ->with('user.wallet')
                ->get();

            $numEsercenti = $esercentiZona->count();

            // Clienti unici che hanno interagito con esercenti della zona
            $numClienti = Transazione::whereIn('mittente_id', $esercentiZona->pluck('user_id'))
                ->where('tipo', 'assegnazione')
                ->distinct('destinatario_id')
                ->count();

            // Punti totali in circolazione
            $puntiTotaliCircolazione = $esercentiZona->sum(function($e) {
                return $e->user->wallet ? $e->user->wallet->punti_emessi : 0;
            });

            // Ultimo mese
            $dataInizio = now()->subMonth();
            
            $puntiEmessiMese = Transazione::whereIn('mittente_id', $esercentiZona->pluck('user_id'))
                ->where('tipo', 'assegnazione')
                ->where('created_at', '>=', $dataInizio)
                ->sum('punti');

            $puntiSpesiMese = Transazione::whereIn('destinatario_id', $esercentiZona->pluck('user_id'))
                ->where('tipo', 'pagamento')
                ->where('created_at', '>=', $dataInizio)
                ->sum('punti');

            $tassoCircolazione = $puntiEmessiMese > 0 
                ? ($puntiSpesiMese / $puntiEmessiMese) * 100 
                : 0;

            $nuoviClientiMese = Transazione::whereIn('mittente_id', $esercentiZona->pluck('user_id'))
                ->where('tipo', 'assegnazione')
                ->where('created_at', '>=', $dataInizio)
                ->distinct('destinatario_id')
                ->count();

            // Top esercenti
            $topEsercenti = $esercentiZona->map(function($e) {
                $wallet = $e->user->wallet;
                $clientiUnici = Transazione::where('mittente_id', $e->user_id)
                    ->where('tipo', 'assegnazione')
                    ->distinct('destinatario_id')
                    ->count();

                return [
                    'id' => $e->id,
                    'nome_negozio' => $e->nome_negozio,
                    'categoria' => $e->categoria_formattata,
                    'punti_emessi' => $wallet ? (float) $wallet->punti_emessi : 0,
                    'punti_incassati' => $wallet ? (float) $wallet->punti_incassati : 0,
                    'saldo' => $wallet ? (float) $wallet->saldo_esercente : 0,
                    'clienti_unici' => $clientiUnici
                ];
            })->sortByDesc('punti_incassati')->take(10)->values();

            // Eventi attivi
            $eventiAttivi = Evento::where('rappresentante_id', $rappresentante->id)
                ->attivi()
                ->get()
                ->map(function($e) {
                    return [
                        'id' => $e->id,
                        'titolo' => $e->titolo,
                        'data_inizio' => $e->data_inizio,
                        'data_fine' => $e->data_fine,
                        'bonus_punti' => (float) $e->bonus_punti,
                        'partecipanti' => $e->num_partecipanti,
                        'posti_disponibili' => $e->posti_disponibili
                    ];
                });

            return $this->successResponse([
                'zona' => [
                    'nome' => $rappresentante->nome_zona,
                    'provincia' => $rappresentante->provincia,
                    'num_esercenti' => $numEsercenti,
                    'num_clienti' => $numClienti
                ],
                'kpi' => [
                    'punti_totali_circolazione' => (float) $puntiTotaliCircolazione,
                    'punti_emessi_mese' => (float) $puntiEmessiMese,
                    'punti_spesi_mese' => (float) $puntiSpesiMese,
                    'tasso_circolazione' => round($tassoCircolazione, 1),
                    'nuovi_clienti_mese' => $nuoviClientiMese
                ],
                'top_esercenti' => $topEsercenti,
                'eventi_attivi' => $eventiAttivi
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
     * Lista esercenti della zona
     * 
     * GET /api/v1/rappresentante/esercenti
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getEsercenti(Request $request)
    {
        $user = $request->user();

        if (!$user->isRappresentante()) {
            return $this->errorResponse('Solo rappresentanti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $rappresentante = $user->rappresentante;

            $esercenti = Esercente::where('rappresentante_id', $rappresentante->id)
                ->with('user.wallet')
                ->get()
                ->map(function($e) {
                    $wallet = $e->user->wallet;
                    
                    $transazioniTotali = Transazione::where(function($q) use ($e) {
                        $q->where('mittente_id', $e->user_id)
                          ->orWhere('destinatario_id', $e->user_id);
                    })->count();

                    $clientiUnici = Transazione::where('mittente_id', $e->user_id)
                        ->where('tipo', 'assegnazione')
                        ->distinct('destinatario_id')
                        ->count();

                    return [
                        'id' => $e->id,
                        'user_id' => $e->user_id,
                        'nome_negozio' => $e->nome_negozio,
                        'categoria' => $e->categoria_formattata,
                        'indirizzo' => $e->indirizzo_completo,
                        'telefono' => $e->telefono_negozio,
                        'attivo' => $e->attivo,
                        'data_adesione' => $e->data_adesione,
                        'wallet' => [
                            'punti_emessi' => $wallet ? (float) $wallet->punti_emessi : 0,
                            'punti_incassati' => $wallet ? (float) $wallet->punti_incassati : 0,
                            'saldo' => $wallet ? (float) $wallet->saldo_esercente : 0
                        ],
                        'statistiche' => [
                            'clienti_unici' => $clientiUnici,
                            'transazioni_totali' => $transazioniTotali
                        ]
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
     * Crea nuovo evento
     * 
     * POST /api/v1/rappresentante/eventi
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function creaEvento(Request $request)
    {
        $user = $request->user();

        if (!$user->isRappresentante()) {
            return $this->errorResponse('Solo rappresentanti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $validator = Validator::make($request->all(), [
            'titolo' => 'required|string|max:255',
            'descrizione' => 'nullable|string',
            'data_inizio' => 'required|date|after:now',
            'data_fine' => 'required|date|after:data_inizio',
            'bonus_punti' => 'required|numeric|min:1|max:1000',
            'max_partecipanti' => 'nullable|integer|min:1',
            'luogo' => 'nullable|string|max:255',
            'immagine_url' => 'nullable|url'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        try {
            $rappresentante = $user->rappresentante;

            // Genera codice evento unico
            $codiceEvento = strtoupper(Str::random(8));
            while (Evento::where('codice_evento', $codiceEvento)->exists()) {
                $codiceEvento = strtoupper(Str::random(8));
            }

            $evento = Evento::create([
                'rappresentante_id' => $rappresentante->id,
                'titolo' => $request->titolo,
                'descrizione' => $request->descrizione,
                'data_inizio' => $request->data_inizio,
                'data_fine' => $request->data_fine,
                'bonus_punti' => $request->bonus_punti,
                'codice_evento' => $codiceEvento,
                'max_partecipanti' => $request->max_partecipanti,
                'luogo' => $request->luogo,
                'immagine_url' => $request->immagine_url,
                'attivo' => true
            ]);

            return $this->successResponse([
                'id' => $evento->id,
                'titolo' => $evento->titolo,
                'codice_evento' => $evento->codice_evento,
                'bonus_punti' => (float) $evento->bonus_punti,
                'data_inizio' => $evento->data_inizio,
                'data_fine' => $evento->data_fine
            ], 'Evento creato con successo', 201);

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore creazione evento: ' . $e->getMessage(),
                'CREATE_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Lista eventi
     * 
     * GET /api/v1/rappresentante/eventi
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function getEventi(Request $request)
    {
        $user = $request->user();

        if (!$user->isRappresentante()) {
            return $this->errorResponse('Solo rappresentanti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        try {
            $rappresentante = $user->rappresentante;

            $eventi = Evento::where('rappresentante_id', $rappresentante->id)
                ->orderBy('data_inizio', 'desc')
                ->get()
                ->map(function($e) {
                    return [
                        'id' => $e->id,
                        'titolo' => $e->titolo,
                        'descrizione' => $e->descrizione,
                        'data_inizio' => $e->data_inizio,
                        'data_fine' => $e->data_fine,
                        'bonus_punti' => (float) $e->bonus_punti,
                        'codice_evento' => $e->codice_evento,
                        'num_partecipanti' => $e->num_partecipanti,
                        'max_partecipanti' => $e->max_partecipanti,
                        'posti_disponibili' => $e->posti_disponibili,
                        'luogo' => $e->luogo,
                        'attivo' => $e->attivo,
                        'is_in_corso' => $e->isInCorso(),
                        'is_completo' => $e->isCompleto()
                    ];
                });

            return $this->successResponse($eventi->toArray());

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore caricamento eventi: ' . $e->getMessage(),
                'FETCH_ERROR',
                null,
                500
            );
        }
    }

    /**
     * Export report CSV
     * 
     * GET /api/v1/rappresentante/report/export?periodo=ultimo_mese&tipo=completo
     * 
     * @param Request $request
     * @return \Illuminate\Http\Response
     */
    public function exportReport(Request $request)
    {
        $user = $request->user();

        if (!$user->isRappresentante()) {
            return $this->errorResponse('Solo rappresentanti', 'ROLE_NOT_ALLOWED', null, 403);
        }

        $periodo = $request->get('periodo', 'ultimo_mese');
        $tipo = $request->get('tipo', 'completo');

        // Determina range date
        $dataInizio = match($periodo) {
            'ultima_settimana' => now()->subWeek(),
            'ultimo_mese' => now()->subMonth(),
            'ultimo_trimestre' => now()->subMonths(3),
            default => now()->subMonth()
        };

        try {
            $rappresentante = $user->rappresentante;
            $esercentiIds = Esercente::where('rappresentante_id', $rappresentante->id)
                ->pluck('user_id');

            // Query transazioni
            $transazioni = Transazione::where(function($q) use ($esercentiIds) {
                    $q->whereIn('mittente_id', $esercentiIds)
                      ->orWhereIn('destinatario_id', $esercentiIds);
                })
                ->where('created_at', '>=', $dataInizio)
                ->with(['mittente', 'destinatario'])
                ->get();

            // Genera CSV
            $csv = "Data,Tipo,Mittente,Destinatario,Punti,Importo Euro\n";
            
            foreach ($transazioni as $t) {
                $csv .= sprintf(
                    "%s,%s,%s,%s,%.2f,%.2f\n",
                    $t->created_at->format('Y-m-d H:i:s'),
                    $t->tipo,
                    $t->mittente ? $t->mittente->nome : 'Sistema',
                    $t->destinatario->nome,
                    $t->punti,
                    $t->importo_euro ?? 0
                );
            }

            $filename = "report_{$rappresentante->nome_zona}_" . now()->format('Y_m') . ".csv";

            return response($csv, 200)
                ->header('Content-Type', 'text/csv')
                ->header('Content-Disposition', "attachment; filename=\"{$filename}\"");

        } catch (\Exception $e) {
            return $this->errorResponse(
                'Errore export report: ' . $e->getMessage(),
                'EXPORT_ERROR',
                null,
                500
            );
        }
    }
}

