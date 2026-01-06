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
        Schema::create('eventi', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rappresentante_id')
                  ->constrained('rappresentanti')->onDelete('cascade');
            $table->string('titolo');
            $table->text('descrizione')->nullable();
            $table->dateTime('data_inizio');
            $table->dateTime('data_fine');
            $table->decimal('bonus_punti', 10, 2)->default(0.00);
            $table->string('codice_evento', 20)->unique();
            $table->integer('max_partecipanti')->nullable();
            $table->integer('num_partecipanti')->default(0);
            $table->string('immagine_url', 500)->nullable();
            $table->string('luogo')->nullable();
            $table->boolean('attivo')->default(true);
            $table->timestamps();

            // Indici
            $table->index('rappresentante_id');
            $table->index('data_inizio');
            $table->index('codice_evento');
            $table->index('attivo');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('eventi');
    }
};

