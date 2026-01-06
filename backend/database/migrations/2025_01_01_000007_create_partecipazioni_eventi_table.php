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
        Schema::create('partecipazioni_eventi', function (Blueprint $table) {
            $table->id();
            $table->foreignId('evento_id')->constrained('eventi')->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->decimal('punti_ricevuti', 10, 2);
            $table->timestamp('data_partecipazione')->useCurrent();

            // Vincolo: un utente può partecipare a un evento una sola volta
            $table->unique(['evento_id', 'user_id']);

            // Indici
            $table->index('evento_id');
            $table->index('user_id');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('partecipazioni_eventi');
    }
};

