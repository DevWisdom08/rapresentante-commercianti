# 🗄️ Schema Database - RAPRESENTANTE COMMERCIANTI

## 📊 Diagramma Entità-Relazioni

```
┌─────────────────┐
│     USERS       │
├─────────────────┤
│ id              │◄───┐
│ email*          │    │
│ password        │    │
│ nome            │    │
│ cognome         │    │
│ telefono        │    │
│ ruolo*          │    │
│ email_verified  │    │
│ attivo          │    │
│ created_at      │    │
└─────────────────┘    │
         │             │
         │             │
┌────────▼─────────┐   │
│    WALLETS       │   │
├──────────────────┤   │
│ id               │   │
│ user_id*         │───┘
│ saldo_punti      │
│ punti_emessi     │ (solo esercenti)
│ punti_incassati  │ (solo esercenti)
│ updated_at       │
└──────────────────┘
         │
         │
┌────────▼──────────────┐
│   TRANSAZIONI         │
├───────────────────────┤
│ id                    │
│ mittente_id*          │ → users.id
│ destinatario_id*      │ → users.id
│ punti                 │
│ importo_euro          │ (se applicabile)
│ tipo*                 │ (enum)
│ esercente_origine_id  │ (tracking)
│ descrizione           │
│ metadata              │ (JSON)
│ created_at            │
└───────────────────────┘


┌─────────────────────┐
│    ESERCENTI        │
├─────────────────────┤
│ id                  │
│ user_id*            │ → users.id
│ rappresentante_id   │ → rappresentanti.id
│ nome_negozio        │
│ partita_iva         │
│ indirizzo           │
│ citta               │
│ cap                 │
│ telefono_negozio    │
│ categoria           │
│ logo_url            │
│ attivo              │
│ data_adesione       │
└─────────────────────┘
         │
         │
┌────────▼──────────────┐
│   RAPPRESENTANTI      │
├───────────────────────┤
│ id                    │
│ user_id*              │ → users.id
│ nome_zona             │
│ provincia             │
│ num_esercenti         │
│ data_nomina           │
└───────────────────────┘


┌─────────────────────┐
│      EVENTI         │
├─────────────────────┤
│ id                  │
│ rappresentante_id*  │ → rappresentanti.id
│ titolo              │
│ descrizione         │
│ data_inizio         │
│ data_fine           │
│ bonus_punti         │
│ codice_evento       │ (unico)
│ max_partecipanti    │
│ num_partecipanti    │
│ attivo              │
│ created_at          │
└─────────────────────┘
         │
         │
┌────────▼──────────────────┐
│ PARTECIPAZIONI_EVENTI     │
├───────────────────────────┤
│ id                        │
│ evento_id*                │ → eventi.id
│ user_id*                  │ → users.id
│ punti_ricevuti            │
│ data_partecipazione       │
└───────────────────────────┘
```

## 📋 Tabelle Dettagliate

### 1. users

Tabella principale utenti multiruolo.

