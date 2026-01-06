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
        Schema::create('rappresentanti', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->onDelete('cascade');
            $table->string('nome_zona');
            $table->string('provincia', 2);
            $table->json('comuni_coperti')->nullable();
            $table->integer('num_esercenti')->default(0);
            $table->integer('num_clienti')->default(0);
            $table->date('data_nomina');
            $table->text('note')->nullable();
            $table->timestamps();

            // Indici
            $table->index('user_id');
            $table->index('provincia');
        });
    }

    /**
     * Rollback migrations
     */
    public function down(): void
    {
        Schema::dropIfExists('rappresentanti');
    }
};

