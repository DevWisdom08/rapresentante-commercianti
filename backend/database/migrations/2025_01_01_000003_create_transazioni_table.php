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
        Schema::create('transazioni', function (Blueprint $table) {
            $table->id();
            $table->foreignId('mittente_id')->nullable()
                  ->constrained('users')->onDelete('set null');
            $table->foreignId('destinatario_id')
                  ->constrained('users')->onDelete('cascade');
            $table->decimal('punti', 10, 2);
            $table->decimal('importo_euro', 10, 2)->nullable();
            $table->enum('tipo', [
                'assegnazione',
                'pagamento',
                'bonus_benvenuto',
                'bonus_evento',
                'rimborso',
                'scadenza'
            ]);
            $table->foreignId('esercente_origine_id')->nullable()
                  ->constrained('users')->onDelete('set null');
            $table->text('descrizione')->nullable();
            $table->json('metadata')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->text('user_agent')->nullable();
            $table->timestamp('created_at')->useCurrent();

            // Indici per performance
            $table->index('mittente_id');
            $table->index('destinatario_id');
            $table->index('tipo');
            $table->index('created_at');
            $table->index('esercente_origine_id');
            
            // Indice composito per query comuni
            $table->index(['destinatario_id', 'tipo', 'created_at']);
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('transazioni');
    }
};

