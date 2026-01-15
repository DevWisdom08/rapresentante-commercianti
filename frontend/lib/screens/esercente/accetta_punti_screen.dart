import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Schermata Accettazione Pagamento con Punti
class AccettaPuntiScreen extends StatefulWidget {
  const AccettaPuntiScreen({super.key});

  @override
  State<AccettaPuntiScreen> createState() => _AccettaPuntiScreenState();
}

class _AccettaPuntiScreenState extends State<AccettaPuntiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clienteIdController = TextEditingController();
  final _puntiController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _clienteVerificato;

  @override
  void dispose() {
    _clienteIdController.dispose();
    _puntiController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _verificaCliente() async {
    if (_clienteIdController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConfig.esercenteVerificaCliente,
        body: {
          'cliente_id': int.parse(_clienteIdController.text.trim()),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _clienteVerificato = response['data'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAccettaPunti() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clienteVerificato == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifica prima il cliente'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConfig.esercenteAccettaPunti,
        body: {
          'cliente_id': int.parse(_clienteIdController.text.trim()),
          'punti': double.parse(_puntiController.text),
          'descrizione': _descrizioneController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final puntiUtilizzati = data['punti_utilizzati'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Accettati $puntiUtilizzati punti!'),
            backgroundColor: AppTheme.success,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errore,
          duration: const Duration(seconds: 4),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accetta Pagamento in Punti/Moneta'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info
              Card(
                color: AppTheme.warning.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: AppTheme.warning),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          'Il cliente può spendere punti solo se NON li ha guadagnati qui',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // ID Cliente
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _clienteIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ID Cliente',
                        hintText: '123',
                        prefixIcon: Icon(Icons.badge),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci ID cliente';
                        }
                        if (int.tryParse(value) == null) {
                          return 'ID non valido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verificaCliente,
                    child: const Text('VERIFICA'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Cliente verificato
              if (_clienteVerificato != null) ...[
                Card(
                  color: _clienteVerificato!['puo_spendere']
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.errore.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _clienteVerificato!['puo_spendere']
                                  ? Icons.check_circle
                                  : Icons.block,
                              color: _clienteVerificato!['puo_spendere']
                                  ? AppTheme.success
                                  : AppTheme.errore,
                            ),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Text(
                                _clienteVerificato!['cliente']['nome'],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingS),
                        Text('Email: ${_clienteVerificato!['cliente']['email']}'),
                        Text('Saldo totale: ${_clienteVerificato!['wallet']['saldo_totale']} punti'),
                        Text(
                          'Spendibili qui: ${_clienteVerificato!['wallet']['punti_spendibili_qui']} punti',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _clienteVerificato!['puo_spendere']
                                ? AppTheme.success
                                : AppTheme.errore,
                          ),
                        ),
                        if (!_clienteVerificato!['puo_spendere']) ...[
                          const SizedBox(height: AppTheme.spacingS),
                          Text(
                            _clienteVerificato!['motivo_blocco'] ?? 'Bloccato',
                            style: TextStyle(color: AppTheme.errore, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),
              ],

              // Punti da accettare
              if (_clienteVerificato != null && _clienteVerificato!['puo_spendere']) ...[
                TextFormField(
                  controller: _puntiController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Punti da Accettare',
                    hintText: 'Max: ${_clienteVerificato!['wallet']['punti_spendibili_qui']}',
                    prefixIcon: const Icon(Icons.stars),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci punti';
                    }
                    final punti = double.tryParse(value);
                    if (punti == null || punti <= 0) {
                      return 'Punti non validi';
                    }
                    final max = _clienteVerificato!['wallet']['punti_spendibili_qui'];
                    if (punti > max) {
                      return 'Massimo $max punti disponibili';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                TextFormField(
                  controller: _descrizioneController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione (opzionale)',
                    hintText: 'Acquisto con punti...',
                    prefixIcon: Icon(Icons.note),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAccettaPunti,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: AppTheme.success,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('ACCETTA PAGAMENTO'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

