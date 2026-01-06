# 📱 Frontend Flutter - RAPRESENTANTE COMMERCIANTI

## 🚀 Quick Start

### Prerequisiti
- Flutter SDK 3.0+
- Android Studio / Xcode
- Backend Laravel in esecuzione su `http://localhost:8000`

### Installazione

```bash
# Installa dipendenze
flutter pub get

# Avvia su emulatore Android
flutter run

# Avvia su browser (per test rapidi)
flutter run -d chrome

# Build APK per test
flutter build apk --release
```

## 📦 Struttura Progetto

```
frontend/lib/
├── main.dart                    # Entry point app
├── config/
│   ├── api_config.dart          # Configurazione API endpoints
│   └── theme.dart               # Tema Material 3
├── models/
│   ├── user.dart                # Model Utente
│   ├── wallet.dart              # Model Wallet
│   └── transazione.dart         # Model Transazione
├── services/
│   ├── api_service.dart         # HTTP client base
│   ├── auth_service.dart        # Autenticazione
│   └── wallet_service.dart      # Wallet e transazioni
├── providers/
│   ├── auth_provider.dart       # State management auth
│   └── wallet_provider.dart     # State management wallet
└── screens/
    ├── auth/                    # Schermate autenticazione
    │   ├── login_screen.dart
    │   ├── registrazione_screen.dart
    │   └── verifica_otp_screen.dart
    ├── cliente/
    │   └── home_cliente.dart    # Dashboard cliente
    ├── esercente/
    │   └── home_esercente.dart  # Dashboard esercente
    ├── rappresentante/
    │   └── dashboard_rappresentante.dart
    └── centrale/
        └── dashboard_centrale.dart
```

## ⚙️ Configurazione

### Modifica URL Backend

**File:** `lib/config/api_config.dart`

```dart
// Per Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

// Per iOS Simulator
static const String baseUrl = 'http://localhost:8000/api/v1';

// Per dispositivo fisico o produzione
static const String baseUrl = 'http://TUO-IP:8000/api/v1';
```

## 🧪 Testing

### Credenziali di Test

Dopo aver eseguito il seeder sul backend:

**Cliente:**
- Email: `mario.rossi@test.it`
- Password: `Password123!`

**Esercente:**
- Email: `panificio@test.it`
- Password: `Password123!`

**Rappresentante:**
- Email: `rappresentante.milano@rapresentante.it`
- Password: `Password123!`

**Admin:**
- Email: `admin@rapresentante.it`
- Password: `Password123!`

## 📱 Build per Distribuzione

### Android APK

```bash
# Build release APK
flutter build apk --release

# APK generato in: build/app/outputs/flutter-apk/app-release.apk
```

### iOS (richiede macOS)

```bash
# Build iOS
flutter build ios --release

# Poi aprire Xcode per distribution
open ios/Runner.xcworkspace
```

## 🔧 Troubleshooting

### Errore di connessione al backend

1. Verifica che il backend Laravel sia in esecuzione:
   ```bash
   cd backend
   php artisan serve
   ```

2. Controlla URL in `api_config.dart`:
   - Android Emulator: `http://10.0.2.2:8000/api/v1`
   - iOS Simulator: `http://localhost:8000/api/v1`

3. Verifica firewall e permessi rete

### App non compila

```bash
# Pulisci build
flutter clean
flutter pub get
flutter run
```

### Hot reload non funziona

Nel terminale dove gira l'app:
- Premi `r` per hot reload
- Premi `R` per hot restart
- Premi `q` per quit

## 📚 Dipendenze

- **provider**: State management
- **http**: HTTP client
- **flutter_secure_storage**: Storage sicuro token
- **shared_preferences**: Storage locale
- **intl**: Formattazione date/numeri
- **qr_flutter**: Generazione QR codes
- **mobile_scanner**: Scansione QR

## 🎨 Tema e Colori

**Colori Principali:**
- Primario: `#2563EB` (Blu)
- Secondario: `#10B981` (Verde)
- Errore: `#EF4444` (Rosso)

Vedi `lib/config/theme.dart` per personalizzazioni.

## 🚀 Prossimi Step

### Funzionalità da Implementare:

**Cliente:**
- [ ] Lista esercenti zona
- [ ] Storico transazioni completo
- [ ] Partecipazione eventi
- [ ] QR Code wallet

**Esercente:**
- [ ] Assegnazione punti con QR
- [ ] Accettazione pagamenti punti
- [ ] Dashboard con statistiche
- [ ] Bilancio esercente

**Rappresentante:**
- [ ] KPI zona completi
- [ ] Gestione eventi
- [ ] Report esportabili

**Centrale:**
- [ ] Gestione utenti
- [ ] Configurazioni sistema
- [ ] Report globali

## 📞 Supporto

Per problemi o domande:
1. Controlla log Flutter: output terminale
2. Controlla log backend: `backend/storage/logs/laravel.log`
3. Verifica connessione API con Postman

---

**Versione:** 1.0.0-MVP  
**Flutter:** 3.0+  
**Stato:** 🚧 In Sviluppo - Base Funzionante

