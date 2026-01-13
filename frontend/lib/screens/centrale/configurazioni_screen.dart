import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// Configurazioni Sistema (Admin)
class ConfigurazioniScreen extends StatefulWidget {
  const ConfigurazioniScreen({super.key});

  @override
  State<ConfigurazioniScreen> createState() => _ConfigurazioniScreenState();
}

class _ConfigurazioniScreenState extends State<ConfigurazioniScreen> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _bonusBenvenutoController = TextEditingController();
  final _scadenzaPuntiController = TextEditingController();
  final _limitePuntiController = TextEditingController();
  final _euroPerPuntoController = TextEditingController();
  final _dominioEmailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _bonusBenvenutoController.dispose();
    _scadenzaPuntiController.dispose();
    _limitePuntiController.dispose();
    _euroPerPuntoController.dispose();
    _dominioEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(ApiConfig.centraleConfigurazioni);
      if (response['success'] == true) {
        final data = response['data'];
        _bonusBenvenutoController.text = '${data['bonus_benvenuto'] ?? 10}';
        _scadenzaPuntiController.text = '${data['scadenza_punti_giorni'] ?? 180}';
        _limitePuntiController.text = '${data['limite_max_punti_transazione'] ?? 500}';
        _euroPerPuntoController.text = '${data['euro_per_punto'] ?? 10}';
        _dominioEmailController.text = '${data['dominio_email_default'] ?? '@rapresentante.it'}';
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

  Future<void> _salvaConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final response = await _apiService.put(
        ApiConfig.centraleConfigurazioni,
        body: {
          'bonus_benvenuto': double.parse(_bonusBenvenutoController.text),
          'scadenza_punti_giorni': int.parse(_scadenzaPuntiController.text),
          'limite_max_punti_transazione': double.parse(_limitePuntiController.text),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configurazioni salvate!'),
          backgroundColor: AppTheme.success,
        ),
      );
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurazioni Sistema'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Regole Sistema Punti',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacingL),

                            TextFormField(
                              controller: _bonusBenvenutoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Bonus Benvenuto (punti)',
                                helperText: 'Punti assegnati ai nuovi clienti',
                                prefixIcon: Icon(Icons.card_giftcard),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Richiesto';
                                if (double.tryParse(v) == null) return 'Numero non valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            TextFormField(
                              controller: _scadenzaPuntiController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Scadenza Punti (giorni)',
                                helperText: 'Dopo quanti giorni i punti scadono',
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Richiesto';
                                if (int.tryParse(v) == null) return 'Numero non valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            TextFormField(
                              controller: _limitePuntiController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Limite Max Punti per Transazione',
                                helperText: 'Massimo punti spendibili in una volta',
                                prefixIcon: Icon(Icons.trending_up),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Richiesto';
                                if (double.tryParse(v) == null) return 'Numero non valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            TextFormField(
                              controller: _euroPerPuntoController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Euro per 1 Punto',
                                helperText: 'Quanti euro di spesa generano 1 punto (default: 10)',
                                prefixIcon: Icon(Icons.euro),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Richiesto';
                                if (double.tryParse(v) == null) return 'Numero non valido';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppTheme.spacingM),

                            TextFormField(
                              controller: _dominioEmailController,
                              decoration: const InputDecoration(
                                labelText: 'Dominio Email Default',
                                helperText: 'Es: @rapresentante.it',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Richiesto';
                                if (!v.startsWith('@')) return 'Deve iniziare con @';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),

                    Card(
                      color: AppTheme.warning.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppTheme.warning),
                            const SizedBox(width: AppTheme.spacingM),
                            Expanded(
                              child: Text(
                                'Le modifiche richiedono riavvio del server backend per essere applicate',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXl),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _salvaConfig,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SALVA CONFIGURAZIONI'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

