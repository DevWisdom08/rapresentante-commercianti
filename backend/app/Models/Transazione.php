<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model Transazione - Log completo movimentazioni punti
 * 
 * Tipi transazione:
 * - assegnazione: Esercente → Cliente
 * - pagamento: Cliente → Esercente
 * - bonus_benvenuto: Sistema → Cliente
 * - bonus_evento: Sistema → Cliente
 * - rimborso: Esercente → Cliente
 * - scadenza: Sistema (punti scaduti)
 */
class Transazione extends Model
{
    use HasFactory;

    /**
     * Disabilita updated_at (solo created_at)
     */
    const UPDATED_AT = null;

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'mittente_id',
        'destinatario_id',
        'punti',
        'importo_euro',
        'tipo',
        'esercente_origine_id',
        'descrizione',
        'metadata',
        'ip_address',
        'user_agent'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'punti' => 'decimal:2',
        'importo_euro' => 'decimal:2',
        'metadata' => 'array',
        'created_at' => 'datetime'
    ];

    /**
     * Nome tabella database
     */
    protected $table = 'transazioni';

    /**
     * Relazione: Mittente (utente che invia punti)
     */
    public function mittente()
    {
        return $this->belongsTo(User::class, 'mittente_id');
    }

    /**
     * Relazione: Destinatario (utente che riceve punti)
     */
    public function destinatario()
    {
        return $this->belongsTo(User::class, 'destinatario_id');
    }

    /**
     * Relazione: Esercente origine (per tracking)
     */
    public function esercenteOrigine()
    {
        return $this->belongsTo(User::class, 'esercente_origine_id');
    }

    /**
     * Scope: Filtra per tipo transazione
     */
    public function scopeDelTipo($query, string $tipo)
    {
        return $query->where('tipo', $tipo);
    }

    /**
     * Scope: Transazioni di assegnazione (Esercente → Cliente)
     */
    public function scopeAssegnazioni($query)
    {
        return $query->where('tipo', 'assegnazione');
    }

    /**
     * Scope: Transazioni di pagamento (Cliente → Esercente)
     */
    public function scopePagamenti($query)
    {
        return $query->where('tipo', 'pagamento');
    }

    /**
     * Scope: Bonus (benvenuto + eventi)
     */
    public function scopeBonus($query)
    {
        return $query->whereIn('tipo', ['bonus_benvenuto', 'bonus_evento']);
    }

    /**
     * Scope: Transazioni di un utente (mittente o destinatario)
     */
    public function scopePerUtente($query, int $userId)
    {
        return $query->where(function($q) use ($userId) {
            $q->where('mittente_id', $userId)
              ->orWhere('destinatario_id', $userId);
        });
    }

    /**
     * Scope: Transazioni recenti (ultimi N giorni)
     */
    public function scopeRecenti($query, int $giorni = 30)
    {
        return $query->where('created_at', '>=', now()->subDays($giorni));
    }

    /**
     * Scope: Ordina per più recenti
     */
    public function scopePiuRecenti($query)
    {
        return $query->orderBy('created_at', 'desc');
    }

    /**
     * Accessor: Formatta punti con simbolo
     */
    public function getPuntiFormattatiAttribute(): string
    {
        return number_format($this->punti, 2, ',', '.') . ' punti';
    }

    /**
     * Accessor: Formatta importo euro
     */
    public function getImportoFormattato Attribute(): ?string
    {
        if (!$this->importo_euro) {
            return null;
        }
        return '€ ' . number_format($this->importo_euro, 2, ',', '.');
    }

    /**
     * Accessor: Descrizione tipo human-readable
     */
    public function getTipoDescrizioneAttribute(): string
    {
        return match($this->tipo) {
            'assegnazione' => 'Assegnazione punti',
            'pagamento' => 'Pagamento con punti',
            'bonus_benvenuto' => 'Bonus benvenuto',
            'bonus_evento' => 'Bonus evento',
            'rimborso' => 'Rimborso',
            'scadenza' => 'Scadenza punti',
            default => ucfirst($this->tipo)
        };
    }

    /**
     * Crea transazione assegnazione
     * 
     * @param int $esercenteId
     * @param int $clienteId
     * @param float $punti
     * @param float $importoEuro
     * @param string|null $descrizione
     * @param array $metadata
     * @return self
     */
    public static function creaAssegnazione(
        int $esercenteId,
        int $clienteId,
        float $punti,
        float $importoEuro,
        ?string $descrizione = null,
        array $metadata = []
    ): self {
        return self::create([
            'mittente_id' => $esercenteId,
            'destinatario_id' => $clienteId,
            'punti' => $punti,
            'importo_euro' => $importoEuro,
            'tipo' => 'assegnazione',
            'esercente_origine_id' => $esercenteId,
            'descrizione' => $descrizione ?? 'Acquisto presso esercente',
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent()
        ]);
    }

    /**
     * Crea transazione pagamento
     * 
     * @param int $clienteId
     * @param int $esercenteId
     * @param float $punti
     * @param int|null $esercenteOrigineId
     * @param string|null $descrizione
     * @param array $metadata
     * @return self
     */
    public static function creaPagamento(
        int $clienteId,
        int $esercenteId,
        float $punti,
        ?int $esercenteOrigineId = null,
        ?string $descrizione = null,
        array $metadata = []
    ): self {
        return self::create([
            'mittente_id' => $clienteId,
            'destinatario_id' => $esercenteId,
            'punti' => $punti,
            'tipo' => 'pagamento',
            'esercente_origine_id' => $esercenteOrigineId,
            'descrizione' => $descrizione ?? 'Pagamento con punti',
            'metadata' => $metadata,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent()
        ]);
    }
}

