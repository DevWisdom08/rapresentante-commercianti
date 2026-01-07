<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Model Wallet - Portafoglio digitale punti
 * 
 * Per clienti: solo saldo_punti è rilevante
 * Per esercenti: saldo_punti + punti_emessi + punti_incassati
 */
class Wallet extends Model
{
    use HasFactory;

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'user_id',
        'saldo_punti',
        'punti_emessi',
        'punti_incassati',
        'ultimo_aggiornamento'
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'saldo_punti' => 'decimal:2',
        'punti_emessi' => 'decimal:2',
        'punti_incassati' => 'decimal:2',
        'ultimo_aggiornamento' => 'datetime'
    ];

    /**
     * Relazione: Utente proprietario del wallet
     */
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Aggiungi punti al wallet
     * 
     * @param float $punti
     * @param string $motivo
     * @return bool
     */
    public function aggiungiPunti(float $punti, string $motivo = 'Aggiunta punti'): bool
    {
        $this->saldo_punti += $punti;
        $this->ultimo_aggiornamento = now();
        
        // Log::info("Wallet {$this->id}: +{$punti} punti. Nuovo saldo: {$this->saldo_punti}. Motivo: {$motivo}");
        
        return $this->save();
    }

    /**
     * Rimuovi punti dal wallet
     * 
     * @param float $punti
     * @param string $motivo
     * @return bool
     * @throws \Exception Se saldo insufficiente
     */
    public function rimuoviPunti(float $punti, string $motivo = 'Rimozione punti'): bool
    {
        if ($this->saldo_punti < $punti) {
            throw new \Exception("Saldo insufficiente. Disponibile: {$this->saldo_punti}, Richiesto: {$punti}");
        }

        $this->saldo_punti -= $punti;
        $this->ultimo_aggiornamento = now();
        
        // Log::info("Wallet {$this->id}: -{$punti} punti. Nuovo saldo: {$this->saldo_punti}. Motivo: {$motivo}");
        
        return $this->save();
    }

    /**
     * Registra punti emessi (solo per esercenti)
     * 
     * @param float $punti
     * @return bool
     */
    public function registraPuntiEmessi(float $punti): bool
    {
        $this->punti_emessi += $punti;
        $this->ultimo_aggiornamento = now();
        
        // Log::info("Wallet {$this->id} (Esercente): Emessi +{$punti}. Totale emessi: {$this->punti_emessi}");
        
        return $this->save();
    }

    /**
     * Registra punti incassati (solo per esercenti)
     * 
     * @param float $punti
     * @return bool
     */
    public function registraPuntiIncassati(float $punti): bool
    {
        $this->punti_incassati += $punti;
        $this->ultimo_aggiornamento = now();
        
        // Log::info("Wallet {$this->id} (Esercente): Incassati +{$punti}. Totale incassati: {$this->punti_incassati}");
        
        return $this->save();
    }

    /**
     * Calcola saldo esercente
     * Saldo = Punti Incassati - Punti Emessi
     * 
     * @return float
     */
    public function getSaldoEsercenteAttribute(): float
    {
        return (float) ($this->punti_incassati - $this->punti_emessi);
    }

    /**
     * Verifica se wallet ha saldo sufficiente
     * 
     * @param float $importo
     * @return bool
     */
    public function hasSaldoSufficiente(float $importo): bool
    {
        return $this->saldo_punti >= $importo;
    }

    /**
     * Scope: Filtra wallet con saldo positivo
     */
    public function scopeConSaldoPositivo($query)
    {
        return $query->where('saldo_punti', '>', 0);
    }

    /**
     * Scope: Filtra wallet di esercenti
     */
    public function scopeEsercenti($query)
    {
        return $query->whereHas('user', function($q) {
            $q->where('ruolo', 'esercente');
        });
    }

    /**
     * Scope: Filtra wallet di clienti
     */
    public function scopeClienti($query)
    {
        return $query->whereHas('user', function($q) {
            $q->where('ruolo', 'cliente');
        });
    }
}

