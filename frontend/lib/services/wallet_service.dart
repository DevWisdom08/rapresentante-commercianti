import '../models/wallet.dart';
import '../models/transazione.dart';
import '../config/api_config.dart';
import 'api_service.dart';

/// Service per gestione wallet e transazioni
class WalletService {
  final ApiService _apiService = ApiService();

  /// Ottieni wallet utente corrente
  Future<Wallet> getWallet() async {
    final response = await _apiService.get(ApiConfig.wallet);

    if (response['success'] == true) {
      return Wallet.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Errore caricamento wallet');
    }
  }

  /// Ottieni storico transazioni
  /// 
  /// Parameters:
  /// - page: numero pagina (default 1)
  /// - limit: elementi per pagina (default 20)
  /// - tipo: filtra per tipo (opzionale)
  Future<Map<String, dynamic>> getTransazioni({
    int page = 1,
    int limit = 20,
    String? tipo,
  }) async {
    String endpoint = '${ApiConfig.walletTransazioni}?page=$page&limit=$limit';
    if (tipo != null) {
      endpoint += '&tipo=$tipo';
    }

    final response = await _apiService.get(endpoint);

    if (response['success'] == true) {
      final data = response['data'];
      
      return {
        'current_page': data['current_page'],
        'total': data['total'],
        'per_page': data['per_page'],
        'last_page': data['last_page'],
        'transazioni': (data['data'] as List)
            .map((t) => Transazione.fromJson(t))
            .toList(),
      };
    } else {
      throw Exception(response['message'] ?? 'Errore caricamento transazioni');
    }
  }

  /// Ottieni dettaglio singola transazione
  Future<Transazione> getTransazione(int id) async {
    final response = await _apiService.get(
      '${ApiConfig.walletTransazioni}/$id',
    );

    if (response['success'] == true) {
      return Transazione.fromJson(response['data']);
    } else {
      throw Exception(response['message'] ?? 'Transazione non trovata');
    }
  }

  /// Ottieni statistiche wallet (solo esercenti)
  Future<Map<String, dynamic>> getStatistiche({int giorni = 30}) async {
    final response = await _apiService.get(
      '${ApiConfig.walletStatistiche}?giorni=$giorni',
    );

    if (response['success'] == true) {
      return response['data'];
    } else {
      throw Exception(response['message'] ?? 'Errore caricamento statistiche');
    }
  }
}

