<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;

/**
 * Model User - Utente multiruolo
 * 
 * Ruoli: cliente, esercente, rappresentante, centrale
 */
class User extends Authenticatable implements JWTSubject
{
    use HasFactory, Notifiable;

    /**
     * Attributi assegnabili in massa
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'email',
        'password',
        'nome',
        'cognome',
        'telefono',
        'ruolo',
        'email_verified_at',
        'otp_code',
        'otp_expires_at',
        'attivo',
        'ultimo_accesso'
    ];

    /**
     * Attributi nascosti per array
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'otp_code',
        'remember_token',
    ];

    /**
     * Attributi da castare a tipi nativi
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'otp_expires_at' => 'datetime',
        'ultimo_accesso' => 'datetime',
        'attivo' => 'boolean',
        'password' => 'hashed',
    ];

    /**
     * Relazione: Wallet dell'utente
     */
    public function wallet()
    {
        return $this->hasOne(Wallet::class);
    }

    /**
     * Relazione: Transazioni come mittente
     */
    public function transazioniInviate()
    {
        return $this->hasMany(Transazione::class, 'mittente_id');
    }

    /**
     * Relazione: Transazioni come destinatario
     */
    public function transazioniRicevute()
    {
        return $this->hasMany(Transazione::class, 'destinatario_id');
    }

    /**
     * Relazione: Dati esercente (se ruolo = esercente)
     */
    public function esercente()
    {
        return $this->hasOne(Esercente::class);
    }

    /**
     * Relazione: Dati rappresentante (se ruolo = rappresentante)
     */
    public function rappresentante()
    {
        return $this->hasOne(Rappresentante::class);
    }

    /**
     * Verifica se l'utente ha un ruolo specifico
     * 
     * @param string $ruolo
     * @return bool
     */
    public function hasRole(string $ruolo): bool
    {
        return $this->ruolo === $ruolo;
    }

    /**
     * Verifica se l'utente ha uno dei ruoli specificati
     * 
     * @param array $ruoli
     * @return bool
     */
    public function hasAnyRole(array $ruoli): bool
    {
        return in_array($this->ruolo, $ruoli);
    }

    /**
     * Verifica se l'utente è un cliente
     * 
     * @return bool
     */
    public function isCliente(): bool
    {
        return $this->ruolo === 'cliente';
    }

    /**
     * Verifica se l'utente è un esercente
     * 
     * @return bool
     */
    public function isEsercente(): bool
    {
        return $this->ruolo === 'esercente';
    }

    /**
     * Verifica se l'utente è un rappresentante
     * 
     * @return bool
     */
    public function isRappresentante(): bool
    {
        return $this->ruolo === 'rappresentante';
    }

    /**
     * Verifica se l'utente è centrale (admin)
     * 
     * @return bool
     */
    public function isCentrale(): bool
    {
        return $this->ruolo === 'centrale';
    }

    /**
     * JWT: Ottieni identificatore per JWT
     * 
     * @return mixed
     */
    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    /**
     * JWT: Ottieni claims custom per JWT
     * 
     * @return array
     */
    public function getJWTCustomClaims()
    {
        return [
            'ruolo' => $this->ruolo,
            'nome' => $this->nome,
            'cognome' => $this->cognome
        ];
    }
}

