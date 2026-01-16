<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\WalletController;
use App\Http\Controllers\EsercenteController;
use App\Http\Controllers\RappresentanteController;
use App\Http\Controllers\CentraleController;
use App\Http\Controllers\TransazioneController;

/*
|--------------------------------------------------------------------------
| API Routes - RAPRESENTANTE COMMERCIANTI
|--------------------------------------------------------------------------
|
| Tutte le routes API per il sistema fedeltà circolare.
| Versione: v1
|
*/

// Health check endpoint (pubblico)
Route::get('/health', function () {
    return response()->json([
        'status' => 'OK',
        'service' => 'Rapresentante Commercianti API',
        'version' => '1.0.0',
        'timestamp' => now()->toIso8601String()
    ]);
});

// API v1
Route::prefix('v1')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | AUTENTICAZIONE (Pubbliche)
    |--------------------------------------------------------------------------
    */
    Route::prefix('auth')->group(function () {
        Route::post('/registrazione', [AuthController::class, 'registrazione']);
        Route::post('/check-username', [AuthController::class, 'checkUsername']);
        Route::post('/verifica-otp', [AuthController::class, 'verificaOtp']);
        Route::post('/login', [AuthController::class, 'login']);
        Route::post('/reinvia-otp', [AuthController::class, 'reinviaOtp']);
        
        // Routes autenticate
        Route::middleware('auth.simple')->group(function () {
            Route::post('/logout', [AuthController::class, 'logout']);
            Route::get('/profilo', [AuthController::class, 'profilo']);
        });
    });

    /*
    |--------------------------------------------------------------------------
    | WALLET (Cliente e Esercente)
    |--------------------------------------------------------------------------
    */
    Route::middleware('auth.simple')->prefix('wallet')->group(function () {
        Route::get('/', [WalletController::class, 'getWallet']);
        Route::get('/transazioni', [WalletController::class, 'getTransazioni']);
        Route::get('/transazioni/{id}', [WalletController::class, 'getTransazione']);
        
        // Solo esercenti
        Route::middleware('role:esercente')->group(function () {
            Route::get('/statistiche', [WalletController::class, 'getStatistiche']);
        });
    });

    /*
    |--------------------------------------------------------------------------
    | ESERCENTE
    |--------------------------------------------------------------------------
    */
    Route::middleware(['auth.simple', 'role:esercente'])->prefix('esercente')->group(function () {
        Route::post('/assegna-punti', [EsercenteController::class, 'assegnaPunti']);
        Route::post('/accetta-punti', [EsercenteController::class, 'accettaPunti']);
        Route::get('/dashboard', [EsercenteController::class, 'dashboard']);
        Route::post('/verifica-cliente', [EsercenteController::class, 'verificaCliente']);
    });

    /*
    |--------------------------------------------------------------------------
    | TRANSAZIONI UNIFICATE
    |--------------------------------------------------------------------------
    */
    Route::middleware(['auth.simple', 'role:esercente'])->prefix('transazione')->group(function () {
        Route::post('/anteprima', [TransazioneController::class, 'anteprimaTransazione']);
        Route::post('/unificata', [TransazioneController::class, 'transazioneUnificata']);
    });

    // Lista esercenti (accessibile a clienti e esercenti)
    Route::middleware(['auth.simple', 'role:cliente,esercente'])->get('/esercente/lista-zona', [EsercenteController::class, 'listaZona']);

    /*
    |--------------------------------------------------------------------------
    | RAPPRESENTANTE
    |--------------------------------------------------------------------------
    */
    Route::middleware(['auth.simple', 'role:rappresentante'])->prefix('rappresentante')->group(function () {
        Route::get('/dashboard', [RappresentanteController::class, 'dashboard']);
        Route::get('/esercenti', [RappresentanteController::class, 'getEsercenti']);
        
        // Eventi
        Route::get('/eventi', [RappresentanteController::class, 'getEventi']);
        Route::post('/eventi', [RappresentanteController::class, 'creaEvento']);
        
        // Report
        Route::get('/report/export', [RappresentanteController::class, 'exportReport']);
    });

    /*
    |--------------------------------------------------------------------------
    | EVENTI (Pubblici per clienti)
    |--------------------------------------------------------------------------
    */
    Route::middleware('auth.simple')->prefix('eventi')->group(function () {
        // Lista eventi attivi (tutti possono vedere)
        Route::get('/', function(Request $request) {
            $eventi = \App\Models\Evento::attivi()
                ->with('rappresentante.user')
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
                        'luogo' => $e->luogo,
                        'immagine_url' => $e->immagine_url,
                        'posti_disponibili' => $e->posti_disponibili,
                        'is_completo' => $e->isCompleto()
                    ];
                });
            
            return response()->json([
                'success' => true,
                'data' => $eventi
            ]);
        });

        // Partecipa evento (solo clienti)
        Route::middleware('role:cliente')->post('/{id}/partecipa', function(Request $request, int $id) {
            $user = $request->user();
            $evento = \App\Models\Evento::find($id);

            if (!$evento) {
                return response()->json([
                    'success' => false,
                    'message' => 'Evento non trovato',
                    'error' => 'EVENT_NOT_FOUND'
                ], 404);
            }

            if (!$evento->isInCorso()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Evento non attivo',
                    'error' => 'EVENT_NOT_ACTIVE'
                ], 400);
            }

            if ($evento->haPartecipato($user->id)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Hai già partecipato a questo evento',
                    'error' => 'ALREADY_PARTICIPATED'
                ], 400);
            }

            if ($evento->isCompleto()) {
                return response()->json([
                    'success' => false,
                    'message' => 'Evento al completo',
                    'error' => 'EVENT_FULL'
                ], 400);
            }

            try {
                // Registra partecipazione
                $partecipazione = $evento->registraPartecipazione($user->id);

                // Assegna bonus punti
                $walletService = new \App\Services\WalletService();
                $result = $walletService->assegnaBonusEvento($user->id, $evento->id, $evento->bonus_punti);

                return response()->json([
                    'success' => true,
                    'message' => "Partecipazione confermata! Hai ricevuto {$evento->bonus_punti} punti bonus",
                    'data' => [
                        'punti_ricevuti' => (float) $evento->bonus_punti,
                        'nuovo_saldo' => $result['nuovo_saldo'],
                        'evento' => [
                            'titolo' => $evento->titolo,
                            'data' => $evento->data_inizio->format('Y-m-d')
                        ]
                    ]
                ]);

            } catch (\Exception $e) {
                return response()->json([
                    'success' => false,
                    'message' => 'Errore partecipazione evento: ' . $e->getMessage(),
                    'error' => 'PARTICIPATION_ERROR'
                ], 500);
            }
        });
    });

    /*
    |--------------------------------------------------------------------------
    | CENTRALE (Admin)
    |--------------------------------------------------------------------------
    */
    Route::middleware(['auth.simple', 'role:centrale'])->prefix('centrale')->group(function () {
        Route::get('/dashboard', [CentraleController::class, 'dashboard']);
        Route::get('/report', [CentraleController::class, 'getReport']);
        
        // Gestione utenti
        Route::get('/utenti', [CentraleController::class, 'getUtenti']);
        Route::post('/crea-rappresentante', [CentraleController::class, 'creaRappresentante']);
        Route::post('/utenti/{id}/attiva', [CentraleController::class, 'attivaUtente']);
        Route::post('/utenti/{id}/disattiva', [CentraleController::class, 'disattivaUtente']);
        Route::delete('/utenti/{id}', [CentraleController::class, 'eliminaUtente']);
        
        // Configurazioni
        Route::get('/configurazioni', [CentraleController::class, 'getConfigurazioni']);
        Route::put('/configurazioni', [CentraleController::class, 'updateConfigurazioni']);
    });

});

/*
|--------------------------------------------------------------------------
| 404 - Route non trovata
|--------------------------------------------------------------------------
*/
Route::fallback(function () {
    return response()->json([
        'success' => false,
        'message' => 'Endpoint non trovato',
        'error' => 'NOT_FOUND'
    ], 404);
});

