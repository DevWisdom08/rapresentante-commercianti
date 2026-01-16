import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Vista Promozioni per Cliente
class PromozioniClienteScreen extends StatefulWidget {
  const PromozioniClienteScreen({super.key});

  @override
  State<PromozioniClienteScreen> createState() => _PromozioniClienteScreenState();
}

class _PromozioniClienteScreenState extends State<PromozioniClienteScreen> {
  final _apiService = ApiService();
  List<Map<String, dynamic>> _promozioni = [];
  String _ordinamento = 'nome'; // nome, percentuale, categoria
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromozioni();
  }

  Future<void> _loadPromozioni() async {
    setState(() => _isLoading = true);

    // Mock data per ora - da collegare con API
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _promozioni = [
        {
          'esercente': 'Panificio del Centro',
          'categoria': 'Alimentari',
          'tipo': '25% pagabile con P/M',
          'sconto_percentuale': 25,
          'descrizione': 'Sconto su tutti i prodotti da forno',
          'valido_fino': '31/01/2026',
        },
        {
          'esercente': 'Abbigliamento Moda',
          'categoria': 'Abbigliamento',
          'tipo': 'Sconto 30%',
          'sconto_percentuale': 30,
          'descrizione': 'Collezione invernale',
          'valido_fino': '15/02/2026',
        },
        {
          'esercente': 'Bar Centrale',
          'categoria': 'Bevande',
          'tipo': 'Primi clienti 40%',
          'sconto_percentuale': 40,
          'descrizione': 'Doppio sconto per nuovi clienti!',
          'valido_fino': '28/02/2026',
          'is_primi_clienti': true,
        },
      ];
      _isLoading = false;
    });

    _ordinaPromozioni();
  }

  void _ordinaPromozioni() {
    setState(() {
      switch (_ordinamento) {
        case 'nome':
          _promozioni.sort((a, b) => a['esercente'].compareTo(b['esercente']));
          break;
        case 'sconto':
          _promozioni.sort((a, b) => b['sconto_percentuale'].compareTo(a['sconto_percentuale']));
          break;
        case 'categoria':
          _promozioni.sort((a, b) => a['categoria'].compareTo(b['categoria']));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promozioni Attive'),
      ),
      body: Column(
        children: [
          // Filtri ordinamento
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            color: AppTheme.grigio100,
            child: Row(
              children: [
                const Text('Ordina per:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'nome', label: Text('Nome')),
                      ButtonSegment(value: 'sconto', label: Text('% P/M')),
                      ButtonSegment(value: 'categoria', label: Text('Categoria')),
                    ],
                    selected: {_ordinamento},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _ordinamento = newSelection.first;
                        _ordinaPromozioni();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Lista promozioni
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    itemCount: _promozioni.length,
                    itemBuilder: (context, index) {
                      final promo = _promozioni[index];
                      return _buildPromoCard(promo);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final isPrimiClienti = promo['is_primi_clienti'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.local_offer, color: AppTheme.primario),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo['esercente'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        promo['categoria'],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grigio500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPrimiClienti 
                        ? AppTheme.warning.withOpacity(0.2)
                        : AppTheme.success.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${promo['sconto_percentuale']}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPrimiClienti ? AppTheme.warning : AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isPrimiClienti)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'DOPPIO SCONTO per primi clienti!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            
            if (isPrimiClienti) const SizedBox(height: 8),
            
            Text(
              promo['descrizione'],
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: AppTheme.grigio500),
                const SizedBox(width: 4),
                Text(
                  'Valido fino: ${promo['valido_fino']}',
                  style: TextStyle(fontSize: 12, color: AppTheme.grigio500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

