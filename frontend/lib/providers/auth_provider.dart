import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Provider per gestione stato autenticazione
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = true;
  String? _error;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get error => _error;

  /// Costruttore - carica utente se autenticato
  AuthProvider() {
    _loadUser();
  }

  /// Carica utente salvato
  Future<void> _loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authService.loadUser();
      _error = null;
    } catch (e) {
      _user = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Registrazione
  Future<Map<String, dynamic>> registrazione({
    required String email,
    required String password,
    required String passwordConfirmation,
    required String nome,
    required String cognome,
    String? telefono,
    String ruolo = 'cliente',
  }) async {
    _error = null;
    notifyListeners();

    try {
      final result = await _authService.registrazione(
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        nome: nome,
        cognome: cognome,
        telefono: telefono,
        ruolo: ruolo,
      );

      // Se registrazione diretta (con token), imposta user
      if (result.containsKey('user')) {
        _user = User.fromJson(result['user']);
        _error = null;
      }

      return result;
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Verifica OTP
  Future<void> verificaOtp({
    required String email,
    required String otpCode,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.verificaOtp(
        email: email,
        otpCode: otpCode,
      );

      _user = result['user'];
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      _user = result['user'];
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      // Ignora errori logout
    } finally {
      // SEMPRE pulisci stato locale
      _user = null;
      _error = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reinvia OTP
  Future<void> reinviaOtp(String email) async {
    _error = null;
    notifyListeners();

    try {
      await _authService.reinviaOtp(email: email);
    } catch (e) {
      _error = _extractErrorMessage(e);
      notifyListeners();
      rethrow;
    }
  }

  /// Ricarica profilo utente
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    try {
      _user = await _authService.getProfilo();
      _error = null;
      notifyListeners();
    } catch (e) {
      if (e is ApiException && e.isAuthError) {
        // Token scaduto - logout
        await logout();
      }
    }
  }

  /// Pulisci errore
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Estrai messaggio errore leggibile
  String _extractErrorMessage(dynamic error) {
    if (error is ApiException) {
      return error.message;
    }
    return error.toString().replaceAll('Exception: ', '');
  }
}

