import 'package:flutter/foundation.dart';
import '../models/wallet.dart';
import '../models/transazione.dart';
import '../services/wallet_service.dart';

/// Provider per gestione stato wallet
class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();

  Wallet? _wallet;
  List<Transazione> _transazioni = [];
  bool _isLoading = false;
  bool _isLoadingTransazioni = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Getters
  Wallet? get wallet => _wallet;
  List<Transazione> get transazioni => _transazioni;
  bool get isLoading => _isLoading;
  bool get isLoadingTransazioni => _isLoadingTransazioni;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;

  /// Carica wallet
  Future<void> loadWallet() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wallet = await _walletService.getWallet();
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _wallet = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carica transazioni (prima pagina)
  Future<void> loadTransazioni({String? tipo}) async {
    _isLoadingTransazioni = true;
    _error = null;
    _currentPage = 1;
    notifyListeners();

    try {
      final result = await _walletService.getTransazioni(
        page: _currentPage,
        tipo: tipo,
      );

      _transazioni = result['transazioni'];
      _totalPages = result['last_page'];
      _hasMore = _currentPage < _totalPages;
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _transazioni = [];
    } finally {
      _isLoadingTransazioni = false;
      notifyListeners();
    }
  }

  /// Carica più transazioni (paginazione)
  Future<void> loadMoreTransazioni({String? tipo}) async {
    if (!_hasMore || _isLoadingTransazioni) return;

    _isLoadingTransazioni = true;
    notifyListeners();

    try {
      _currentPage++;
      
      final result = await _walletService.getTransazioni(
        page: _currentPage,
        tipo: tipo,
      );

      _transazioni.addAll(result['transazioni']);
      _totalPages = result['last_page'];
      _hasMore = _currentPage < _totalPages;
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _currentPage--; // Ripristina pagina precedente
    } finally {
      _isLoadingTransazioni = false;
      notifyListeners();
    }
  }

  /// Ricarica wallet e transazioni
  Future<void> refresh() async {
    await Future.wait([
      loadWallet(),
      loadTransazioni(),
    ]);
  }

  /// Pulisci dati (logout)
  void clear() {
    _wallet = null;
    _transazioni = [];
    _currentPage = 1;
    _totalPages = 1;
    _hasMore = true;
    _error = null;
    _isLoading = false;
    _isLoadingTransazioni = false;
    notifyListeners();
  }

  /// Pulisci errore
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Estrai messaggio errore leggibile
  String _extractErrorMessage(dynamic error) {
    return error.toString().replaceAll('Exception: ', '');
  }

  /// Aggiorna saldo wallet manualmente (dopo transazione)
  void updateSaldo(double nuovoSaldo) {
    if (_wallet != null) {
      _wallet = _wallet!.copyWith(saldoPunti: nuovoSaldo);
      notifyListeners();
    }
  }

  /// Aggiungi transazione in cima alla lista (dopo creazione)
  void addTransazione(Transazione transazione) {
    _transazioni.insert(0, transazione);
    notifyListeners();
  }
}

