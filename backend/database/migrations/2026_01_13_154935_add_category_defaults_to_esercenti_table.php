<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('esercenti', function (Blueprint $table) {
            // Sconti default per categoria (JSON)
            $table->json('sconti_default_categorie')->nullable()->after('descrizione');
            
            // Promozione primi clienti
            $table->boolean('promo_primi_clienti_attiva')->default(false)->after('sconti_default_categorie');
            $table->integer('promo_primi_clienti_percentuale')->default(0)->after('promo_primi_clienti_attiva');
        });
    }

    public function down(): void
    {
        Schema::table('esercenti', function (Blueprint $table) {
            $table->dropColumn(['sconti_default_categorie', 'promo_primi_clienti_attiva', 'promo_primi_clienti_percentuale']);
        });
    }
};
