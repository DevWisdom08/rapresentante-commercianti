# 🔌 API Reference - RAPRESENTANTE COMMERCIANTI

## 🌐 Base URL

```
Development:  http://localhost:8000/api/v1
Production:   https://api.rapresentante.it/api/v1
```

## 🔐 Autenticazione

Tutte le richieste protette richiedono header:

```http
Authorization: Bearer {JWT_TOKEN}
Content-Type: application/json
Accept: application/json
```

---

## 📚 Endpoints

### 🔓 Autenticazione

#### 1. Registrazione Nuovo Utente

```http
POST /auth/registrazione
```

**Body:**
```json
{
  "email": "mario.rossi@email.com",
  "password": "Password123!",
  "password_confirmation": "Password123!",
  "nome": "Mario",
  "cognome": "Rossi",
  "telefono": "+393331234567",
  "ruolo": "cliente"
}
```

**Risposta 201:**
```json
{
  "success": true,
  "message": "Registrazione completata. Controlla la tua email per il codice OTP.",
  "data": {
    "user_id": 123,
    "email": "mario.rossi@email.com",
    "otp_inviato": true
  }
}
```

---

#### 2. Verifica OTP

```http
POST /auth/verifica-otp
```

**Body:**
```json
{
  "email": "mario.rossi@email.com",
  "otp_code": "123456"
}
```

**Risposta 200:**
```json
{
  "success": true,
  "message": "Email verificata con successo",
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer",
    "expires_in": 86400,
    "user": {
      "id": 123,
      "email": "mario.rossi@email.com",
      "nome": "Mario",
      "cognome": "Rossi",
      "ruolo": "cliente",
      "wallet": {
        "saldo_punti": 10.00
      }
    }
  }
}
```

---

#### 3. Login

```http
POST /auth/login
```

**Body:**
```json
{
  "email": "mario.rossi@email.com",
  "password": "Password123!"
}
```

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer",
    "expires_in": 86400,
    "user": {
      "id": 123,
      "email": "mario.rossi@email.com",
      "nome": "Mario",
      "cognome": "Rossi",
      "ruolo": "cliente"
    }
  }
}
```

---

#### 4. Logout

```http
POST /auth/logout
```

**Headers:** `Authorization: Bearer {token}`

**Risposta 200:**
```json
{
  "success": true,
  "message": "Logout effettuato con successo"
}
```

---

#### 5. Profilo Utente

```http
GET /auth/profilo
```

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "id": 123,
    "email": "mario.rossi@email.com",
    "nome": "Mario",
    "cognome": "Rossi",
    "telefono": "+393331234567",
    "ruolo": "cliente",
    "email_verificata": true,
    "attivo": true,
    "created_at": "2025-01-01T10:00:00Z"
  }
}
```

---

### 💰 Wallet

#### 1. Ottieni Wallet

```http
GET /wallet
```

**Risposta 200 (Cliente):**
```json
{
  "success": true,
  "data": {
    "saldo_punti": 150.50,
    "ultimo_aggiornamento": "2025-01-07T15:30:00Z"
  }
}
```

**Risposta 200 (Esercente):**
```json
{
  "success": true,
  "data": {
    "saldo_punti": -200.00,
    "punti_emessi": 1500.00,
    "punti_incassati": 1300.00,
    "saldo": -200.00,
    "ultimo_aggiornamento": "2025-01-07T15:30:00Z"
  }
}
```

---

#### 2. Storico Transazioni

```http
GET /wallet/transazioni?page=1&limit=20
```

