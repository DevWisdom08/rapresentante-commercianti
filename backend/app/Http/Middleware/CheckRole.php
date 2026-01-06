<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Middleware per verificare ruolo utente
 */
class CheckRole
{
    /**
     * Verifica che l'utente abbia uno dei ruoli specificati
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     * @param  string  ...$ruoli Lista ruoli ammessi
     */
    public function handle(Request $request, Closure $next, string ...$ruoli): Response
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Non autenticato',
                'error' => 'UNAUTHENTICATED'
            ], 401);
        }

        // Verifica se utente ha uno dei ruoli richiesti
        if (!in_array($user->ruolo, $ruoli)) {
            return response()->json([
                'success' => false,
                'message' => 'Non hai i permessi per questa azione',
                'error' => 'FORBIDDEN',
                'data' => [
                    'ruolo_richiesto' => $ruoli,
                    'ruolo_utente' => $user->ruolo
                ]
            ], 403);
        }

        return $next($request);
    }
}

