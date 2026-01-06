# 🧪 Testing Instructions - RAPRESENTANTE COMMERCIANTI MVP

**Data:** 7 Gennaio 2025  
**Status:** Backend e Frontend Pronti per Test

---

## ✅ Setup Completato

### Backend Laravel
- ✅ Composer dependencies installate
- ✅ Database SQLite creato
- ✅ 7 tabelle migrate
- ✅ Dati di test seedati
- ✅ Server deve essere avviato manualmente

### Frontend Flutter
- ✅ Piattaforme generate (Android, iOS, Web, Windows)
- ✅ Dependencies installate
- ✅ App pronta per essere lanciata

---

## 🚀 Come Avviare per Testing

### Step 1: Avvia Backend (Terminal 1)

Apri PowerShell e run:

```powershell
cd C:\Users\Koala\Music\Italy\backend
C:\xampp\php\php.exe artisan serve
```

Dovresti vedere:
```
INFO  Server running on [http://127.0.0.1:8000]
```

**✅ Test Backend:** Apri browser → http://localhost:8000/api/health

Dovresti vedere:
```json
{
  "status": "OK",
  "service": "Rapresentante Commercianti API",
  "version": "1.0.0"
}
```

**IMPORTANTE: Lascia questo terminale aperto!**

---

### Step 2: Avvia Frontend (Terminal 2)

Apri NUOVO PowerShell e run:

```powershell
cd C:\Users\Koala\Music\Italy\frontend
flutter run -d chrome
```

Oppure per Android emulator:
```powershell
flutter run -d emulator-5554
```

L'app si aprirà in Chrome (o emulatore) dopo 30-60 secondi.

---

## 🧪 Flow di Test Completo

### Test 1: Registrazione Nuovo Cliente

1. **App si apre con schermata Login**
2. Click "**Non hai un account? Registrati**"
3. Compila form:
   - Tipo account: **Cliente**
   - Nome: **Test**
   - Cognome: **Utente**
   - Email: **test.cliente@test.it**
   - Password: **Test1234!**
   - Conferma: **Test1234!**
4. Click "**REGISTRATI**"

5. **Vai al terminal del backend** (dove gira `php artisan serve`)
   - Cerca nel log: `local.INFO: OTP per test.cliente@test.it: 123456`
   - Copia il codice OTP (6 cifre)

6. **Torna all'app** → Inserisci il codice OTP → Click "**VERIFICA**"

7. **✅ Dovresti vedere:**
   - Dashboard Cliente
   - Benvenuto, Test Utente
   - Saldo Punti: **10.00** (bonus benvenuto)
   - 1 punto = 1 euro di sconto

---

### Test 2: Login Cliente Esistente

1. Se sei loggato, fai **Logout**
2. Schermata Login, inserisci:
   - Email: **mario.rossi@test.it**
   - Password: **Password123!**
3. Click "**ACCEDI**"

4. **✅ Dovresti vedere:**
   - Dashboard Cliente
   - Benvenuto, Mario Rossi
   - Saldo Punti (variabile, ha già transazioni)

---

### Test 3: Login Esercente

1. Logout
2. Login con:
   - Email: **panificio@test.it**
   - Password: **Password123!**
3. Click "ACCEDI"

4. **✅ Dovresti vedere:**
   - Dashboard Esercente (placeholder)
   - Benvenuto Esercente
   - Messaggio "Dashboard in sviluppo"

---

### Test 4: Login Rappresentante

1. Logout
2. Login con:
   - Email: **rappresentante.milano@rapresentante.it**
   - Password: **Password123!**
3. Click "ACCEDI"

4. **✅ Dovresti vedere:**
   - Dashboard Rappresentante (placeholder)

---

### Test 5: Login Admin Centrale

1. Logout
2. Login con:
   - Email: **admin@rapresentante.it**
   - Password: **Password123!**
3. Click "ACCEDI"

4. **✅ Dovresti vedere:**
   - Dashboard Centrale (placeholder)

---

## 🔑 Credenziali di Test Complete

**CLIENTE (con bonus benvenuto):**
```
mario.rossi@test.it / Password123!
laura.bianchi@test.it / Password123!
paolo.verdi@test.it / Password123!
```

**ESERCENTE:**
```
panificio@test.it / Password123!
abbigliamento@test.it / Password123!
ferramenta@test.it / Password123!
```

**RAPPRESENTANTE:**
```
rappresentante.milano@rapresentante.it / Password123!
```

**ADMIN:**
```
admin@rapresentante.it / Password123!
```

---

## ✅ Cosa Testare

### Autenticazione ✅
- [x] Registrazione nuovo utente
- [x] Verifica OTP
- [x] Login con credenziali esistenti
- [x] Logout
- [x] Routing automatico basato su ruolo

### Dashboard Cliente ✅
- [x] Visualizzazione saldo punti
- [x] Bonus benvenuto (10 punti)
- [x] UI responsive
- [ ] Storico transazioni (placeholder)
- [ ] Lista esercenti (placeholder)

### Dashboard Esercente 🚧
- [x] Placeholder funzionante
- [ ] Assegnazione punti (da implementare)
- [ ] Accettazione punti (da implementare)
- [ ] Statistiche (da implementare)

### Dashboard Rappresentante 🚧
- [x] Placeholder funzionante
- [ ] KPI zona (da implementare)
- [ ] Gestione eventi (da implementare)

### Dashboard Centrale 🚧
- [x] Placeholder funzionante
- [ ] Gestione utenti (da implementare)
- [ ] Configurazioni (da implementare)

---

## 🐛 Risoluzione Problemi

### Backend non risponde

```powershell
# Verifica se server è in running
http://localhost:8000/api/health

# Se non funziona, riavvia:
# Ctrl+C nel terminal backend
php artisan serve
```

### Frontend non si connette

1. **Verifica backend running**
2. **Controlla URL in `lib/config/api_config.dart`:**
   - Per Chrome: deve essere `http://localhost:8000/api/v1`
   - Per Android: deve essere `http://10.0.2.2:8000/api/v1`

3. **Riavvia Flutter:**
   - Nel terminal Flutter, premi `R` per hot restart

### Errore CORS

Nel terminal backend dovresti vedere errori CORS. Se succede:
```powershell
# Ctrl+C per fermare
php artisan config:clear
php artisan serve
```

---

## 📊 Log e Debug

### Backend Logs
- **Terminal output:** Vedi richieste API in tempo reale
- **Log file:** `backend/storage/logs/laravel.log`

### Flutter Logs
- **Terminal output:** Errori e debug prints
- **DevTools:** Premi `w` nel terminal Flutter

---

## 🎯 Obiettivo Test

**Verificare che funzioni:**
1. ✅ Registrazione con OTP
2. ✅ Login multi-ruolo
3. ✅ Routing automatico per ruolo
4. ✅ Visualizzazione wallet punti
5. ✅ Backend API risponde correttamente

**Stato Atteso:** MVP funzionante al 85%

---

## 📞 Prossimi Step

Dopo il test:
1. **Video demo** per il cliente
2. **Completamento UI** dashboard avanzate
3. **Build APK** Android
4. **Deploy** su server produzione

---

**Ready to Test!** 🚀

Apri i due terminali come descritto sopra e inizia il testing!

