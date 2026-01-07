import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Gestione Promozioni Esercente
class PromozioniScreen extends StatefulWidget {
  const PromozioniScreen({super.key});

  @override
  State<PromozioniScreen> createState() => _PromozioniScreenState();
}

class _PromozioniScreenState extends State<PromozioniScreen> {
  final List<Map<String, dynamic>> _promozioni = [
    {
      'titolo': 'Sconto 20% su tutti i prodotti',
      'descrizione': 'Valido fino a fine mese',
      'attivo': true,
    },
  ];

  void _aggiungiPromozione() {
    showDialog(
      context: context,
      builder: (context) => _PromozioneDialog(
        onSave: (titolo, descrizione) {
          setState(() {
            _promozioni.add({
              'titolo': titolo,
              'descrizione': descrizione,
              'attivo': true,
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Le Mie Promozioni'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _aggiungiPromozione,
          ),
        ],
      ),
      body: _promozioni.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, size: 64, color: AppTheme.grigio300),
                  const SizedBox(height: AppTheme.spacingM),
                  const Text('Nessuna promozione attiva'),
                  const SizedBox(height: AppTheme.spacingM),
                  ElevatedButton.icon(
                    onPressed: _aggiungiPromozione,
                    icon: const Icon(Icons.add),
                    label: const Text('Crea Promozione'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              itemCount: _promozioni.length,
              itemBuilder: (context, index) {
                final promo = _promozioni[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                  child: ListTile(
                    leading: Icon(
                      Icons.local_offer,
                      color: promo['attivo'] ? AppTheme.success : AppTheme.grigio300,
                    ),
                    title: Text(promo['titolo']),
                    subtitle: Text(promo['descrizione']),
                    trailing: Switch(
                      value: promo['attivo'],
                      onChanged: (value) {
                        setState(() {
                          _promozioni[index]['attivo'] = value;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _PromozioneDialog extends StatefulWidget {
  final Function(String titolo, String descrizione) onSave;

  const _PromozioneDialog({required this.onSave});

  @override
  State<_PromozioneDialog> createState() => _PromozioneDialogState();
}

class _PromozioneDialogState extends State<_PromozioneDialog> {
  final _titoloController = TextEditingController();
  final _descrizioneController = TextEditingController();

  @override
  void dispose() {
    _titoloController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nuova Promozione'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titoloController,
            decoration: const InputDecoration(
              labelText: 'Titolo',
              hintText: 'Sconto 10%...',
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _descrizioneController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Descrizione',
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
            if (_titoloController.text.isNotEmpty) {
              widget.onSave(
                _titoloController.text,
                _descrizioneController.text,
              );
              Navigator.pop(context);
            }
          },
          child: const Text('Salva'),
        ),
      ],
    );
  }
}