```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    nome VARCHAR(100) NOT NULL,
    cognome VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    ruolo ENUM('cliente', 'esercente', 'rappresentante', 'centrale') NOT NULL DEFAULT 'cliente',
    email_verified_at TIMESTAMP NULL,
    otp_code VARCHAR(6) NULL,
    otp_expires_at TIMESTAMP NULL,
    attivo BOOLEAN DEFAULT TRUE,
    ultimo_accesso TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_ruolo (ruolo),
    INDEX idx_attivo (attivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Campi Chiave:**
- `ruolo`: determina le funzionalità accessibili
- `email_verified_at`: NULL = email non verificata
- `otp_code`: codice temporaneo per verifica email
- `attivo`: flag per disabilitare account senza eliminare

---

### 2. wallets

Portafoglio digitale punti per clienti ed esercenti.

```sql
CREATE TABLE wallets (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE NOT NULL,
    saldo_punti DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    punti_emessi DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    punti_incassati DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    ultimo_aggiornamento TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_saldo (saldo_punti)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Logica Campi:**
- `saldo_punti`: punti disponibili per il cliente / cassa per esercente
- `punti_emessi`: solo per esercenti - totale punti regalati
- `punti_incassati`: solo per esercenti - totale punti accettati
- **Bilancio Esercente** = `punti_incassati - punti_emessi`

---

### 3. transazioni

Log completo di tutte le movimentazioni punti.

```sql
CREATE TABLE transazioni (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    mittente_id BIGINT UNSIGNED NULL,
    destinatario_id BIGINT UNSIGNED NOT NULL,
    punti DECIMAL(10, 2) NOT NULL,
    importo_euro DECIMAL(10, 2) NULL,
    tipo ENUM(
        'assegnazione',
        'pagamento',
        'bonus_benvenuto',
        'bonus_evento',
        'rimborso',
        'scadenza'
    ) NOT NULL,
    esercente_origine_id BIGINT UNSIGNED NULL,
    descrizione TEXT NULL,
    metadata JSON NULL,
    ip_address VARCHAR(45) NULL,
    user_agent TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (mittente_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (destinatario_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (esercente_origine_id) REFERENCES users(id) ON DELETE SET NULL,
    
    INDEX idx_mittente (mittente_id),
    INDEX idx_destinatario (destinatario_id),
    INDEX idx_tipo (tipo),
    INDEX idx_created_at (created_at),
    INDEX idx_esercente_origine (esercente_origine_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Tipi Transazione:**
- `assegnazione`: Esercente → Cliente (acquisto)
- `pagamento`: Cliente → Esercente (spesa punti)
- `bonus_benvenuto`: Sistema → Cliente (10 punti iniziali)
- `bonus_evento`: Sistema → Cliente (partecipazione evento)
- `rimborso`: Esercente → Cliente (annullamento)
- `scadenza`: Sistema (punti scaduti rimossi)

**Metadata JSON Esempi:**
```json
{
    "qr_code": "QR123456",
    "note": "Acquisto scarpe",
    "evento_id": 42
}
```

---

### 4. esercenti

Dati specifici dei negozi aderenti.

```sql
CREATE TABLE esercenti (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE NOT NULL,
    rappresentante_id BIGINT UNSIGNED NULL,
    nome_negozio VARCHAR(255) NOT NULL,
    partita_iva VARCHAR(20) UNIQUE,
    indirizzo VARCHAR(255) NOT NULL,
    citta VARCHAR(100) NOT NULL,
    cap VARCHAR(10) NOT NULL,
    provincia VARCHAR(2) NOT NULL,
    telefono_negozio VARCHAR(20),
    categoria ENUM(
        'alimentari',
        'abbigliamento',
        'bar_ristoranti',
        'servizi',
        'salute_benessere',
        'casa_arredamento',
        'elettronica',
        'altro'
    ) NOT NULL,
    descrizione TEXT,
    orari_apertura JSON,
    logo_url VARCHAR(500),
    foto_negozio JSON,
    attivo BOOLEAN DEFAULT TRUE,
    data_adesione DATE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (rappresentante_id) REFERENCES rappresentanti(id) ON DELETE SET NULL,
    
    INDEX idx_user_id (user_id),
    INDEX idx_rappresentante (rappresentante_id),
    INDEX idx_citta (citta),
    INDEX idx_categoria (categoria),
    INDEX idx_attivo (attivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Orari Apertura JSON:**
```json
{
    "lunedi": "09:00-13:00, 15:00-19:00",
    "martedi": "09:00-13:00, 15:00-19:00",
    "mercoledi": "chiuso",
    "giovedi": "09:00-13:00, 15:00-19:00",
    "venerdi": "09:00-13:00, 15:00-19:00",
    "sabato": "09:00-13:00",
    "domenica": "chiuso"
}
```

---

### 5. rappresentanti

Coordinatori di zona.

```sql
CREATE TABLE rappresentanti (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED UNIQUE NOT NULL,
    nome_zona VARCHAR(255) NOT NULL,
    provincia VARCHAR(2) NOT NULL,
    comuni_coperti JSON,
    num_esercenti INT DEFAULT 0,
    num_clienti INT DEFAULT 0,
    data_nomina DATE NOT NULL,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    INDEX idx_user_id (user_id),
    INDEX idx_provincia (provincia)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 6. eventi

Eventi territoriali con bonus punti.

```sql
CREATE TABLE eventi (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    rappresentante_id BIGINT UNSIGNED NOT NULL,
    titolo VARCHAR(255) NOT NULL,
    descrizione TEXT,
    data_inizio DATETIME NOT NULL,
    data_fine DATETIME NOT NULL,
    bonus_punti DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    codice_evento VARCHAR(20) UNIQUE NOT NULL,
    max_partecipanti INT NULL,
    num_partecipanti INT DEFAULT 0,
    immagine_url VARCHAR(500),
    luogo VARCHAR(255),
    attivo BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    FOREIGN KEY (rappresentante_id) REFERENCES rappresentanti(id) ON DELETE CASCADE,
    
    INDEX idx_rappresentante (rappresentante_id),
    INDEX idx_data_inizio (data_inizio),
    INDEX idx_codice (codice_evento),
    INDEX idx_attivo (attivo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### 7. partecipazioni_eventi

Traccia partecipazione clienti agli eventi.

```sql
CREATE TABLE partecipazioni_eventi (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    evento_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    punti_ricevuti DECIMAL(10, 2) NOT NULL,
    data_partecipazione TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (evento_id) REFERENCES eventi(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    
    UNIQUE KEY uq_evento_user (evento_id, user_id),
    INDEX idx_evento (evento_id),
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 🔐 Constraints e Vincoli

### Vincolo Blocco "Stesso Negozio"

Implementato a livello applicativo (non DB constraint):

```sql
-- Query verifica: Cliente può spendere nel Negozio X?
SELECT SUM(t.punti) as punti_ricevuti_da_x
FROM transazioni t
WHERE t.destinatario_id = :cliente_id
  AND t.tipo = 'assegnazione'
  AND t.mittente_id = :negozio_x_id;

-- Se punti_ricevuti_da_x > 0 → BLOCCO
```

### Vincolo Saldo Non Negativo

```sql
-- Trigger BEFORE UPDATE su wallets
DELIMITER $$
CREATE TRIGGER check_saldo_non_negativo
BEFORE UPDATE ON wallets
FOR EACH ROW
BEGIN
    IF NEW.saldo_punti < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Saldo punti non può essere negativo';
    END IF;
END$$
DELIMITER ;
```

---

## 📊 Indici di Performance

### Indici Critici per Performance

```sql
-- Accelera ricerca transazioni per cliente
CREATE INDEX idx_trans_dest_tipo_created 
ON transazioni(destinatario_id, tipo, created_at DESC);

-- Accelera calcolo bilancio esercente
CREATE INDEX idx_trans_mitt_tipo 
ON transazioni(mittente_id, tipo);

-- Accelera ricerca esercenti per zona
CREATE INDEX idx_esercenti_zona 
ON esercenti(citta, provincia, attivo);
```

---

## 🔄 Query Comuni Ottimizzate

### 1. Saldo Wallet Cliente
```sql
SELECT saldo_punti 
FROM wallets 
WHERE user_id = :cliente_id;
```

### 2. Bilancio Esercente
```sql
SELECT 
    punti_emessi,
    punti_incassati,
    (punti_incassati - punti_emessi) as saldo
FROM wallets
WHERE user_id = :esercente_id;
```

### 3. Storico Transazioni Cliente
```sql
SELECT 
    t.*,
    u_mitt.nome as mittente_nome,
    u_dest.nome as destinatario_nome
FROM transazioni t
LEFT JOIN users u_mitt ON t.mittente_id = u_mitt.id
LEFT JOIN users u_dest ON t.destinatario_id = u_dest.id
WHERE t.destinatario_id = :cliente_id 
   OR t.mittente_id = :cliente_id
ORDER BY t.created_at DESC
LIMIT 50;
```

### 4. Esercenti Zona con Bilancio
```sql
SELECT 
    e.nome_negozio,
    e.categoria,
    w.punti_emessi,
    w.punti_incassati,
    (w.punti_incassati - w.punti_emessi) as saldo
FROM esercenti e
INNER JOIN wallets w ON e.user_id = w.user_id
WHERE e.rappresentante_id = :rappresentante_id
  AND e.attivo = TRUE
ORDER BY saldo DESC;
```

### 5. Top Esercenti per Punti Incassati
```sql
SELECT 
    e.nome_negozio,
    e.citta,
    w.punti_incassati,
    COUNT(DISTINCT t.destinatario_id) as clienti_unici
FROM esercenti e
INNER JOIN wallets w ON e.user_id = w.user_id
LEFT JOIN transazioni t ON t.mittente_id = e.user_id 
    AND t.tipo = 'pagamento'
WHERE e.attivo = TRUE
GROUP BY e.id, e.nome_negozio, e.citta, w.punti_incassati
ORDER BY w.punti_incassati DESC
LIMIT 10;
```

---

## 🎯 Dati Seed per Testing

### User Centrale
```sql
INSERT INTO users (email, password, nome, cognome, ruolo, email_verified_at)
VALUES ('admin@rapresentante.it', '$2y$10$...', 'Admin', 'Centrale', 'centrale', NOW());
```

### Rappresentante Zona Milano
```sql
INSERT INTO users (email, password, nome, cognome, telefono, ruolo, email_verified_at)
VALUES ('rep.milano@rapresentante.it', '$2y$10$...', 'Marco', 'Rossi', '+393331234567', 'rappresentante', NOW());

INSERT INTO rappresentanti (user_id, nome_zona, provincia, data_nomina)
VALUES (LAST_INSERT_ID(), 'Milano Centro', 'MI', '2025-01-01');
```

### 3 Esercenti di Test
```sql
-- Esercente 1: Panificio
-- Esercente 2: Abbigliamento
-- Esercente 3: Ferramenta
```

### 10 Clienti di Test
```sql
-- Cliente 1-10 con 10 punti bonus benvenuto ciascuno
```

---

**Versione Schema:** 1.0  
**Ultimo Aggiornamento:** Gennaio 2025  
**Engine:** MySQL 8.0+

