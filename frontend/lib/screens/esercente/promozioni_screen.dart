import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Gestione Promozioni Esercente
class PromozioniScreen extends StatefulWidget {
  const PromozioniScreen({super.key});

  @override
  State<PromozioniScreen> createState() => _PromozioniScreenState();
}

class _PromozioniScreenState extends State<PromozioniScreen> {
  bool _promoPrimiClientiAttiva = false;
  int _promoPrimiClientiPercentuale = 50; // Doppia percentuale pagabile con P/M

  final List<Map<String, dynamic>> _promozioni = [
    {
      'titolo': '20% pagabile con P/M su tutti i prodotti',
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
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Promo Primi Clienti (SPECIALE)
          Card(
            color: AppTheme.warning.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.stars, color: AppTheme.warning),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Promo Primi Clienti',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Switch(
                        value: _promoPrimiClientiAttiva,
                        onChanged: (value) {
                          setState(() => _promoPrimiClientiAttiva = value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Doppia percentuale pagabile con P/M per nuovi clienti',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_promoPrimiClientiAttiva) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Percentuale pagabile con P/M:'),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () {
                                  if (_promoPrimiClientiPercentuale > 10) {
                                    setState(() => _promoPrimiClientiPercentuale -= 10);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  '$_promoPrimiClientiPercentuale%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () {
                                  if (_promoPrimiClientiPercentuale < 100) {
                                    setState(() => _promoPrimiClientiPercentuale += 10);
                                  }
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
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
          
          // Altre promozioni
          if (_promozioni.isEmpty)
            Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: ElevatedButton.icon(
                    onPressed: _aggiungiPromozione,
                    icon: const Icon(Icons.add),
                    label: const Text('Crea Promozione'),
                  ),
                ),
              )
          else
            ..._promozioni.asMap().entries.map((entry) {
              final index = entry.key;
              final promo = entry.value;
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
            }),
        ],
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
              hintText: '20% pagabile con P/M...',
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

