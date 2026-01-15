import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'scanner_qr_screen.dart';

/// Transazione Unificata - Usa sconto e genera nuovi punti
class TransazioneUnificataScreen extends StatefulWidget {
  const TransazioneUnificataScreen({super.key});

  @override
  State<TransazioneUnificataScreen> createState() => _TransazioneUnificataScreenState();
}

class _TransazioneUnificataScreenState extends State<TransazioneUnificataScreen> {
  final _apiService = ApiService();
  
  int? _clienteId;
  String? _clienteNome;
  List<Map<String, dynamic>> _categorie = [];
  Map<String, dynamic>? _anteprima;
  bool _isLoading = false;

  void _aggiungiCategoria() {
    showDialog(
      context: context,
      builder: (context) => _CategoriaDialog(
        onSave: (nome, importo, percentuale) {
          setState(() {
            _categorie.add({
              'nome': nome,
              'importo': importo,
              'sconto_max_percentuale': percentuale,
            });
            _anteprima = null; // Reset anteprima
          });
        },
      ),
    );
  }

  Future<void> _scansionaCliente() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerQRScreen(),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _clienteId = result['cliente_id'];
        _clienteNome = result['cliente_email'];
        _anteprima = null;
      });
      
      if (_categorie.isNotEmpty) {
        _calcolaAnteprima();
      }
    }
  }

  Future<void> _calcolaAnteprima() async {
    if (_clienteId == null || _categorie.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        '/transazione/anteprima',
        body: {
          'cliente_id': _clienteId,
          'categorie': _categorie,
        },
      );

      if (response['success'] == true) {
        setState(() {
          _anteprima = response['data'];
        });
      }
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

  Future<void> _confermaTransazione() async {
    if (_clienteId == null || _categorie.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        '/transazione/unificata',
        body: {
          'cliente_id': _clienteId,
          'categorie': _categorie,
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final riepilogo = response['data']['riepilogo'];
        
        // Mostra riepilogo successo
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 12),
                const Text('Transazione Completata!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRiepilogoRow('Totale', '€${riepilogo['totale_acquisto']}'),
                _buildRiepilogoRow('Sconto', '-€${riepilogo['sconto_applicato']}'),
                Divider(),
                _buildRiepilogoRow(
                  'DA PAGARE',
                  '€${riepilogo['importo_da_pagare']}',
                  bold: true,
                ),
                Divider(),
                _buildRiepilogoRow(
                  'Nuovi punti cliente',
                  '+${riepilogo['nuovi_punti_generati']} punti',
                  color: AppTheme.success,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totale = _categorie.fold<double>(0, (sum, cat) => sum + cat['importo']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuova Transazione'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cliente
            Card(
              color: _clienteId != null ? AppTheme.success.withOpacity(0.1) : null,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _clienteId != null ? Icons.check_circle : Icons.person,
                          color: _clienteId != null ? AppTheme.success : AppTheme.grigio500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _clienteId != null ? 'Cliente: $_clienteNome' : 'Scansiona cliente',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (_clienteId != null)
                                Text('ID: $_clienteId', style: TextStyle(fontSize: 12, color: AppTheme.grigio500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Row(
                      children: [
                        // TEST button
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _clienteId = 6;
                                _clienteNome = 'Mario Rossi';
                                _anteprima = null;
                              });
                              if (_categorie.isNotEmpty) {
                                _calcolaAnteprima();
                              }
                            },
                            icon: const Icon(Icons.bug_report, size: 18),
                            label: const Text('TEST'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.warning,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _scansionaCliente,
                            icon: const Icon(Icons.qr_code_scanner, size: 20),
                            label: const Text('SCAN'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Categorie
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Categorie Acquisto',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: _aggiungiCategoria,
                          icon: const Icon(Icons.add_circle, color: AppTheme.primario),
                        ),
                      ],
                    ),
                    if (_categorie.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.shopping_cart, size: 48, color: AppTheme.grigio300),
                              const SizedBox(height: 8),
                              const Text('Aggiungi categorie merce'),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._categorie.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final cat = entry.value;
                        return ListTile(
                          title: Text(cat['nome']),
                          subtitle: Text('Max sconto: ${cat['sconto_max_percentuale']}%'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '€${cat['importo'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: AppTheme.errore),
                                onPressed: () {
                                  setState(() {
                                    _categorie.removeAt(idx);
                                    _anteprima = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    if (_categorie.isNotEmpty) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTALE:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            '€${totale.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),

            // Anteprima calcolo
            if (_categorie.isNotEmpty && _clienteId != null) ...[
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _calcolaAnteprima,
                icon: const Icon(Icons.calculate),
                label: const Text('CALCOLA IMPORTI'),
              ),
              const SizedBox(height: AppTheme.spacingM),
            ],

            // Riepilogo
            if (_anteprima != null) ...[
              Card(
                color: AppTheme.primario.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riepilogo Transazione',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      
                      _buildRiepilogoRow('Totale acquisto', '€${_anteprima!['totale_acquisto']}'),
                      _buildRiepilogoRow('Sconto max applicabile', '€${_anteprima!['sconto_max_applicabile']}'),
                      _buildRiepilogoRow('Punti disponibili cliente', '${_anteprima!['punti_disponibili_cliente']} pt'),
                      
                      if (!_anteprima!['puo_usare_sconto'])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.block, color: AppTheme.warning, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _anteprima!['motivo_blocco'] ?? 'Bloccato',
                                    style: TextStyle(color: AppTheme.warning, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const Divider(thickness: 2),
                      _buildRiepilogoRow(
                        'PAGABILE CON PUNTI/MONETA',
                        '-€${_anteprima!['sconto_applicato']}',
                        bold: true,
                        color: AppTheme.success,
                      ),
                      _buildRiepilogoRow(
                        'DA PAGARE IN CONTANTI',
                        '€${_anteprima!['importo_da_pagare']}',
                        bold: true,
                        large: true,
                      ),
                      const Divider(),
                      _buildRiepilogoRow(
                        'Nuovi punti generati',
                        '+${_anteprima!['nuovi_punti_generati']} pt',
                        color: AppTheme.primario,
                      ),
                      _buildRiepilogoRow(
                        'Nuovo saldo cliente',
                        '${_anteprima!['nuovo_saldo_cliente']} pt',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _confermaTransazione,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: AppTheme.success,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CONFERMA TRANSAZIONE'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiepilogoRow(String label, String value, {
    bool bold = false,
    bool large = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: large ? 20 : 16,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog per aggiungere categoria
class _CategoriaDialog extends StatefulWidget {
  final Function(String nome, double importo, int percentuale) onSave;

  const _CategoriaDialog({required this.onSave});

  @override
  State<_CategoriaDialog> createState() => _CategoriaDialogState();
}

class _CategoriaDialogState extends State<_CategoriaDialog> {
  String? _categoriaSelezionata = 'Tutto';
  final _importoController = TextEditingController();
  int _percentualeDefault = 30;
  
  final Map<String, int> _scontiDefault = {
    'Tutto': 30,
    'Alimentari': 25,
    'Bevande': 20,
    'Abbigliamento': 30,
    'Elettronica': 15,
    'Casa': 25,
    'Servizi': 20,
  };

  @override
  void initState() {
    super.initState();
    _percentualeDefault = _scontiDefault[_categoriaSelezionata] ?? 30;
  }

  @override
  void dispose() {
    _importoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aggiungi Categoria'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _categoriaSelezionata,
            decoration: const InputDecoration(
              labelText: 'Categoria',
              prefixIcon: Icon(Icons.category),
            ),
            items: _scontiDefault.keys.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _categoriaSelezionata = value;
                _percentualeDefault = _scontiDefault[value] ?? 30;
              });
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _importoController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Importo (€)',
              prefixIcon: Icon(Icons.euro),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Sconto Max:'),
                Text(
                  '$_percentualeDefault%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        ElevatedButton(
          onPressed: () {
            final nome = _categoriaSelezionata ?? 'Tutto';
            final importo = double.tryParse(_importoController.text);

            if (importo != null && importo > 0) {
              widget.onSave(nome, importo, _percentualeDefault);
              Navigator.pop(context);
            }
          },
          child: const Text('Aggiungi'),
        ),
      ],
    );
  }
}

