import '../models/user.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service per autenticazione
class AuthService {
  final ApiService _apiService = ApiService();

  /// Registrazione nuovo utente
  /// 
  /// Returns: { 'user_id': int, 'email': string, 'otp_inviato': bool }
  Future<Map<String, dynamic>> registrazione({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String nome,
    required String cognome,
    String? telefono,
    String ruolo = 'cliente',
  }) async {
    final response = await _apiService.post(
      ApiConfig.authRegistrazione,
      body: {
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'nome': nome,
        'cognome': cognome,
        if (telefono != null) 'telefono': telefono,
        'ruolo': ruolo,
      },
      requiresAuth: false,
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['message'] ?? 'Errore registrazione');
    }
  }

  /// Verifica codice OTP
  /// 
  /// Returns: { 'access_token': string, 'user': User object }
  Future<Map<String, dynamic>> verificaOtp({
    required String email,
    required String otpCode,
  }) async {
    final response = await _apiService.post(
      ApiConfig.authVerificaOtp,
      body: {
        'email': email,
        'otp_code': otpCode,
      },
      requiresAuth: false,
    );

    if (response['success'] == true) {
      final data = response['data'];
      
      // Salva token
      await _apiService.saveToken(data['access_token']);

      return {
        'token': data['access_token'],
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception(response['message'] ?? 'OTP non valido');
    }
  }

  /// Login
  /// 
  /// Returns: { 'token': string, 'user': User object }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConfig.authLogin,
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );

    if (response['success'] == true) {
      final data = response['data'];
      
      // Salva token
      await _apiService.saveToken(data['access_token']);

      return {
        'token': data['access_token'],
        'user': User.fromJson(data['user']),
      };
    } else {
      throw Exception(response['message'] ?? 'Credenziali non valide');
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiService.post(ApiConfig.authLogout);
    } catch (e) {
      // Ignora errori logout (server potrebbe essere offline)
    } finally {
      // Elimina token locale sempre
      await _apiService.deleteToken();
    }
  }

  /// Ottieni profilo utente corrente
  Future<User> getProfilo() async {
    final response = await _apiService.get(ApiConfig.authProfilo);

    if (response['success'] == true) {
      return User.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Errore caricamento profilo');
    }
  }

  /// Reinvia OTP
  Future<void> reinviaOtp({required String email}) async {
    final response = await _apiService.post(
      ApiConfig.authReinviaOtp,
      body: {'email': email},
      requiresAuth: false,
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Errore invio OTP');
    }
  }

  /// Verifica se utente è autenticato (ha token salvato)
  Future<bool> isAuthenticated() async {
    final token = await _apiService.getToken();
    return token != null;
  }

  /// Carica utente se autenticato
  Future<User?> loadUser() async {
    try {
      if (await isAuthenticated()) {
        return await getProfilo();
      }
      return null;
    } catch (e) {
      // Token invalido o scaduto
      await _apiService.deleteToken();
      return null;
    }
  }
}

