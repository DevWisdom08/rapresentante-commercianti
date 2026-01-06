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
        Schema::create('wallets', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->onDelete('cascade');
            $table->decimal('saldo_punti', 10, 2)->default(0.00);
            $table->decimal('punti_emessi', 10, 2)->default(0.00);
            $table->decimal('punti_incassati', 10, 2)->default(0.00);
            $table->timestamp('ultimo_aggiornamento')->nullable();
            $table->timestamps();

            // Indici
            $table->index('user_id');
            $table->index('saldo_punti');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('wallets');
    }
};

