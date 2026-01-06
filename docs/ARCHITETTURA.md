# 🏗️ Architettura Sistema RAPRESENTANTE COMMERCIANTI

## 📐 Panoramica Generale

Sistema distribuito composto da:
- **Backend API** (Laravel)
- **Frontend Multipiattaforma** (Flutter)
- **Database Relazionale** (MySQL)
- **Storage Files** (locale per MVP, S3 per produzione)

```
┌─────────────────────────────────────────────────┐
│                   FRONTEND                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │   iOS    │  │ Android  │  │  Web (PWA)   │  │
│  │  Native  │  │  Native  │  │   Browser    │  │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  │
│       │             │                │          │
│       └─────────────┴────────────────┘          │
│                     │                           │
│              Flutter Framework                  │
└─────────────────────┼───────────────────────────┘
                      │
                  HTTPS/REST
                      │
┌─────────────────────▼───────────────────────────┐
│              BACKEND API (Laravel)               │
│  ┌──────────────────────────────────────────┐  │
│  │  Controllers (Autenticazione, Wallet,    │  │
│  │   Transazioni, Dashboard, Admin)         │  │
│  └────────────────┬─────────────────────────┘  │
│                   │                             │
│  ┌────────────────▼─────────────────────────┐  │
│  │  Business Logic (Services)               │  │
│  │  - WalletService                         │  │
│  │  - TransazioneService                    │  │
│  │  - BloccoStessoNegozioService           │  │
│  │  - BonusEventoService                    │  │
│  └────────────────┬─────────────────────────┘  │
│                   │                             │
│  ┌────────────────▼─────────────────────────┐  │
│  │  Models (Eloquent ORM)                   │  │
│  │  User, Wallet, Transazione, Esercente... │  │
│  └────────────────┬─────────────────────────┘  │
└───────────────────┼─────────────────────────────┘
                    │
                    │
┌───────────────────▼─────────────────────────────┐
│              DATABASE (MySQL)                    │
│  ┌──────────────────────────────────────────┐  │
│  │  Tabelle:                                │  │
│  │  - users (multiruolo)                    │  │
│  │  - wallets (saldo punti)                 │  │
│  │  - transazioni (log completo)            │  │
│  │  - esercenti (dati negozio)              │  │
│  │  - rappresentanti (zone)                 │  │
│  │  - eventi (bonus territoriali)           │  │
│  └──────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## 🔐 Autenticazione e Autorizzazione

### Sistema Multiruolo

```php
Ruoli Disponibili:
├── cliente          (level: 1)
├── esercente        (level: 2)
├── rappresentante   (level: 3)
└── centrale         (level: 4)
```

### Flow Autenticazione

1. **Registrazione:**
   - Email + Password
   - OTP via email (6 cifre)
   - Verifica OTP
   - Assegnazione ruolo
   - Creazione wallet (se cliente/esercente)
   - Bonus benvenuto (10 punti per clienti)

2. **Login:**
   - Email + Password
   - Generazione JWT token
   - Token contiene: user_id, ruolo, scadenza
   - Refresh token per sessioni lunghe

3. **Middleware Protezione:**
   - `auth:api` - richiede token valido
   - `role:esercente` - richiede ruolo specifico
   - `role:esercente|rappresentante` - uno dei ruoli

## 💰 Sistema Wallet e Punti

### Struttura Wallet

```sql
wallets
├── id
├── user_id (FK → users)
├── saldo_punti (decimal 10,2)
├── punti_emessi (solo esercenti)
├── punti_incassati (solo esercenti)
├── ultimo_aggiornamento
└── timestamps
```

### Bilancio Esercente

```
Saldo Esercente = punti_incassati - punti_emessi

