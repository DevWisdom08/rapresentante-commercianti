<?php

return [
    'name' => env('APP_NAME', 'Laravel'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
    'asset_url' => env('ASSET_URL'),
    'timezone' => 'Europe/Rome',
    'locale' => 'it',
    'fallback_locale' => 'en',
    'faker_locale' => 'it_IT',
    'key' => env('APP_KEY'),
    'cipher' => 'AES-256-CBC',

    // Configurazioni custom sistema punti
    'bonus_benvenuto' => (float) env('BONUS_BENVENUTO', 10.00),
    'scadenza_punti_giorni' => (int) env('SCADENZA_PUNTI_GIORNI', 180),
    'limite_max_punti_transazione' => (float) env('LIMITE_MAX_PUNTI_TRANSAZIONE', 500.00),
    'tasso_cambio_punti_euro' => (float) env('TASSO_CAMBIO_PUNTI_EURO', 1.00),
    'euro_per_punto' => (float) env('EURO_PER_PUNTO', 10.00), // Quanti euro spesi per 1 punto
    'dominio_email_cliente' => env('DOMINIO_EMAIL_CLIENTE', '@sottocasa.it'),
    'dominio_email_esercente' => env('DOMINIO_EMAIL_ESERCENTE', '@esercenti.sottocasa.it'),

    'providers' => [
        Illuminate\Auth\AuthServiceProvider::class,
        Illuminate\Broadcasting\BroadcastServiceProvider::class,
        Illuminate\Bus\BusServiceProvider::class,
        Illuminate\Cache\CacheServiceProvider::class,
        Illuminate\Foundation\Providers\ConsoleSupportServiceProvider::class,
        Illuminate\Cookie\CookieServiceProvider::class,
        Illuminate\Database\DatabaseServiceProvider::class,
        Illuminate\Encryption\EncryptionServiceProvider::class,
        Illuminate\Filesystem\FilesystemServiceProvider::class,
        Illuminate\Foundation\Providers\FoundationServiceProvider::class,
        Illuminate\Hashing\HashServiceProvider::class,
        Illuminate\Mail\MailServiceProvider::class,
        Illuminate\Notifications\NotificationServiceProvider::class,
        Illuminate\Pagination\PaginationServiceProvider::class,
        Illuminate\Pipeline\PipelineServiceProvider::class,
        Illuminate\Queue\QueueServiceProvider::class,
        Illuminate\Redis\RedisServiceProvider::class,
        Illuminate\Auth\Passwords\PasswordResetServiceProvider::class,
        Illuminate\Session\SessionServiceProvider::class,
        Illuminate\Translation\TranslationServiceProvider::class,
        Illuminate\Validation\ValidationServiceProvider::class,
        Illuminate\View\ViewServiceProvider::class,
        
        App\Providers\RouteServiceProvider::class,
    ],

    'aliases' => [],
];

