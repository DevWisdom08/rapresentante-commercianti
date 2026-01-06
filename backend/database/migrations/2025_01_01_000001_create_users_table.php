<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Esegui migrations
     */
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id();
            $table->string('email')->unique();
            $table->string('password');
            $table->string('nome', 100);
            $table->string('cognome', 100);
            $table->string('telefono', 20)->nullable();
            $table->enum('ruolo', ['cliente', 'esercente', 'rappresentante', 'centrale'])
                  ->default('cliente');
            $table->timestamp('email_verified_at')->nullable();
            $table->string('otp_code', 6)->nullable();
            $table->timestamp('otp_expires_at')->nullable();
            $table->boolean('attivo')->default(true);
            $table->timestamp('ultimo_accesso')->nullable();
            $table->rememberToken();
            $table->timestamps();

            // Indici per performance
            $table->index('email');
            $table->index('ruolo');
            $table->index('attivo');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};