Interpretazione:
- Saldo > 0 → Ha attratto clienti (successo marketing)
- Saldo < 0 → Ha "seminato" clientela (investimento)
- Saldo = 0 → Equilibrio perfetto
```

## 🔄 Sistema Transazioni

### Tipi di Transazione

```php
enum TipoTransazione {
    ASSEGNAZIONE,      // Esercente → Cliente
    PAGAMENTO,         // Cliente → Esercente
    BONUS_BENVENUTO,   // Sistema → Cliente
    BONUS_EVENTO,      // Sistema → Cliente
    RIMBORSO,          // Esercente → Cliente (annullamento)
    SCADENZA           // Sistema (punti scaduti)
}
```

### Flow Assegnazione Punti

```
1. Cliente acquista per 50€ nel Negozio A
2. Esercente A inserisce: importo_euro = 50
3. Sistema:
   - Calcola punti = 50 * 1 = 50 punti
   - Wallet Cliente: saldo += 50
   - Wallet Esercente A: punti_emessi += 50
   - Log transazione
4. Cliente riceve notifica
```

### Flow Spesa Punti

```
1. Cliente vuole spendere 30 punti nel Negozio B
2. Sistema VERIFICA:
   ✓ Cliente ha >= 30 punti
   ✓ Negozio B ≠ Negozio dove ha guadagnato i punti
   ✓ Negozio B è attivo
3. Sistema ESEGUE:
   - Wallet Cliente: saldo -= 30
   - Wallet Esercente B: punti_incassati += 30
   - Wallet Esercente B: saldo_punti -= 30 (costo sconto)
   - Log transazione
4. Entrambi ricevono notifica
```

## 🚫 Blocco "Stesso Negozio" (Regola Fondamentale)

### Implementazione

```php
class BloccoStessoNegozioService {
    
    public function puoSpenderePunti(
        int $cliente_id, 
        int $esercente_destinazione_id
    ): bool {
        
        // Recupera tutte le transazioni di assegnazione
        $assegnazioni = Transazione::where('destinatario_id', $cliente_id)
            ->where('tipo', 'ASSEGNAZIONE')
            ->where('mittente_id', $esercente_destinazione_id)
            ->sum('punti');
        
        // Se ha ricevuto punti da questo esercente, BLOCCO
        if ($assegnazioni > 0) {
            return false;
        }
        
        return true;
    }
}
```

### Logica Avanzata (Opzionale Fase 2)

```
Scenario: Cliente ha 100 punti
- 70 punti da Negozio A
- 30 punti da Negozio B

Vuole spendere nel Negozio A:
- PUÒ spendere MAX 30 punti (quelli da B)
- NON può spendere i 70 da A
```

Per MVP: **BLOCCO TOTALE** (più semplice e sicuro)

## 📊 Dashboard e KPI

### Dashboard Cliente
- Saldo punti corrente
- Storico transazioni (ultime 50)
- Negozi dove può spendere
- Eventi attivi con bonus

### Dashboard Esercente
- Bilancio completo:
  - Punti emessi (totale)
  - Punti incassati (totale)
  - Saldo (incassati - emessi)
- Clienti acquisiti questo mese
- Grafico trend emissione/incasso
- QR Code per assegnazione rapida

### Dashboard Rappresentante
- KPI Zona:
  - Numero esercenti attivi
  - Numero clienti zona
  - Punti totali in circolazione
  - Tasso circolazione punti
- Ranking esercenti (per punti incassati)
- Eventi creati e performance
- Report esportabili CSV

### Dashboard Centrale
- **Vista Globale:**
  - Tutte le zone
  - Tutti gli esercenti
  - Tutti i clienti
  - Tutte le transazioni
- **Configurazioni Sistema:**
  - Bonus benvenuto (default 10)
  - Scadenza punti (default 180 giorni)
  - Limite massimo punti per transazione
  - Attivazione/disattivazione esercenti
- **Report Avanzati:**
  - Heatmap geografica movimenti
  - Analisi flussi cross-negozio
  - Esercenti più performanti
  - Export dati grezzi

## 🎯 Eventi e Bonus

### Struttura Evento

```sql
eventi
├── id
├── rappresentante_id (chi ha creato)
├── zona_id
├── titolo
├── descrizione
├── data_inizio
├── data_fine
├── bonus_punti (es. 20)
├── condizione (es. "partecipa alla sagra")
└── attivo
```

### Assegnazione Bonus Evento

```
1. Rappresentante crea evento con bonus 20 punti
2. Cliente partecipa (scansiona QR evento o codice)
3. Sistema:
   - Verifica cliente in zona corretta
   - Verifica evento attivo
   - Wallet Cliente: saldo += 20
   - Log transazione tipo BONUS_EVENTO
