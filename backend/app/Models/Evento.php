<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model Evento - Eventi territoriali con bonus punti
 */
class Evento extends Model
{
    use HasFactory;

    /**
     * Nome tabella database
     */
    protected $table = 'eventi';

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'rappresentante_id',
        'titolo',
        'descrizione',
        'data_inizio',
        'data_fine',
        'bonus_punti',
        'codice_evento',
        'max_partecipanti',
        'num_partecipanti',
        'immagine_url',
        'luogo',
        'attivo'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'data_inizio' => 'datetime',
        'data_fine' => 'datetime',
        'bonus_punti' => 'decimal:2',
        'max_partecipanti' => 'integer',
        'num_partecipanti' => 'integer',
        'attivo' => 'boolean'
    ];

    /**
     * Relazione: Rappresentante creatore
     */
    public function rappresentante()
    {
        return $this->belongsTo(Rappresentante::class, 'rappresentante_id');
    }

    /**
     * Relazione: Partecipazioni
     */
    public function partecipazioni()
    {
        return $this->hasMany(PartecipazioneEvento::class, 'evento_id');
    }

    /**
     * Relazione: Partecipanti (utenti)
     */
    public function partecipanti()
    {
        return $this->belongsToMany(User::class, 'partecipazioni_eventi', 'evento_id', 'user_id')
                    ->withPivot('punti_ricevuti', 'data_partecipazione')
                    ->withTimestamps();
    }

    /**
     * Scope: Eventi attivi
     */
    public function scopeAttivi($query)
    {
        return $query->where('attivo', true)
                     ->where('data_inizio', '<=', now())
                     ->where('data_fine', '>=', now());
    }

    /**
     * Scope: Eventi futuri
     */
    public function scopeFuturi($query)
    {
        return $query->where('data_inizio', '>', now());
    }

    /**
     * Scope: Eventi passati
     */
    public function scopePassati($query)
    {
        return $query->where('data_fine', '<', now());
    }

    /**
     * Verifica se evento è in corso
     */
    public function isInCorso(): bool
    {
        return now()->between($this->data_inizio, $this->data_fine) && $this->attivo;
    }

    /**
     * Verifica se evento è completo (max partecipanti raggiunto)
     */
    public function isCompleto(): bool
    {
        if (!$this->max_partecipanti) {
            return false;
        }
        return $this->num_partecipanti >= $this->max_partecipanti;
    }

    /**
     * Verifica se utente ha già partecipato
     */
    public function haPartecipato(int $userId): bool
    {
        return $this->partecipazioni()->where('user_id', $userId)->exists();
    }

    /**
     * Registra partecipazione utente
     */
    public function registraPartecipazione(int $userId): PartecipazioneEvento
    {
        $this->increment('num_partecipanti');

        return PartecipazioneEvento::create([
            'evento_id' => $this->id,
            'user_id' => $userId,
            'punti_ricevuti' => $this->bonus_punti
        ]);
    }

    /**
     * Accessor: Posti disponibili
     */
    public function getPostiDisponibiliAttribute(): ?int
    {
        if (!$this->max_partecipanti) {
            return null;
        }
        return max(0, $this->max_partecipanti - $this->num_partecipanti);
    }
}

