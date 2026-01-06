# 🚀 Guida Deployment - RAPRESENTANTE COMMERCIANTI

## 📋 Panoramica

Questa guida spiega come fare il deploy completo del sistema su DigitalOcean o Hetzner.

---

## 🎯 Opzione 1: Deploy su DigitalOcean (Raccomandato per MVP)

### Requisiti

- Account DigitalOcean
- Dominio registrato (opzionale per MVP, può usare IP)
- Client SSH (PuTTY su Windows, Terminal su Mac/Linux)

### Step 1: Crea Droplet

1. **Accedi a DigitalOcean** → Create → Droplets
2. **Scegli immagine:** Ubuntu 22.04 LTS x64
3. **Piano:** Basic - $6/mese
   - 1 vCPU
   - 1 GB RAM
   - 25 GB SSD
4. **Datacenter:** Amsterdam o Frankfurt (più vicino all'Italia)
5. **Autenticazione:** SSH Key o Password
6. **Nome droplet:** `rapresentante-mvp`
7. **Crea Droplet**

Annota l'**IP pubblico** (es: `167.99.123.45`)

---

### Step 2: Connessione SSH

```bash
ssh root@167.99.123.45
```

---

### Step 3: Setup Iniziale Server

```bash
# Aggiorna sistema
apt update && apt upgrade -y

# Crea utente non-root
adduser domenico
usermod -aG sudo domenico

# Configura firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# Logout e riconnetti con nuovo utente
exit
ssh domenico@167.99.123.45
```

---

### Step 4: Installa Software Stack

```bash
# Installa Nginx
sudo apt install nginx -y

# Installa PHP 8.2
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install php8.2-fpm php8.2-mysql php8.2-mbstring php8.2-xml \
  php8.2-bcmath php8.2-curl php8.2-gd php8.2-zip php8.2-cli -y

# Installa MySQL
sudo apt install mysql-server -y
sudo mysql_secure_installation

# Installa Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Installa Node.js (per build assets)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y

# Installa Git
sudo apt install git -y
```

---

### Step 5: Configura MySQL

```bash
# Accedi a MySQL
sudo mysql

# Crea database e utente
CREATE DATABASE rapresentante_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'rapresentante_user'@'localhost' IDENTIFIED BY 'password_sicura_qui';
GRANT ALL PRIVILEGES ON rapresentante_db.* TO 'rapresentante_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

---

### Step 6: Deploy Codice Backend

```bash
# Vai nella directory web
cd /var/www

# Clona repository (o carica via SFTP)
sudo git clone https://github.com/tuoaccount/rapresentante.git
cd rapresentante/backend

# Imposta permessi
sudo chown -R domenico:www-data /var/www/rapresentante
sudo chmod -R 775 storage bootstrap/cache

# Installa dipendenze
composer install --no-dev --optimize-autoloader

# Configura ambiente
cp .env.example .env
nano .env
```

**File `.env` configurazione:**

```env
APP_NAME="Rapresentante Commercianti"
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=http://167.99.123.45

LOG_CHANNEL=stack
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rapresentante_db
DB_USERNAME=rapresentante_user
DB_PASSWORD=password_sicura_qui

QUEUE_CONNECTION=database

MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=tuaemail@gmail.com
MAIL_PASSWORD=tuapasswordapp
MAIL_ENCRYPTION=tls
MAIL_FROM_ADDRESS=tuaemail@gmail.com
MAIL_FROM_NAME="Rapresentante Commercianti"
```

```bash
# Genera chiave applicazione
php artisan key:generate

# Esegui migrations
php artisan migrate --force

# Seed dati iniziali (opzionale)
php artisan db:seed --force

# Ottimizza
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

### Step 7: Configura Nginx

```bash
sudo nano /etc/nginx/sites-available/rapresentante
```

**Contenuto file:**

```nginx
server {
    listen 80;
    server_name 167.99.123.45;  # o tuo-dominio.it
    root /var/www/rapresentante/backend/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }

    client_max_body_size 20M;
}
```

```bash
# Abilita sito
sudo ln -s /etc/nginx/sites-available/rapresentante /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

### Step 8: Configura SSL (Opzionale ma Raccomandato)

```bash
# Installa Certbot
sudo apt install certbot python3-certbot-nginx -y

# Ottieni certificato (solo se hai dominio)
sudo certbot --nginx -d tuo-dominio.it -d www.tuo-dominio.it

# Rinnovo automatico è già configurato
```

---

### Step 9: Configura Supervisor (Queue Worker)

```bash
sudo apt install supervisor -y
sudo nano /etc/supervisor/conf.d/rapresentante-worker.conf
```

**Contenuto file:**

```ini
[program:rapresentante-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/rapresentante/backend/artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=domenico
numprocs=1
redirect_stderr=true
stdout_logfile=/var/www/rapresentante/backend/storage/logs/worker.log
```

```bash
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl start rapresentante-worker:*
```

---

### Step 10: Deploy Frontend Flutter Web

```bash
# Sul TUO PC locale (non server)
cd frontend
flutter build web --release

# Carica build su server
scp -r build/web/* domenico@167.99.123.45:/var/www/rapresentante-web/
```

**Configura Nginx per frontend:**

```bash
sudo nano /etc/nginx/sites-available/rapresentante-web
```

```nginx
server {
    listen 80;
    server_name app.tuo-dominio.it;  # o 167.99.123.45:8080
    root /var/www/rapresentante-web;

    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/json;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/rapresentante-web /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🎯 Opzione 2: Deploy su Hetzner

Processo identico a DigitalOcean, cambia solo la creazione server:

1. **Accedi a Hetzner Cloud Console**
2. **Crea progetto:** "Rapresentante MVP"
3. **Add Server:**
   - Location: Falkenstein (Germania)
   - Image: Ubuntu 22.04
   - Type: CX11 (€3.79/mese) o CX21 (€5.83/mese)
4. **SSH Key:** Aggiungi la tua chiave pubblica
5. **Create & Buy**

Poi segui gli stessi step da Step 2 in poi.

---

## 📱 Build App Native

### Android APK

```bash
# Sul TUO PC
cd frontend

# Configura URL API in lib/config/api_config.dart
# Sostituisci localhost con IP server

# Build APK
flutter build apk --release

# APK generato in:
# build/app/outputs/flutter-apk/app-release.apk

# Distribuisci via:
# - Link diretto download
# - Google Drive
# - Play Store (Internal Testing)
```

---

### iOS TestFlight (Richiede Mac)

```bash
# Su Mac
cd frontend

# Configura URL API

# Build iOS
flutter build ios --release

# Apri Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Seleziona "Any iOS Device" come target
# 2. Product → Archive
# 3. Distribute App → App Store Connect
# 4. Upload
# 5. In App Store Connect → TestFlight → aggiungi tester
```

---

## 🔧 Configurazione Flutter per Backend Remoto

**File: `frontend/lib/config/api_config.dart`**

```dart
class ApiConfig {
  // SVILUPPO LOCALE
  // static const String baseUrl = 'http://localhost:8000/api/v1';
  
  // PRODUZIONE
  static const String baseUrl = 'http://167.99.123.45/api/v1';
  
  static const int timeout = 30;
  static const String version = '1.0.0';
}
```

**Ricompila dopo ogni modifica!**

---

## 🧪 Testing Post-Deploy

### 1. Test API Backend

```bash
# Health check
curl http://167.99.123.45/api/health

# Registrazione test
curl -X POST http://167.99.123.45/api/v1/auth/registrazione \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "password_confirmation": "Test123!",
    "nome": "Test",
    "cognome": "User",
    "ruolo": "cliente"
  }'
```

### 2. Test Frontend Web

Apri browser: `http://167.99.123.45` (o dominio)

- [ ] Pagina carica correttamente
- [ ] Form registrazione funziona
- [ ] Login funziona
- [ ] Dashboard carica

### 3. Test App Mobile

- [ ] Installa APK su Android
- [ ] App si connette al backend
- [ ] Registrazione funziona
- [ ] Login funziona
- [ ] Wallet punti visualizzato

---

## 📊 Monitoring e Manutenzione

### Log Backend Laravel

```bash
# Log applicazione
tail -f /var/www/rapresentante/backend/storage/logs/laravel.log

# Log Nginx
sudo tail -f /var/log/nginx/error.log

# Log PHP-FPM
sudo tail -f /var/log/php8.2-fpm.log
```

### Comandi Manutenzione

```bash
# Pulisci cache
cd /var/www/rapresentante/backend
php artisan cache:clear
php artisan config:clear
php artisan route:clear

# Backup database
mysqldump -u rapresentante_user -p rapresentante_db > backup_$(date +%Y%m%d).sql

# Ripristina database
mysql -u rapresentante_user -p rapresentante_db < backup_20250107.sql
```

---

## 🔐 Security Checklist

- [ ] Firewall UFW attivo (solo porte 22, 80, 443)
- [ ] MySQL accessibile solo da localhost
- [ ] `.env` non esposto pubblicamente
- [ ] SSL/HTTPS attivo (se dominio disponibile)
- [ ] Password forti per DB e utenti
- [ ] Backup automatici configurati
- [ ] Log rotazione attiva

---

## 🚨 Troubleshooting Comuni

### Errore 502 Bad Gateway

```bash
# Controlla PHP-FPM
sudo systemctl status php8.2-fpm
sudo systemctl restart php8.2-fpm
```

### Errore 500 Server Error

```bash
# Controlla permessi
sudo chown -R domenico:www-data /var/www/rapresentante
sudo chmod -R 775 storage bootstrap/cache

# Controlla log
tail -100 storage/logs/laravel.log
```

### Database connection refused

```bash
# Verifica credenziali in .env
cat .env | grep DB_

# Verifica MySQL attivo
sudo systemctl status mysql

# Test connessione
php artisan tinker
>>> DB::connection()->getPdo();
```

### Flutter app non si connette

1. **Verifica URL in `api_config.dart`:**
   - Usa IP pubblico server (non localhost!)
   - Usa `http://` non `https://` (se non hai SSL)
   - Porta corretta (default 80)

2. **Controlla firewall server:**
   ```bash
   sudo ufw status
   ```

3. **Test da browser mobile:**
   Visita `http://IP-SERVER/api/health`

---

## 📈 Upgrade e Scalabilità Futura

### Quando serve upgrade?

- **> 1000 utenti attivi:** Passa a Droplet/Server 2GB RAM
- **> 10.000 transazioni/giorno:** Aggiungi Redis per cache
- **> 50 esercenti:** Considera load balancer

### Piano di Scaling

```
Fase 1 (MVP):       1 server monolitico  - $6/mese
Fase 2 (< 5K utenti): Server 2GB + Redis   - $12/mese
Fase 3 (< 50K):     Load Balancer + DB separato - $50/mese
Fase 4:             Microservizi su Kubernetes
```

---

## ✅ Checklist Deploy Completo

**Backend:**
- [ ] Server Ubuntu 22.04 creato
- [ ] Nginx installato e configurato
- [ ] PHP 8.2 installato
- [ ] MySQL installato e database creato
- [ ] Codice Laravel caricato
- [ ] `.env` configurato correttamente
- [ ] Migrations eseguite
- [ ] SSL configurato (opzionale)
- [ ] Supervisor worker attivo

**Frontend:**
- [ ] Flutter web build caricato
- [ ] Nginx configurato per servire frontend
- [ ] APK Android compilato e testato
- [ ] iOS build caricato su TestFlight (se richiesto)
- [ ] API endpoint configurato correttamente

**Testing:**
- [ ] Registrazione utente funziona
- [ ] Login funziona
- [ ] Wallet punti visibile
- [ ] Transazioni test completate
- [ ] Dashboard accessibili per ogni ruolo

---

**Tempo Stimato Deploy Completo:** 2-3 ore  
**Difficoltà:** Media  
**Costo MVP:** $6-10/mese

---

## 📞 Supporto

In caso di problemi durante il deploy, controlla:
1. Log server (`/var/log/nginx/error.log`)
2. Log Laravel (`storage/logs/laravel.log`)
3. Configurazione `.env`
4. Permessi file (`sudo chown` e `chmod`)

---

**Versione Guida:** 1.0  
**Ultimo Aggiornamento:** Gennaio 2025  
**Testato su:** Ubuntu 22.04 LTS

