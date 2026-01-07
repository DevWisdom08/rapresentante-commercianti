<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use App\Models\User;

/**
 * Middleware autenticazione semplice per MVP (senza JWT)
 */
class SimpleAuth
{
    public function handle(Request $request, Closure $next)
    {
        $token = $request->bearerToken();
        
        if (!$token) {
            return response()->json([
                'message' => 'Token non fornito'
            ], 401);
        }

        try {
            // Decodifica token: "userId|email|timestamp"
            $decoded = base64_decode($token);
            $parts = explode('|', $decoded);
            
            if (count($parts) !== 3) {
                throw new \Exception('Token invalido');
            }
            
            $userId = $parts[0];
            $user = User::find($userId);
            
            if (!$user || !$user->attivo) {
                throw new \Exception('Utente non trovato');
            }
            
            // Imposta utente autenticato
            $request->setUserResolver(function () use ($user) {
                return $user;
            });
            
            return $next($request);
            
        } catch (\Exception $e) {
            return response()->json([
                'message' => 'Token non valido'
            ], 401);
        }
    }
}

