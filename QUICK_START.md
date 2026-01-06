# ⚡ Quick Start Guide - RAPRESENTANTE COMMERCIANTI

## 🎯 Avvio Rapido in 3 Step

### Step 1: Abilita Developer Mode (Una Volta Sola)

1. Premi `Windows + I` (apre Impostazioni)
2. Vai su **Update & Security** → **For Developers**
3. Abilita "**Developer Mode**"
4. Conferma e attendi che Windows installi i componenti

**Oppure** apri PowerShell come Admin e run:
```powershell
start ms-settings:developers
```

---

### Step 2: Avvia Backend (Terminal 1)

```powershell
cd C:\Users\Koala\Music\Italy\backend
C:\xampp\php\php.exe artisan serve
```

Attendi:
```
INFO  Server running on [http://127.0.0.1:8000]
```

**LASCIA APERTO!**

---

### Step 3: Avvia Flutter su Chrome (Terminal 2)

```powershell
cd C:\Users\Koala\Music\Italy\frontend
flutter run -d chrome --web-port=8080
```

Attendi 30-60 secondi. Chrome si aprirà automaticamente.

---

## 🧪 Test Login

**Email:** `mario.rossi@test.it`  
**Password:** `Password123!`

Click "ACCEDI" → Dovresti vedere Dashboard con Wallet Punti!

---

## 🔑 Tutte le Credenziali

**Clienti:**
- mario.rossi@test.it / Password123!
- laura.bianchi@test.it / Password123!

**Esercenti:**
- panificio@test.it / Password123!
- abbigliamento@test.it / Password123!

**Rappresentante:**
- rappresentante.milano@rapresentante.it / Password123!

**Admin:**
- admin@rapresentante.it / Password123!

---

## ✅ Cosa Funziona

- Login/Logout
- Registrazione con OTP
- Dashboard Cliente con wallet punti
- Multi-role routing
- Backend API completo

---

## 🚀 Prossimi Step

1. Testare tutte le credenziali
2. Registrare nuovo utente
3. Video demo per cliente
4. Push to GitHub

---

**Tutto pronto! Avvia i 2 terminali e inizia!** 🎉

