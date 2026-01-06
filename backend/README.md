# 🔧 Backend Laravel - RAPRESENTANTE COMMERCIANTI

## 📋 Installazione

### Prerequisiti
- PHP 8.1 o superiore
- Composer
- MySQL 8.0 o superiore
- Estensioni PHP: OpenSSL, PDO, Mbstring, Tokenizer, XML, BCMath

### Setup

```bash
# Installa dipendenze
composer install

# Copia file environment
cp .env.example .env

# Genera chiave applicazione
php artisan key:generate

# Genera chiave JWT
php artisan jwt:secret

# Crea database
mysql -u root -p
CREATE DATABASE rapresentante_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;

# Esegui migrations
php artisan migrate

# Seed dati di test (opzionale)
php artisan db:seed

# Avvia server sviluppo
php artisan serve
```

Backend disponibile su: `http://localhost:8000`

## 🧪 Test API

```bash
# Health check
curl http://localhost:8000/api/health

# Registrazione utente test
curl -X POST http://localhost:8000/api/v1/auth/registrazione \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "password_confirmation": "Test123!",
    "nome": "Mario",
    "cognome": "Rossi",
    "ruolo": "cliente"
  }'
```

## 📚 Documentazione

Consulta `/docs/API_REFERENCE.md` per la documentazione completa delle API.

## 🔐 Sicurezza

- JWT per autenticazione
- Password hashate con bcrypt
- Validazione input rigorosa
- Rate limiting attivo
- CORS configurato

## 📊 Struttura Database

Vedi `/docs/DATABASE_SCHEMA.md` per lo schema completo.

## 🚀 Deploy Produzione

Vedi `/docs/GUIDA_DEPLOYMENT.md` per istruzioni deploy.

