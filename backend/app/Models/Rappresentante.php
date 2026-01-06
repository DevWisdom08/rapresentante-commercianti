<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model Rappresentante - Coordinatore di zona
 */
class Rappresentante extends Model
{
    use HasFactory;

    /**
     * Nome tabella database
     */
    protected $table = 'rappresentanti';

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'nome_zona',
        'provincia',
        'comuni_coperti',
        'num_esercenti',
        'num_clienti',
        'data_nomina',
        'note'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'comuni_coperti' => 'array',
        'num_esercenti' => 'integer',
        'num_clienti' => 'integer',
        'data_nomina' => 'date'
    ];

    /**
     * Relazione: Utente associato
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relazione: Esercenti della zona
     */
    public function esercenti()
    {
        return $this->hasMany(Esercente::class, 'rappresentante_id');
    }

    /**
     * Relazione: Eventi creati
     */
    public function eventi()
    {
        return $this->hasMany(Evento::class, 'rappresentante_id');
    }

    /**
     * Aggiorna conteggio esercenti
     */
    public function aggiornaNumeroEsercenti(): void
    {
        $this->update([
            'num_esercenti' => $this->esercenti()->attivi()->count()
        ]);
    }

    /**
     * Accessor: Nome zona completo
     */
    public function getNomeZonaCompletoAttribute(): string
    {
        return "{$this->nome_zona} ({$this->provincia})";
    }
}

