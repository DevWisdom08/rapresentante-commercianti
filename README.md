# 🏪 RAPRESENTANTE COMMERCIANTI - Sistema Fedeltà Circolare

## 📋 Descrizione Progetto

Sistema di fedeltà circolare per commercianti locali che combatte la concorrenza di Amazon attraverso il **commercio di prossimità**.

### 💡 Concetto Chiave

**I punti guadagnati in un negozio possono essere spesi SOLO negli altri negozi della zona.**

- **1 Punto = 1 Euro**
- Ogni commerciante destina uno sconto ai clienti, utilizzabile solo presso altri commercianti
- Sistema di pubblicità reciproca tra negozi vicini

## 🎯 Obiettivo MVP

Piattaforma digitale per testare un sistema di scambio circolare di punti tra esercenti, con:
- Generazione nuovi clienti per gli esercenti
- Incentivazione partecipazione eventi territoriali
- Raccolta dati misurabili sui flussi commerciali locali

**Durata MVP: 90 giorni**

## 👥 Ruoli Utente

1. **Cliente Finale** - Accumula e spende punti
2. **Esercente** - Assegna e accetta punti
3. **Rappresentante Zona** - Coordina esercenti di una zona
4. **Centrale** - Amministrazione completa del sistema

## 🏗️ Architettura

```
├── backend/          # Laravel API
├── frontend/         # Flutter (iOS/Android/Web)
└── docs/            # Documentazione italiana
```

### Stack Tecnologico

- **Backend:** Laravel (PHP) + MySQL
- **Frontend:** Flutter (multipiattaforma)
- **Deploy:** Hetzner / DigitalOcean
- **Pagamenti:** Stripe (fase futura)

## ✨ Funzionalità Principali

### Cliente
- ✅ Registrazione con email + OTP
- ✅ Wallet punti digitale
- ✅ Bonus benvenuto (10 punti)
- ✅ Storico movimenti
- ✅ Blocco automatico utilizzo nello stesso negozio

### Esercente
- ✅ Assegnazione punti (manuale/QR)
- ✅ Accettazione punti da altri esercenti
- ✅ Dashboard bilancio (emessi/incassati/saldo)
- ✅ Gestione promozioni

### Rappresentante Zona
- ✅ Dashboard KPI zona
- ✅ Gestione eventi con bonus punti
- ✅ Report flussi clienti

### Centrale
- ✅ Dashboard globale
- ✅ Configurazione regole sistema
- ✅ Report CSV esportabili
- ✅ Controllo totale utenti e transazioni

## 🔐 Regola Fondamentale (Hard-Coded)

**I punti NON possono essere spesi nello stesso esercente dove sono stati generati.**

Questo previene:
- ❌ Sconti auto-generati
- ❌ Dumping
- ❌ Abusi del sistema

## 📊 Schema Contabile

### Per l'Esercente:
- **Punti Emessi**: quando assegna punti (azione neutra)
- **Punti Incassati**: quando accetta punti (costo reale = acquisizione cliente)
- **Saldo**: Incassati - Emessi (indicatore performance marketing)

### Esempio:
```
Cliente spende 50€ nel Negozio A → riceve 50 punti
Cliente spende 50 punti nel Negozio B

Negozio A: +50 emessi, 0€ costo
Negozio B: +50 incassati, -50€ sconto (= investimento marketing)
Cliente: 50€ di sconto reale ricevuto
```

## 🚀 Roadmap MVP

### Fase 1: Sviluppo Locale (Giorni 1-7)
- Backend Laravel completo
- Frontend Flutter multipiattaforma
- Testing integrazione
- Video demo progressivi

### Fase 2: Deploy Demo (Giorno 8)
- Deploy su DigitalOcean/Hetzner
- URL accessibile da browser (PWA)
- APK Android scaricabile
- Testing funzionale

### Fase 3: Test Reale (Giorni 9-14)
- Test con 2-3 esercenti reali
- Correzioni e ottimizzazioni
- Demo con clienti
- Build TestFlight iOS

## 📦 Installazione

### Requisiti
- PHP 8.1+
- Composer
- MySQL 8.0+
- Flutter 3.0+
- Node.js 18+ (per tools)

### Setup Backend
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

### Setup Frontend
```bash
cd frontend
flutter pub get
flutter run
```

Documentazione completa in `/docs`

## 📈 KPI da Misurare

- % punti spesi vs emessi
- Clienti che visitano 2+ negozi
- Nuovi clienti per esercente
- Partecipazione eventi
- Saldo medio per esercente

## 🔒 Sicurezza

- Autenticazione JWT multi-ruolo
- Validazione backend rigorosa
- Blocco tecnico "stesso negozio"
- Log completo di tutte le transazioni
- Rate limiting API

## 📝 Licenza

Proprietario - Tutti i diritti riservati

## 👨‍💻 Sviluppo

**Codice e documentazione 100% in italiano**

Sviluppato da Domenico per test di mercato commercio di prossimità.

---

**Versione:** 1.0.0-MVP  
**Data Inizio:** Gennaio 2025  
**Status:** 🚧 In Sviluppo

