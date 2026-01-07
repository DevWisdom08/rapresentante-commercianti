import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'scanner_qr_screen.dart';

/// Schermata Assegnazione Punti a Cliente
class AssegnaPuntiScreen extends StatefulWidget {
  const AssegnaPuntiScreen({super.key});

  @override
  State<AssegnaPuntiScreen> createState() => _AssegnaPuntiScreenState();
}

class _AssegnaPuntiScreenState extends State<AssegnaPuntiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailClienteController = TextEditingController();
  final _importoEuroController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _apiService = ApiService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailClienteController.dispose();
    _importoEuroController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> _handleAssegnaPunti() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConfig.esercenteAssegnaPunti,
        body: {
          'cliente_email': _emailClienteController.text.trim(),
          'importo_euro': double.parse(_importoEuroController.text),
          'descrizione': _descrizioneController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final puntiAssegnati = data['punti_assegnati'];

        // Mostra successo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Assegnati $puntiAssegnati punti!'),
            backgroundColor: AppTheme.success,
          ),
        );

        // Pulisci form
        _emailClienteController.clear();
        _importoEuroController.clear();
        _descrizioneController.clear();

        // Torna indietro
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assegna Punti'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: AppTheme.info.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: Text(
                          '1 euro di spesa = 1 punto assegnato',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Email cliente
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailClienteController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email Cliente',
                        hintText: 'mario.rossi@test.it',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci email del cliente';
                        }
                        if (!value.contains('@')) {
                          return 'Email non valida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  IconButton.filled(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScannerQRScreen(),
                        ),
                      );
                      
                      if (result != null && result is Map) {
                        _emailClienteController.text = result['cliente_email'] ?? '';
                      }
                    },
                    tooltip: 'Scansiona QR',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Importo euro
              TextFormField(
                controller: _importoEuroController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Importo Spesa (€)',
                  hintText: '50.00',
                  prefixIcon: Icon(Icons.euro),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Inserisci importo';
                  }
                  final importo = double.tryParse(value);
                  if (importo == null || importo <= 0) {
                    return 'Importo non valido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Descrizione
              TextFormField(
                controller: _descrizioneController,
                textInputAction: TextInputAction.done,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descrizione (opzionale)',
                  hintText: 'Acquisto prodotti...',
                  prefixIcon: Icon(Icons.note),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Pulsante assegna
              ElevatedButton(
                onPressed: _isLoading ? null : _handleAssegnaPunti,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
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
                    : const Text('ASSEGNA PUNTI'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

