<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return response()->json([
        'message' => 'Rapresentante Commercianti API',
        'version' => '1.0.0',
        'docs' => '/api/health'
    ]);
});