4. Cliente riceve notifica
```

## 🔒 Sicurezza

### Livelli di Protezione

1. **API Level:**
   - Rate limiting (60 req/min per IP)
   - JWT expiration (24h)
   - HTTPS obbligatorio in produzione

2. **Business Logic Level:**
   - Validazione double-spending
   - Controllo saldi negativi
   - Audit log completo

3. **Database Level:**
   - Foreign keys con ON DELETE CASCADE
   - Indexes su campi critici
   - Backup automatici

### Prevenzione Abusi

```
Scenario Attacco: Cliente tenta double-spending
1. Cliente ha 50 punti
2. Invia 2 richieste simultanee per spendere 50 punti

Difesa:
- Database transaction con lock
- Controllo saldo DENTRO la transaction
- Solo 1 delle 2 richieste va a buon fine
```

## 📱 Frontend Architecture (Flutter)

### Struttura Modulare

```
frontend/lib/
├── main.dart
├── config/
│   ├── api_config.dart
│   └── theme.dart
├── models/
│   ├── user.dart
│   ├── wallet.dart
│   └── transazione.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── wallet_service.dart
├── screens/
│   ├── cliente/
│   │   ├── home_cliente.dart
│   │   ├── wallet_page.dart
│   │   └── storico_page.dart
│   ├── esercente/
│   │   ├── home_esercente.dart
│   │   ├── assegna_punti.dart
│   │   └── dashboard_esercente.dart
│   ├── rappresentante/
│   │   └── dashboard_rappresentante.dart
│   └── centrale/
│       └── dashboard_centrale.dart
├── widgets/
│   ├── custom_button.dart
│   ├── wallet_card.dart
│   └── transazione_tile.dart
└── utils/
    ├── validators.dart
    └── formatters.dart
```

### State Management

**Provider Pattern** (semplice per MVP):
- `AuthProvider` - stato autenticazione
- `WalletProvider` - stato wallet e transazioni
- `DashboardProvider` - dati dashboard

### Routing Basato su Ruolo

```dart
if (user.ruolo == 'cliente') {
  Navigator.pushReplacementNamed(context, '/home-cliente');
} else if (user.ruolo == 'esercente') {
  Navigator.pushReplacementNamed(context, '/home-esercente');
} else if (user.ruolo == 'rappresentante') {
  Navigator.pushReplacementNamed(context, '/dashboard-rappresentante');
} else if (user.ruolo == 'centrale') {
  Navigator.pushReplacementNamed(context, '/dashboard-centrale');
}
```

## 🚀 Deploy Architecture

### MVP (DigitalOcean Droplet)

```
Server: Ubuntu 22.04 LTS
RAM: 2GB
Storage: 50GB SSD
CPU: 1 vCPU

Software Stack:
├── Nginx (web server)
├── PHP 8.2 FPM
├── MySQL 8.0
├── Certbot (SSL Let's Encrypt)
└── Supervisor (queue workers)
```

### Produzione (Hetzner - Fase 2)

```
Server: Hetzner Cloud CX21
RAM: 4GB
Storage: 80GB SSD
CPU: 2 vCPU

+ Load Balancer
+ Redis (cache e sessioni)
+ S3-compatible storage (immagini)
```

## 📈 Scalabilità

### Colli di Bottiglia Previsti

1. **Database writes** (transazioni frequenti)
   - Soluzione: Database indexing + read replicas

2. **Calcolo bilanci esercenti** (query pesanti)
   - Soluzione: Cache Redis + aggiornamento incrementale

3. **Export report grandi**
   - Soluzione: Queue jobs + download differito

### Piano Scalabilità

```
Fase 1: 1 server monolitico         → 0-1000 utenti
Fase 2: Separazione DB              → 1000-10.000 utenti
Fase 3: Load balancing + Redis      → 10.000-100.000 utenti
Fase 4: Microservizi (opzionale)    → 100.000+ utenti
```

---

**Documento Versione:** 1.0  
**Ultimo Aggiornamento:** Gennaio 2025  
**Stato:** 🔧 In Definizione