**Query Parameters:**
- `page` (int): Numero pagina (default: 1)
- `limit` (int): Elementi per pagina (max: 100, default: 20)
- `tipo` (string): Filtra per tipo transazione

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "current_page": 1,
    "data": [
      {
        "id": 456,
        "tipo": "assegnazione",
        "punti": 50.00,
        "importo_euro": 50.00,
        "mittente": {
          "id": 10,
          "nome": "Panificio Da Mario",
          "tipo": "esercente"
        },
        "destinatario": {
          "id": 123,
          "nome": "Mario Rossi",
          "tipo": "cliente"
        },
        "descrizione": "Acquisto prodotti",
        "created_at": "2025-01-07T14:20:00Z"
      },
      {
        "id": 455,
        "tipo": "bonus_benvenuto",
        "punti": 10.00,
        "descrizione": "Bonus registrazione",
        "created_at": "2025-01-01T10:05:00Z"
      }
    ],
    "total": 2,
    "per_page": 20,
    "last_page": 1
  }
}
```

---

### 🏪 Esercente

#### 1. Assegna Punti a Cliente

```http
POST /esercente/assegna-punti
```

**Ruolo Richiesto:** `esercente`

**Body:**
```json
{
  "cliente_email": "mario.rossi@email.com",
  "importo_euro": 75.50,
  "descrizione": "Acquisto abbigliamento"
}
```

**Risposta 201:**
```json
{
  "success": true,
  "message": "Punti assegnati con successo",
  "data": {
    "transazione_id": 789,
    "punti_assegnati": 75.50,
    "nuovo_saldo_cliente": 226.00,
    "wallet_esercente": {
      "punti_emessi": 1575.50,
      "punti_incassati": 1300.00,
      "saldo": -275.50
    }
  }
}
```

**Errore 400 (Cliente non esiste):**
```json
{
  "success": false,
  "message": "Cliente non trovato",
  "error": "CLIENT_NOT_FOUND"
}
```

---

#### 2. Accetta Punti da Cliente

```http
POST /esercente/accetta-punti
```

**Ruolo Richiesto:** `esercente`

**Body:**
```json
{
  "cliente_id": 123,
  "punti": 50.00,
  "descrizione": "Acquisto con punti"
}
```

**Risposta 200:**
```json
{
  "success": true,
  "message": "Pagamento con punti completato",
  "data": {
    "transazione_id": 790,
    "punti_utilizzati": 50.00,
    "nuovo_saldo_cliente": 176.00,
    "wallet_esercente": {
      "punti_emessi": 1575.50,
      "punti_incassati": 1350.00,
      "saldo": -225.50
    }
  }
}
```

**Errore 403 (Blocco Stesso Negozio):**
```json
{
  "success": false,
  "message": "Il cliente non può spendere punti in questo negozio perché li ha guadagnati qui",
  "error": "SAME_STORE_BLOCK"
}
```

**Errore 400 (Saldo Insufficiente):**
```json
{
  "success": false,
  "message": "Il cliente non ha abbastanza punti",
  "error": "INSUFFICIENT_POINTS",
  "data": {
    "punti_richiesti": 50.00,
    "saldo_disponibile": 30.00
  }
}
```

---

#### 3. Dashboard Esercente

```http
GET /esercente/dashboard
```

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "wallet": {
      "punti_emessi": 1575.50,
      "punti_incassati": 1350.00,
      "saldo": -225.50
    },
    "statistiche": {
      "clienti_unici_mese": 45,
      "punti_emessi_mese": 450.00,
      "punti_incassati_mese": 380.00,
      "transazioni_mese": 78
    },
    "ultimi_clienti": [
      {
        "nome": "Mario Rossi",
        "punti_assegnati": 75.50,
        "data": "2025-01-07T14:20:00Z"
      }
    ],
    "trend_settimana": [
      { "giorno": "2025-01-01", "emessi": 120, "incassati": 90 },
      { "giorno": "2025-01-02", "emessi": 150, "incassati": 100 }
    ]
  }
}
```

---

#### 4. Lista Esercenti Zona

```http
GET /esercente/lista-zona
```

