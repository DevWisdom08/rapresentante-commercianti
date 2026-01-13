import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Impostazioni Categorie e Sconti Default
class ImpostazioniCategorieScreen extends StatefulWidget {
  const ImpostazioniCategorieScreen({super.key});

  @override
  State<ImpostazioniCategorieScreen> createState() => _ImpostazioniCategorieScreenState();
}

class _ImpostazioniCategorieScreenState extends State<ImpostazioniCategorieScreen> {
  final Map<String, int> _scontiDefault = {
    'Tutto': 30, // Categoria generale
    'Alimentari': 25,
    'Bevande': 20,
    'Abbigliamento': 30,
    'Elettronica': 15,
    'Casa': 25,
    'Servizi': 20,
  };

  void _modificaSconto(String categoria, int currentValue) {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: '$currentValue');
        return AlertDialog(
          title: Text('Sconto: $categoria'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Sconto massimo (%)',
              suffixText: '%',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () {
                final newValue = int.tryParse(controller.text);
                if (newValue != null && newValue >= 0 && newValue <= 100) {
                  setState(() {
                    _scontiDefault[categoria] = newValue;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sconti per Categoria'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          Card(
            color: AppTheme.info.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Questi sconti appariranno di default quando aggiungi una categoria nella transazione',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          ..._scontiDefault.entries.map((entry) {
            final categoria = entry.key;
            final sconto = entry.value;
            final isTutto = categoria == 'Tutto';

            return Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
              color: isTutto ? AppTheme.primario.withOpacity(0.05) : null,
              child: ListTile(
                leading: Icon(
                  isTutto ? Icons.list : Icons.category,
                  color: isTutto ? AppTheme.primario : AppTheme.grigio500,
                ),
                title: Text(
                  categoria,
                  style: TextStyle(
                    fontWeight: isTutto ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: isTutto ? const Text('Categoria generale (default)') : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$sconto%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _modificaSconto(categoria, sconto),
                    ),
                  ],
                ),
              ),
            );
          }),
          
          const SizedBox(height: AppTheme.spacingL),
          
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Sconti salvati!'),
                  backgroundColor: AppTheme.success,
                ),
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('SALVA IMPOSTAZIONI'),
          ),
        ],
      ),
    );
  }
}

