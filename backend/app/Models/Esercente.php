<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model Esercente - Dati specifici negozi aderenti
 */
class Esercente extends Model
{
    use HasFactory;

    /**
     * Nome tabella database
     */
    protected $table = 'esercenti';

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'rappresentante_id',
        'nome_negozio',
        'partita_iva',
        'indirizzo',
        'citta',
        'cap',
        'provincia',
        'telefono_negozio',
        'categoria',
        'descrizione',
        'orari_apertura',
        'logo_url',
        'foto_negozio',
        'attivo',
        'data_adesione'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'orari_apertura' => 'array',
        'foto_negozio' => 'array',
        'attivo' => 'boolean',
        'data_adesione' => 'date'
    ];

    /**
     * Relazione: Utente associato
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Relazione: Rappresentante di zona
     */
    public function rappresentante()
    {
        return $this->belongsTo(Rappresentante::class, 'rappresentante_id');
    }

    /**
     * Scope: Filtra esercenti attivi
     */
    public function scopeAttivi($query)
    {
        return $query->where('attivo', true);
    }

    /**
     * Scope: Filtra per città
     */
    public function scopePerCitta($query, string $citta)
    {
        return $query->where('citta', $citta);
    }

    /**
     * Scope: Filtra per categoria
     */
    public function scopePerCategoria($query, string $categoria)
    {
        return $query->where('categoria', $categoria);
    }

    /**
     * Scope: Filtra per zona (rappresentante)
     */
    public function scopePerZona($query, int $rappresentanteId)
    {
        return $query->where('rappresentante_id', $rappresentanteId);
    }

    /**
     * Accessor: Nome completo con città
     */
    public function getNomeCompletoAttribute(): string
    {
        return "{$this->nome_negozio} - {$this->citta}";
    }

    /**
     * Accessor: Indirizzo completo
     */
    public function getIndirizzoCompletoAttribute(): string
    {
        return "{$this->indirizzo}, {$this->cap} {$this->citta} ({$this->provincia})";
    }

    /**
     * Accessor: Categoria formattata
     */
    public function getCategoriaFormattataAttribute(): string
    {
        return match($this->categoria) {
            'alimentari' => 'Alimentari',
            'abbigliamento' => 'Abbigliamento',
            'bar_ristoranti' => 'Bar e Ristoranti',
            'servizi' => 'Servizi',
            'salute_benessere' => 'Salute e Benessere',
            'casa_arredamento' => 'Casa e Arredamento',
            'elettronica' => 'Elettronica',
            'altro' => 'Altro',
            default => ucfirst($this->categoria)
        };
    }
}

