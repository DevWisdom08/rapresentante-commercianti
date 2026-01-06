# 💻 Guida Sviluppo Locale - RAPRESENTANTE COMMERCIANTI

## 🎯 Obiettivo

Questa guida spiega come configurare l'ambiente di sviluppo sul tuo PC per lavorare al progetto.

---

## 📋 Prerequisiti Software

### Windows

- **PHP 8.1+**: [Download XAMPP](https://www.apachefriends.org/download.html) o [Laragon](https://laragon.org/download/)
- **Composer**: [Download](https://getcomposer.org/download/)
- **MySQL 8.0**: Incluso in XAMPP
- **Git**: [Download](https://git-scm.com/downloads)
- **Flutter**: [Download](https://docs.flutter.dev/get-started/install/windows)
- **Android Studio**: [Download](https://developer.android.com/studio) (per emulatore)
- **Visual Studio Code**: [Download](https://code.visualstudio.com/)

### macOS

```bash
# Installa Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa PHP
brew install php@8.2

# Installa Composer
brew install composer

# Installa MySQL
brew install mysql
brew services start mysql

# Installa Flutter
brew install --cask flutter

# Installa Android Studio
brew install --cask android-studio
```

### Linux (Ubuntu/Debian)

```bash
# Installa PHP
sudo apt install php8.2 php8.2-cli php8.2-fpm php8.2-mysql php8.2-xml \
  php8.2-mbstring php8.2-curl php8.2-zip php8.2-bcmath php8.2-gd

# Installa Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Installa MySQL
sudo apt install mysql-server
sudo mysql_secure_installation

# Installa Flutter
sudo snap install flutter --classic

# Installa Android Studio
sudo snap install android-studio --classic
```

---

## 🚀 Setup Progetto

### 1. Clona Repository

```bash
git clone https://github.com/tuoaccount/rapresentante.git
cd rapresentante
```

---

### 2. Setup Backend Laravel

```bash
cd backend

# Installa dipendenze
composer install

# Copia file environment
cp .env.example .env

# IMPORTANTE: Modifica .env con i tuoi dati
# Apri con editor di testo: nano .env  (Linux/Mac)
# Oppure:                  notepad .env  (Windows)
```

**Configurazione `.env` per sviluppo:**

```env
APP_NAME="Rapresentante Commercianti"
APP_ENV=local
APP_KEY=
APP_DEBUG=true
APP_URL=http://localhost:8000

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rapresentante_dev
DB_USERNAME=root
DB_PASSWORD=          # La tua password MySQL (vuoto se XAMPP)

QUEUE_CONNECTION=database

# Email (opzionale per sviluppo locale)
MAIL_MAILER=log      # Scrive email nei log invece di inviarle
```

```bash
# Genera chiave applicazione
php artisan key:generate

# Crea database
mysql -u root -p
```

**In MySQL:**
```sql
CREATE DATABASE rapresentante_dev CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EXIT;
```

```bash
# Esegui migrations (crea tabelle)
php artisan migrate

# Seed dati di test (opzionale)
php artisan db:seed

# Avvia server sviluppo
php artisan serve
```

**Backend ora disponibile su:** `http://localhost:8000`

---

### 3. Setup Frontend Flutter

**Nuovo terminale/tab:**

```bash
cd frontend

# Installa dipendenze
flutter pub get

# Controlla tutto OK
flutter doctor

# Se mancano licenze Android:
flutter doctor --android-licenses

# Avvia emulatore Android (o collega device fisico)
# In Android Studio: Tools → Device Manager → Play

# Avvia app
flutter run
```

**Selezione target:**
- `1`: Android emulator
- `2`: Browser (Chrome)
- `3`: Windows desktop (se abilitato)

---

## 🧪 Verifica Installazione

### Test Backend

```bash
# Test 1: Health check
curl http://localhost:8000/api/health

# Test 2: Registrazione utente
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

### Test Frontend

1. **Apri app Flutter**
2. **Schermata registrazione dovrebbe essere visibile**
3. **Prova registrazione con:**
   - Email: `test@test.it`
   - Password: `Test123!`
   - Nome: Mario
   - Cognome: Rossi

---

## 🗂️ Struttura Progetto

```
rapresentante/
├── backend/                 # Laravel API
│   ├── app/
│   │   ├── Http/
│   │   │   ├── Controllers/
│   │   │   │   ├── AuthController.php
│   │   │   │   ├── WalletController.php
│   │   │   │   ├── EsercenteController.php
│   │   │   │   ├── RappresentanteController.php
│   │   │   │   └── CentraleController.php
│   │   │   ├── Middleware/
│   │   │   │   └── CheckRole.php
│   │   │   └── Requests/
│   │   ├── Models/
│   │   │   ├── User.php
│   │   │   ├── Wallet.php
│   │   │   ├── Transazione.php
│   │   │   ├── Esercente.php
│   │   │   └── Evento.php
│   │   └── Services/
│   │       ├── WalletService.php
│   │       ├── TransazioneService.php
│   │       └── BloccoStessoNegozioService.php
│   ├── database/
│   │   ├── migrations/
│   │   └── seeders/
│   ├── routes/
│   │   └── api.php
│   └── tests/
│
├── frontend/                # Flutter App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   ├── api_config.dart
│   │   │   └── theme.dart
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── wallet.dart
│   │   │   └── transazione.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   └── wallet_service.dart
│   │   ├── screens/
│   │   │   ├── auth/
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── registrazione_screen.dart
│   │   │   ├── cliente/
│   │   │   │   ├── home_cliente.dart
│   │   │   │   └── wallet_page.dart
│   │   │   ├── esercente/
│   │   │   │   ├── home_esercente.dart
│   │   │   │   └── dashboard_esercente.dart
│   │   │   └── rappresentante/
│   │   │       └── dashboard_rappresentante.dart
│   │   ├── widgets/
│   │   │   ├── custom_button.dart
│   │   │   └── wallet_card.dart
│   │   └── utils/
│   │       └── validators.dart
│   ├── android/
│   ├── ios/
│   └── web/
│
└── docs/                    # Documentazione
    ├── ARCHITETTURA.md
    ├── DATABASE_SCHEMA.md
    ├── API_REFERENCE.md
    ├── GUIDA_DEPLOYMENT.md
    └── GUIDA_SVILUPPO.md
```

---

## 🔧 Workflow Sviluppo

### 1. Nuova Funzionalità Backend

```bash
# Crea controller
php artisan make:controller NomeFunzioneController

# Crea model
php artisan make:model NomeModello -m  # -m crea anche migration

# Crea migration
php artisan make:migration create_nome_tabella

# Esegui migration
php artisan migrate

# Crea seeder (dati test)
php artisan make:seeder NomeSeeder

# Test API con Postman o Insomnia
```

### 2. Nuova Funzionalità Frontend

```bash
# Crea nuova schermata
touch lib/screens/nuova_schermata.dart

# Crea widget riutilizzabile
touch lib/widgets/nuovo_widget.dart

# Hot reload automatico: salva file e vedi cambiamenti istantanei
# Se non funziona: premi 'r' nel terminale dove gira flutter run
# Per riavvio completo: premi 'R'
```

---

## 🐛 Debug

### Backend Laravel

#### Metodo 1: Log file
```bash
# Visualizza log in tempo reale
tail -f storage/logs/laravel.log
```

#### Metodo 2: Debug nel codice
```php
// Nel controller
use Illuminate\Support\Facades\Log;

Log::info('Debug info', ['variabile' => $data]);
dd($variabile);  // Dump and Die (ferma esecuzione e stampa)
```

#### Metodo 3: Laravel Telescope (Advanced)
```bash
composer require laravel/telescope --dev
php artisan telescope:install
php artisan migrate

# Accedi a: http://localhost:8000/telescope
```

---

### Frontend Flutter

#### Metodo 1: Print nel terminale
```dart
print('Debug: $variabile');
debugPrint('Messaggio debug');
```

#### Metodo 2: Flutter DevTools
```bash
# Avvia app in debug mode
flutter run

# Premi 'w' nel terminale per aprire DevTools
# Oppure: flutter pub global activate devtools
#         flutter pub global run devtools
```

#### Metodo 3: Breakpoint in VSCode
1. Clicca sulla linea di codice (pallino rosso)
2. Avvia debug con `F5`
3. Esegui passo-passo con `F10`

---

## 📦 Gestione Database

### Reset Completo Database

```bash
# Backend: droppa tutto e ricrea
php artisan migrate:fresh

# Con seed:
php artisan migrate:fresh --seed
```

### Aggiungere Nuova Colonna

```bash
# Crea migration
php artisan make:migration add_column_to_table

# In migration file:
public function up() {
    Schema::table('nome_tabella', function (Blueprint $table) {
        $table->string('nuova_colonna')->nullable();
    });
}

# Esegui
php artisan migrate
```

### Backup Database

```bash
# Export
mysqldump -u root -p rapresentante_dev > backup.sql

# Import
mysql -u root -p rapresentante_dev < backup.sql
```

---

## 🧪 Testing

### Backend Tests

```bash
# Esegui tutti i test
php artisan test

# Test specifico
php artisan test --filter=WalletTest

# Con coverage
php artisan test --coverage
```

**Esempio test:**
```php
// tests/Feature/WalletTest.php
public function test_cliente_riceve_bonus_benvenuto()
{
    $response = $this->postJson('/api/v1/auth/registrazione', [
        'email' => 'test@test.it',
        'password' => 'Test123!',
        'password_confirmation' => 'Test123!',
        'nome' => 'Test',
        'cognome' => 'User',
        'ruolo' => 'cliente'
    ]);

    $response->assertStatus(201);
    $this->assertDatabaseHas('wallets', [
        'saldo_punti' => 10.00  // Bonus benvenuto
    ]);
}
```

---

### Frontend Tests

```bash
# Test widget
flutter test

# Test integrazione
flutter test integration_test/

# Con coverage
flutter test --coverage
```

---

## 🎨 Styling e UI

### Backend: Non richiesto (API only)

### Frontend Flutter: Temi centralizzati

**File: `lib/config/theme.dart`**

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colori brand
  static const Color primario = Color(0xFF2563EB);      // Blu
  static const Color secondario = Color(0xFF10B981);    // Verde
  static const Color errore = Color(0xFFEF4444);        // Rosso
  
  static ThemeData get light {
    return ThemeData(
      primaryColor: primario,
      scaffoldBackgroundColor: Colors.grey[100],
      appBarTheme: AppBarTheme(
        backgroundColor: primario,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primario,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
```

---

## 📝 Convenzioni Codice

### Backend (Laravel)

- **Nomi Controller:** `PascalCase` + `Controller` (es: `WalletController`)
- **Nomi Model:** `PascalCase` singolare (es: `User`, `Transazione`)
- **Nomi Tabelle:** `snake_case` plurale (es: `users`, `transazioni`)
- **Nomi Metodi:** `camelCase` (es: `assegnaPunti()`)
- **Commenti:** Italiano
  ```php
  /**
   * Assegna punti da esercente a cliente
   * 
   * @param Request $request
   * @return JsonResponse
   */
  public function assegnaPunti(Request $request) { }
  ```

---

### Frontend (Flutter)

- **Nomi File:** `snake_case` (es: `home_cliente.dart`)
- **Nomi Classi:** `PascalCase` (es: `HomeClienteScreen`)
- **Nomi Variabili:** `camelCase` (es: `saldoPunti`)
- **Nomi Widget:** `PascalCase` (es: `WalletCard`)
- **Commenti:** Italiano
  ```dart
  /// Widget che mostra il saldo punti dell'utente
  class WalletCard extends StatelessWidget { }
  ```

---

## 🔄 Git Workflow

```bash
# Crea nuovo branch per funzionalità
git checkout -b feature/nome-funzionalita

# Fai modifiche e commit frequenti
git add .
git commit -m "feat: implementa assegnazione punti esercente"

# Push su repository
git push origin feature/nome-funzionalita

# Merge su main quando completo
git checkout main
git merge feature/nome-funzionalita
```

**Convenzioni commit:**
- `feat:` nuova funzionalità
- `fix:` correzione bug
- `docs:` modifiche documentazione
- `refactor:` refactoring codice
- `test:` aggiunta test

---

## 🚨 Problemi Comuni

### Backend non parte

```bash
# Verifica porta 8000 libera
netstat -ano | findstr :8000  # Windows
lsof -i :8000                 # Mac/Linux

# Se occupata, usa altra porta
php artisan serve --port=8001
```

### Errore "Class not found"

```bash
# Rigenera autoload
composer dump-autoload
```

### Migration fallisce

```bash
# Rollback ultima migration
php artisan migrate:rollback

# Correggi migration file, poi:
php artisan migrate
```

---

### Flutter non riconosce dispositivo

```bash
# Lista dispositivi
flutter devices

# Se emulatore non appare:
# Android Studio → Tools → Device Manager → Start emulator

# Riavvia Flutter
flutter clean
flutter pub get
flutter run
```

### Hot reload non funziona

```bash
# Nel terminale dove gira app, premi:
r  # hot reload
R  # hot restart

# O ferma e riavvia:
Ctrl+C
flutter run
```

---

## 📚 Risorse Utili

### Laravel
- Documentazione: https://laravel.com/docs
- Laracasts (video tutorial): https://laracasts.com
- Laravel News: https://laravel-news.com

### Flutter
- Documentazione: https://docs.flutter.dev
- Flutter Codelabs: https://flutter.dev/codelabs
- Pub.dev (pacchetti): https://pub.dev

### MySQL
- Documentazione: https://dev.mysql.com/doc
- PHPMyAdmin (GUI): incluso in XAMPP

---

## ✅ Checklist Setup Completo

**Software:**
- [ ] PHP 8.1+ installato (`php -v`)
- [ ] Composer installato (`composer -V`)
- [ ] MySQL installato e running
- [ ] Git installato (`git --version`)
- [ ] Flutter installato (`flutter --version`)
- [ ] Android Studio installato
- [ ] VSCode installato

**Progetto:**
- [ ] Repository clonato
- [ ] Backend: `composer install` completato
- [ ] Backend: `.env` configurato
- [ ] Backend: Database creato
- [ ] Backend: `php artisan migrate` completato
- [ ] Backend: Server avviato (`php artisan serve`)
- [ ] Frontend: `flutter pub get` completato
- [ ] Frontend: Emulatore avviato
- [ ] Frontend: App avviata (`flutter run`)

**Test Funzionalità:**
- [ ] Backend risponde su `http://localhost:8000`
- [ ] Registrazione utente funziona (via Postman o app)
- [ ] Login funziona
- [ ] Wallet punti visibile
- [ ] App Flutter si connette correttamente al backend

---

**Tempo Setup:** 1-2 ore (prima volta)  
**Difficoltà:** Media  

---

## 📞 Supporto Sviluppo

Se incontri problemi:
1. Controlla log: `storage/logs/laravel.log` (backend)
2. Leggi errori nel terminale (frontend)
3. Verifica `.env` configurato correttamente
4. Verifica database creato e migrations eseguite
5. Prova `composer dump-autoload` (backend) o `flutter clean` (frontend)

---

**Versione Guida:** 1.0  
**Ultimo Aggiornamento:** Gennaio 2025  
**Sistema Testato:** Windows 11, macOS 14, Ubuntu 22.04