**Risposta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "nome_negozio": "Panificio Da Mario",
      "categoria": "alimentari",
      "indirizzo": "Via Roma 10, Milano",
      "telefono": "+3902123456",
      "distanza_km": 0.5
    },
    {
      "id": 11,
      "nome_negozio": "Abbigliamento Moda",
      "categoria": "abbigliamento",
      "indirizzo": "Via Garibaldi 25, Milano",
      "distanza_km": 1.2
    }
  ]
}
```

---

### 👥 Rappresentante

#### 1. Dashboard Rappresentante

```http
GET /rappresentante/dashboard
```

**Ruolo Richiesto:** `rappresentante`

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "zona": {
      "nome": "Milano Centro",
      "provincia": "MI",
      "num_esercenti": 28,
      "num_clienti": 450
    },
    "kpi": {
      "punti_totali_circolazione": 15670.50,
      "punti_emessi_mese": 5430.00,
      "punti_spesi_mese": 4890.00,
      "tasso_circolazione": 90.1,
      "nuovi_clienti_mese": 23
    },
    "top_esercenti": [
      {
        "nome_negozio": "Panificio Da Mario",
        "punti_incassati": 1350.00,
        "clienti_unici": 67,
        "saldo": -225.50
      },
      {
        "nome_negozio": "Abbigliamento Moda",
        "punti_incassati": 1120.00,
        "clienti_unici": 45,
        "saldo": 50.00
      }
    ],
    "eventi_attivi": [
      {
        "id": 5,
        "titolo": "Festa del Quartiere",
        "data_inizio": "2025-01-15",
        "bonus_punti": 20,
        "partecipanti": 12
      }
    ]
  }
}
```

---

#### 2. Lista Esercenti Zona

```http
GET /rappresentante/esercenti
```

**Risposta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 10,
      "nome_negozio": "Panificio Da Mario",
      "categoria": "alimentari",
      "citta": "Milano",
      "attivo": true,
      "wallet": {
        "punti_emessi": 1575.50,
        "punti_incassati": 1350.00,
        "saldo": -225.50
      },
      "statistiche": {
        "clienti_unici": 67,
        "transazioni_totali": 234
      }
    }
  ]
}
```

---

#### 3. Crea Evento

```http
POST /rappresentante/eventi
```

**Body:**
```json
{
  "titolo": "Festa del Quartiere 2025",
  "descrizione": "Partecipa alla festa e ricevi punti bonus",
  "data_inizio": "2025-01-15 10:00:00",
  "data_fine": "2025-01-15 20:00:00",
  "bonus_punti": 20.00,
  "max_partecipanti": 100,
  "luogo": "Piazza Centrale, Milano"
}
```

**Risposta 201:**
```json
{
  "success": true,
  "message": "Evento creato con successo",
  "data": {
    "id": 6,
    "titolo": "Festa del Quartiere 2025",
    "codice_evento": "FDQ2025-XY7Z",
    "bonus_punti": 20.00,
    "qr_code_url": "https://api.rapresentante.it/qr/FDQ2025-XY7Z.png"
  }
}
```

---

#### 4. Export Report CSV

```http
GET /rappresentante/report/export?periodo=ultimo_mese
```

**Query Parameters:**
- `periodo`: `ultima_settimana`, `ultimo_mese`, `ultimo_trimestre`
- `tipo`: `transazioni`, `esercenti`, `clienti`, `completo`

**Risposta 200:**
```
Content-Type: text/csv
Content-Disposition: attachment; filename="report_milano_centro_2025_01.csv"

