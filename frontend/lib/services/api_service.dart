import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// Service per chiamate API HTTP
class ApiService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  /// Salva token autenticazione
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Ottieni token salvato
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Elimina token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// GET request
  Future<Map<String, dynamic>> get(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = requiresAuth
          ? await _headersWithAuth()
          : ApiConfig.headers;

      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: ApiConfig.timeout));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// POST request
  Future<Map<String, dynamic>> post(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = requiresAuth
          ? await _headersWithAuth()
          : ApiConfig.headers;

      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeout));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// PUT request
  Future<Map<String, dynamic>> put(String endpoint,
      {Map<String, dynamic>? body, bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = requiresAuth
          ? await _headersWithAuth()
          : ApiConfig.headers;

      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(Duration(seconds: ApiConfig.timeout));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String endpoint,
      {bool requiresAuth = true}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final headers = requiresAuth
          ? await _headersWithAuth()
          : ApiConfig.headers;

      final response = await http
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: ApiConfig.timeout));

      return _handleResponse(response);
    } catch (e) {
      return _handleError(e);
    }
  }

  /// Headers con token autenticazione
  Future<Map<String, String>> _headersWithAuth() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token non trovato. Effettua il login.');
    }
    return ApiConfig.headersWithToken(token);
  }

  /// Gestione risposta HTTP
  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body;
    final decoded = body.isNotEmpty ? jsonDecode(body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Successo
      return decoded;
    } else {
      // Errore dal server
      throw ApiException(
        statusCode: response.statusCode,
        message: decoded['message'] ?? 'Errore sconosciuto',
        errorCode: decoded['error'],
        data: decoded['data'],
      );
    }
  }

  /// Gestione errori
  Map<String, dynamic> _handleError(dynamic error) {
    // Errori di rete o timeout
    throw ApiException(
      statusCode: 0,
      message: 'Errore di connessione. Verifica la tua connessione internet.',
      errorCode: 'NETWORK_ERROR',
    );
  }
}

/// Eccezione personalizzata API
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;
  final dynamic data;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.data,
  });

  @override
  String toString() => message;

  /// Verifica se è errore di autenticazione
  bool get isAuthError => statusCode == 401;

  /// Verifica se è errore di validazione
  bool get isValidationError => statusCode == 422;

  /// Verifica se è errore di permessi
  bool get isForbiddenError => statusCode == 403;
}

