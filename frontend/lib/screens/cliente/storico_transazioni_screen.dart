import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/wallet_service.dart';
import '../../models/transazione.dart';

/// Storico Transazioni Cliente
class StoricoTransazioniScreen extends StatefulWidget {
  const StoricoTransazioniScreen({super.key});

  @override
  State<StoricoTransazioniScreen> createState() => _StoricoTransazioniScreenState();
}

class _StoricoTransazioniScreenState extends State<StoricoTransazioniScreen> {
  final _walletService = WalletService();
  final _scrollController = ScrollController();
  
  List<Transazione> _transazioni = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadTransazioni();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.9) {
      if (!_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  Future<void> _loadTransazioni() async {
    setState(() => _isLoading = true);

    try {
      final result = await _walletService.getTransazioni(page: 1);
      setState(() {
        _transazioni = result['transazioni'];
        _currentPage = result['current_page'];
        _hasMore = _currentPage < result['last_page'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);

    try {
      final result = await _walletService.getTransazioni(page: _currentPage + 1);
      setState(() {
        _transazioni.addAll(result['transazioni']);
        _currentPage = result['current_page'];
        _hasMore = _currentPage < result['last_page'];
      });
    } catch (e) {
      // Ignora errori caricamento
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storico Transazioni'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transazioni.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.grigio300),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Nessuna transazione',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: _transazioni.length + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _transazioni.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppTheme.spacingM),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final transazione = _transazioni[index];
                    return _buildTransazioneTile(transazione);
                  },
                ),
    );
  }

  Widget _buildTransazioneTile(Transazione transazione) {
    final isEntrata = transazione.isEntrata;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isEntrata 
              ? AppTheme.success.withOpacity(0.2)
              : AppTheme.errore.withOpacity(0.2),
          child: Icon(
            isEntrata ? Icons.add : Icons.remove,
            color: isEntrata ? AppTheme.success : AppTheme.errore,
          ),
        ),
        title: Text(
          transazione.tipoDescrizione,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (transazione.mittente != null)
              Text('Da: ${transazione.mittente!.nomeVisualizzato}'),
            if (transazione.destinatario != null)
              Text('A: ${transazione.destinatario!.nomeVisualizzato}'),
            if (transazione.descrizione != null)
              Text(transazione.descrizione!),
            const SizedBox(height: 4),
            Text(
              dateFormat.format(transazione.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.grigio500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isEntrata ? '+' : '-'}${transazione.punti.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEntrata ? AppTheme.success : AppTheme.errore,
              ),
            ),
            const Text('punti', style: TextStyle(fontSize: 11)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}

