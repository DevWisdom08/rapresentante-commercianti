<?php

namespace App\Http\Controllers;

use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Foundation\Validation\ValidatesRequests;
use Illuminate\Routing\Controller as BaseController;

/**
 * Controller base per tutti i controller dell'applicazione
 */
class Controller extends BaseController
{
    use AuthorizesRequests, ValidatesRequests;

    /**
     * Risposta JSON di successo standardizzata
     *
     * @param mixed $data Dati da restituire
     * @param string $message Messaggio di successo
     * @param int $statusCode Codice HTTP (default 200)
     * @return \Illuminate\Http\JsonResponse
     */
    protected function successResponse($data = null, string $message = 'Operazione completata con successo', int $statusCode = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data
        ], $statusCode);
    }

    /**
     * Risposta JSON di errore standardizzata
     *
     * @param string $message Messaggio di errore
     * @param string $errorCode Codice errore specifico
     * @param mixed $data Dati aggiuntivi (opzionale)
     * @param int $statusCode Codice HTTP (default 400)
     * @return \Illuminate\Http\JsonResponse
     */
    protected function errorResponse(string $message, string $errorCode = 'ERROR', $data = null, int $statusCode = 400)
    {
        $response = [
            'success' => false,
            'message' => $message,
            'error' => $errorCode
        ];

        if ($data !== null) {
            $response['data'] = $data;
        }

        return response()->json($response, $statusCode);
    }

    /**
     * Risposta di validazione fallita
     *
     * @param \Illuminate\Contracts\Validation\Validator $validator
     * @return \Illuminate\Http\JsonResponse
     */
    protected function validationErrorResponse($validator)
    {
        return response()->json([
            'success' => false,
            'message' => 'Dati non validi',
            'error' => 'VALIDATION_ERROR',
            'data' => [
                'errors' => $validator->errors()
            ]
        ], 422);
    }
}

