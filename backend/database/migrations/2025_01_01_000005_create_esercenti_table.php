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
        Schema::create('esercenti', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->onDelete('cascade');
            $table->foreignId('rappresentante_id')->nullable()
                  ->constrained('rappresentanti')->onDelete('set null');
            $table->string('nome_negozio');
            $table->string('partita_iva', 20)->unique()->nullable();
            $table->string('indirizzo');
            $table->string('citta', 100);
            $table->string('cap', 10);
            $table->string('provincia', 2);
            $table->string('telefono_negozio', 20)->nullable();
            $table->enum('categoria', [
                'alimentari',
                'abbigliamento',
                'bar_ristoranti',
                'servizi',
                'salute_benessere',
                'casa_arredamento',
                'elettronica',
                'altro'
            ]);
            $table->text('descrizione')->nullable();
            $table->json('orari_apertura')->nullable();
            $table->string('logo_url', 500)->nullable();
            $table->json('foto_negozio')->nullable();
            $table->boolean('attivo')->default(true);
            $table->date('data_adesione');
            $table->timestamps();

            // Indici
            $table->index('user_id');
            $table->index('rappresentante_id');
            $table->index('citta');
            $table->index('categoria');
            $table->index('attivo');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('esercenti');
    }
};

