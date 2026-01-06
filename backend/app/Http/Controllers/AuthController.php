<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Wallet;
use App\Models\Transazione;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Tymon\JWTAuth\Facades\JWTAuth;

/**
 * Controller per gestione autenticazione e registrazione utenti
 */
class AuthController extends Controller
{
    /**
     * Registrazione nuovo utente
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function registrazione(Request $request)
    {
        // Validazione input
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:8|confirmed',
            'nome' => 'required|string|max:100',
            'cognome' => 'required|string|max:100',
            'telefono' => 'nullable|string|max:20',
            'ruolo' => 'required|in:cliente,esercente,rappresentante,centrale'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        // Genera codice OTP per verifica email
        $otpCode = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $otpExpires = now()->addMinutes(15);

        // Crea utente
        $user = User::create([
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'nome' => $request->nome,
            'cognome' => $request->cognome,
            'telefono' => $request->telefono,
            'ruolo' => $request->ruolo,
            'otp_code' => $otpCode,
            'otp_expires_at' => $otpExpires,
            'attivo' => true
        ]);

        // Crea wallet per cliente ed esercente
        if (in_array($user->ruolo, ['cliente', 'esercente'])) {
            $wallet = Wallet::create([
                'user_id' => $user->id,
                'saldo_punti' => 0.00,
                'punti_emessi' => 0.00,
                'punti_incassati' => 0.00
            ]);

            // Bonus benvenuto per clienti
            if ($user->ruolo === 'cliente') {
                $bonusBenvenuto = config('app.bonus_benvenuto', 10.00);
                
                $wallet->update([
                    'saldo_punti' => $bonusBenvenuto
                ]);

                // Log transazione bonus
                Transazione::create([
                    'mittente_id' => null,
                    'destinatario_id' => $user->id,
                    'punti' => $bonusBenvenuto,
                    'tipo' => 'bonus_benvenuto',
                    'descrizione' => 'Bonus di benvenuto',
                    'ip_address' => $request->ip(),
                    'user_agent' => $request->userAgent()
                ]);
            }
        }

        // Invia email OTP (in produzione)
        // In sviluppo, loggiamo il codice
        \Log::info("OTP per {$user->email}: {$otpCode}");

        return $this->successResponse([
            'user_id' => $user->id,
            'email' => $user->email,
            'otp_inviato' => true,
            'otp_code' => config('app.debug') ? $otpCode : null // Solo in debug
        ], 'Registrazione completata. Controlla la tua email per il codice OTP.', 201);
    }

    /**
     * Verifica codice OTP e attiva account
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function verificaOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'otp_code' => 'required|string|size:6'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return $this->errorResponse('Utente non trovato', 'USER_NOT_FOUND', null, 404);
        }

        // Verifica OTP
        if ($user->otp_code !== $request->otp_code) {
            return $this->errorResponse('Codice OTP non valido', 'INVALID_OTP', null, 400);
        }

        // Verifica scadenza
        if (now()->gt($user->otp_expires_at)) {
            return $this->errorResponse('Codice OTP scaduto', 'OTP_EXPIRED', null, 400);
        }

        // Attiva account
        $user->update([
            'email_verified_at' => now(),
            'otp_code' => null,
            'otp_expires_at' => null
        ]);

        // Genera token JWT
        $token = JWTAuth::fromUser($user);

        // Carica wallet se esiste
        $userData = $user->toArray();
        if ($user->wallet) {
            $userData['wallet'] = $user->wallet;
        }

        return $this->successResponse([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'expires_in' => config('jwt.ttl') * 60,
            'user' => $userData
        ], 'Email verificata con successo');
    }

    /**
     * Login utente
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return $this->errorResponse('Credenziali non valide', 'INVALID_CREDENTIALS', null, 401);
        }

        if (!$user->email_verified_at) {
            return $this->errorResponse('Email non verificata', 'EMAIL_NOT_VERIFIED', [
                'user_id' => $user->id
            ], 403);
        }

        if (!$user->attivo) {
            return $this->errorResponse('Account disattivato', 'ACCOUNT_DISABLED', null, 403);
        }

        // Aggiorna ultimo accesso
        $user->update(['ultimo_accesso' => now()]);

        // Genera token
        $token = JWTAuth::fromUser($user);

        return $this->successResponse([
            'access_token' => $token,
            'token_type' => 'Bearer',
            'expires_in' => config('jwt.ttl') * 60,
            'user' => [
                'id' => $user->id,
                'email' => $user->email,
                'nome' => $user->nome,
                'cognome' => $user->cognome,
                'ruolo' => $user->ruolo
            ]
        ], 'Login effettuato con successo');
    }

    /**
     * Logout utente
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function logout(Request $request)
    {
        try {
            JWTAuth::invalidate(JWTAuth::getToken());
            return $this->successResponse(null, 'Logout effettuato con successo');
        } catch (\Exception $e) {
            return $this->errorResponse('Errore durante il logout', 'LOGOUT_ERROR', null, 500);
        }
    }

    /**
     * Ottieni profilo utente autenticato
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function profilo(Request $request)
    {
        $user = $request->user();
        
        return $this->successResponse([
            'id' => $user->id,
            'email' => $user->email,
            'nome' => $user->nome,
            'cognome' => $user->cognome,
            'telefono' => $user->telefono,
            'ruolo' => $user->ruolo,
            'email_verificata' => $user->email_verified_at !== null,
            'attivo' => $user->attivo,
            'created_at' => $user->created_at
        ]);
    }

    /**
     * Reinvia codice OTP
     * 
     * @param Request $request
     * @return \Illuminate\Http\JsonResponse
     */
    public function reinviaOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email'
        ]);

        if ($validator->fails()) {
            return $this->validationErrorResponse($validator);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return $this->errorResponse('Utente non trovato', 'USER_NOT_FOUND', null, 404);
        }

        if ($user->email_verified_at) {
            return $this->errorResponse('Email già verificata', 'EMAIL_ALREADY_VERIFIED', null, 400);
        }

        // Genera nuovo OTP
        $otpCode = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $otpExpires = now()->addMinutes(15);

        $user->update([
            'otp_code' => $otpCode,
            'otp_expires_at' => $otpExpires
        ]);

        \Log::info("Nuovo OTP per {$user->email}: {$otpCode}");

        return $this->successResponse([
            'otp_code' => config('app.debug') ? $otpCode : null
        ], 'Nuovo codice OTP inviato');
    }
}