(CSV file download)
```

---

### 👑 Centrale (Admin)

#### 1. Dashboard Globale

```http
GET /centrale/dashboard
```

**Ruolo Richiesto:** `centrale`

**Risposta 200:**
```json
{
  "success": true,
  "data": {
    "statistiche_globali": {
      "num_rappresentanti": 5,
      "num_esercenti": 127,
      "num_clienti": 2340,
      "punti_totali_circolazione": 87650.50,
      "transazioni_totali": 5678
    },
    "top_zone": [
      {
        "nome_zona": "Milano Centro",
        "rappresentante": "Marco Rossi",
        "num_esercenti": 28,
        "punti_circolazione": 15670.50
      }
    ],
    "grafico_crescita": [
      { "mese": "2024-11", "clienti": 1800, "transazioni": 3400 },
      { "mese": "2024-12", "clienti": 2100, "transazioni": 4500 },
      { "mese": "2025-01", "clienti": 2340, "transazioni": 5678 }
    ]
  }
}
```

---

#### 2. Gestione Utenti

```http
GET /centrale/utenti?ruolo=esercente&page=1
POST /centrale/utenti/{id}/attiva
POST /centrale/utenti/{id}/disattiva
DELETE /centrale/utenti/{id}
```

---

#### 3. Configurazioni Sistema

```http
GET /centrale/configurazioni
PUT /centrale/configurazioni
```

**Body PUT:**
```json
{
  "bonus_benvenuto": 10.00,
  "scadenza_punti_giorni": 180,
  "limite_max_punti_transazione": 500.00,
  "tasso_cambio_punti_euro": 1.00
}
```

---

### 🎯 Eventi

#### 1. Lista Eventi Attivi

```http
GET /eventi?attivi=true
```

**Risposta 200:**
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "titolo": "Festa del Quartiere",
      "descrizione": "Partecipa e ricevi 20 punti",
      "data_inizio": "2025-01-15T10:00:00Z",
      "data_fine": "2025-01-15T20:00:00Z",
      "bonus_punti": 20.00,
      "codice_evento": "FDQ2025-XY7Z",
      "luogo": "Piazza Centrale, Milano",
      "posti_disponibili": 88
    }
  ]
}
```

---

#### 2. Partecipa Evento (Cliente)

```http
POST /eventi/{id}/partecipa
```

**Body:**
```json
{
  "codice_evento": "FDQ2025-XY7Z"
}
```

**Risposta 200:**
```json
{
  "success": true,
  "message": "Partecipazione confermata! Hai ricevuto 20 punti bonus",
  "data": {
    "punti_ricevuti": 20.00,
    "nuovo_saldo": 196.00,
    "evento": {
      "titolo": "Festa del Quartiere",
      "data": "2025-01-15"
    }
  }
}
```

---

## 📊 Codici di Stato HTTP

| Codice | Significato |
|--------|-------------|
| 200    | OK - Richiesta completata |
| 201    | Created - Risorsa creata |
| 400    | Bad Request - Dati non validi |
| 401    | Unauthorized - Token mancante/invalido |
| 403    | Forbidden - Permessi insufficienti |
| 404    | Not Found - Risorsa non trovata |
| 422    | Unprocessable Entity - Validazione fallita |
| 429    | Too Many Requests - Rate limit superato |
| 500    | Internal Server Error |

---

## 🚨 Gestione Errori

### Formato Standard Errore

```json
{
  "success": false,
  "message": "Descrizione errore leggibile",
  "error": "ERROR_CODE",
  "data": {
    // Dati aggiuntivi contestuali
  }
}
```

### Codici Errore Comuni

| Codice | Descrizione |
|--------|-------------|
| `INVALID_CREDENTIALS` | Email o password errati |
| `EMAIL_NOT_VERIFIED` | Email non verificata |
| `OTP_EXPIRED` | Codice OTP scaduto |
| `INSUFFICIENT_POINTS` | Saldo punti insufficiente |
| `SAME_STORE_BLOCK` | Tentativo spesa nello stesso negozio |
| `CLIENT_NOT_FOUND` | Cliente non esistente |
| `UNAUTHORIZED` | Token invalido |
| `FORBIDDEN` | Azione non permessa per il ruolo |
| `RATE_LIMIT_EXCEEDED` | Troppe richieste |

---

## 🔒 Rate Limiting

- **Standard:** 60 richieste/minuto per IP
- **Autenticati:** 120 richieste/minuto per token
- **Admin:** 300 richieste/minuto

Headers risposta:
```http
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 115
X-RateLimit-Reset: 1704646800
```

---

**Versione API:** v1.0  
**Ultimo Aggiornamento:** Gennaio 2025

