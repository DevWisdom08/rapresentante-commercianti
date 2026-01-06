/// Configurazione API endpoints
class ApiConfig {
  // ==========================================
  // IMPORTANTE: Modifica questo URL quando fai il deploy!
  // ==========================================
  
  /// Base URL backend API
  /// 
  /// SVILUPPO LOCALE:
  /// - Android Emulator: 'http://10.0.2.2:8000/api/v1'
  /// - iOS Simulator: 'http://localhost:8000/api/v1'
  /// - Browser: 'http://localhost:8000/api/v1'
  /// 
  /// PRODUZIONE:
  /// - 'https://tuo-server.com/api/v1'
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  /// Timeout richieste HTTP (secondi)
  static const int timeout = 30;

  /// Versione app
  static const String version = '1.0.0';

  /// Endpoints
  static const String health = '/health';

  // Auth
  static const String authRegistrazione = '/auth/registrazione';
  static const String authVerificaOtp = '/auth/verifica-otp';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authProfilo = '/auth/profilo';
  static const String authReinviaOtp = '/auth/reinvia-otp';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTransazioni = '/wallet/transazioni';
  static const String walletStatistiche = '/wallet/statistiche';

  // Esercente
  static const String esercenteAssegnaPunti = '/esercente/assegna-punti';
  static const String esercenteAccettaPunti = '/esercente/accetta-punti';
  static const String esercenteDashboard = '/esercente/dashboard';
  static const String esercenteVerificaCliente = '/esercente/verifica-cliente';
  static const String esercenteListaZona = '/esercente/lista-zona';

  // Rappresentante
  static const String rappresentanteDashboard = '/rappresentante/dashboard';
  static const String rappresentanteEsercenti = '/rappresentante/esercenti';
  static const String rappresentanteEventi = '/rappresentante/eventi';
  static const String rappresentanteReportExport = '/rappresentante/report/export';

  // Eventi
  static const String eventi = '/eventi';
  static String eventoPartecipa(int id) => '/eventi/$id/partecipa';

  // Centrale
  static const String centraleDashboard = '/centrale/dashboard';
  static const String centraleUtenti = '/centrale/utenti';
  static const String centraleReport = '/centrale/report';
  static const String centraleConfigurazioni = '/centrale/configurazioni';
  static String centraleAttivaUtente(int id) => '/centrale/utenti/$id/attiva';
  static String centraleDisattivaUtente(int id) => '/centrale/utenti/$id/disattiva';
  static String centraleEliminaUtente(int id) => '/centrale/utenti/$id';

  /// Headers comuni
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers con token autenticazione
  static Map<String, String> headersWithToken(String token) => {
    ...headers,
    'Authorization': 'Bearer $token',
  };
}

