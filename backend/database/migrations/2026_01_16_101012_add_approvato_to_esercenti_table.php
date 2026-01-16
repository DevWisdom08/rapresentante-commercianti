<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('esercenti', function (Blueprint $table) {
            $table->boolean('approvato')->default(false)->after('attivo');
            $table->timestamp('data_approvazione')->nullable()->after('approvato');
        });
    }

    public function down(): void
    {
        Schema::table('esercenti', function (Blueprint $table) {
            $table->dropColumn(['approvato', 'data_approvazione']);
        });
    }
};
