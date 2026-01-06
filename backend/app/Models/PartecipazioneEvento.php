<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model PartecipazioneEvento - Traccia partecipazione clienti agli eventi
 */
class PartecipazioneEvento extends Model
{
    use HasFactory;

    /**
     * Nome tabella database
     */
    protected $table = 'partecipazioni_eventi';

    /**
     * Disabilita updated_at
     */
    const UPDATED_AT = null;

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'evento_id',
        'user_id',
        'punti_ricevuti',
        'data_partecipazione'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'punti_ricevuti' => 'decimal:2',
        'data_partecipazione' => 'datetime'
    ];

    /**
     * Relazione: Evento
     */
    public function evento()
    {
        return $this->belongsTo(Evento::class, 'evento_id');
    }

    /**
     * Relazione: Utente partecipante
     */
    public function user()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Boot model - Imposta data partecipazione automatica
     */
    protected static function boot()
    {
        parent::boot();

        static::creating(function ($partecipazione) {
            if (!$partecipazione->data_partecipazione) {
                $partecipazione->data_partecipazione = now();
            }
        });
    }
}

