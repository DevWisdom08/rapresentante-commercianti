import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// Crea Nuovo Evento
class CreaEventoScreen extends StatefulWidget {
  const CreaEventoScreen({super.key});

  @override
  State<CreaEventoScreen> createState() => _CreaEventoScreenState();
}

class _CreaEventoScreenState extends State<CreaEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titoloController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _bonusPuntiController = TextEditingController();
  final _luogoController = TextEditingController();
  final _apiService = ApiService();
  
  DateTime? _dataInizio;
  DateTime? _dataFine;
  bool _isLoading = false;

  @override
  void dispose() {
    _titoloController.dispose();
    _descrizioneController.dispose();
    _bonusPuntiController.dispose();
    _luogoController.dispose();
    super.dispose();
  }

  Future<void> _selezionaData(BuildContext context, bool isInizio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final dateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );

        setState(() {
          if (isInizio) {
            _dataInizio = dateTime;
          } else {
            _dataFine = dateTime;
          }
        });
      }
    }
  }

  Future<void> _handleCreaEvento() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataInizio == null || _dataFine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona data inizio e fine')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        ApiConfig.rappresentanteEventi,
        body: {
          'titolo': _titoloController.text.trim(),
          'descrizione': _descrizioneController.text.trim(),
          'data_inizio': _dataInizio!.toIso8601String(),
          'data_fine': _dataFine!.toIso8601String(),
          'bonus_punti': double.parse(_bonusPuntiController.text),
          'luogo': _luogoController.text.trim(),
        },
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Evento creato con successo!'),
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
        title: const Text('Crea Evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titoloController,
                decoration: const InputDecoration(
                  labelText: 'Titolo Evento',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Richiesto' : null,
              ),
              const SizedBox(height: AppTheme.spacingM),

              TextFormField(
                controller: _descrizioneController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  prefixIcon: Icon(Icons.description),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              TextFormField(
                controller: _bonusPuntiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bonus Punti',
                  prefixIcon: Icon(Icons.stars),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Richiesto';
                  if (double.tryParse(v) == null) return 'Numero non valido';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingM),

              TextFormField(
                controller: _luogoController,
                decoration: const InputDecoration(
                  labelText: 'Luogo',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),

              // Data inizio
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Data Inizio'),
                subtitle: Text(
                  _dataInizio != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(_dataInizio!)
                      : 'Seleziona data e ora',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selezionaData(context, true),
              ),
              const Divider(),

              // Data fine
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Data Fine'),
                subtitle: Text(
                  _dataFine != null
                      ? DateFormat('dd/MM/yyyy HH:mm').format(_dataFine!)
                      : 'Seleziona data e ora',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selezionaData(context, false),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleCreaEvento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('CREA EVENTO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

