import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'crea_rappresentante_screen.dart';

/// Gestione Utenti (Admin)
class GestioneUtentiScreen extends StatefulWidget {
  const GestioneUtentiScreen({super.key});

  @override
  State<GestioneUtentiScreen> createState() => _GestioneUtentiScreenState();
}

class _GestioneUtentiScreenState extends State<GestioneUtentiScreen> {
  final _apiService = ApiService();
  List<dynamic> _utenti = [];
  bool _isLoading = true;
  String? _filtroRuolo;

  @override
  void initState() {
    super.initState();
    _loadUtenti();
  }

  Future<void> _loadUtenti() async {
    setState(() => _isLoading = true);

    try {
      String endpoint = ApiConfig.centraleUtenti;
      if (_filtroRuolo != null) {
        endpoint += '?ruolo=$_filtroRuolo';
      }

      final response = await _apiService.get(endpoint);
      if (response['success'] == true) {
        setState(() {
          _utenti = response['data']['data'] ?? [];
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

  Future<void> _attivaUtente(int userId) async {
    try {
      await _apiService.post(ApiConfig.centraleAttivaUtente(userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utente attivato')),
      );
      _loadUtenti();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _disattivaUtente(int userId) async {
    try {
      await _apiService.post(ApiConfig.centraleDisattivaUtente(userId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utente disattivato')),
      );
      _loadUtenti();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _eliminaUtente(int userId, String nome) async {
    // Conferma
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conferma Eliminazione'),
        content: Text('Sei sicuro di voler eliminare definitivamente $nome?\n\nQuesta azione è irreversibile!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.delete(ApiConfig.centraleEliminaUtente(userId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Utente eliminato definitivamente'),
          backgroundColor: Colors.red,
        ),
      );
      _loadUtenti();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Utenti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Crea Rappresentante',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreaRappresentanteScreen(),
                ),
              );
              if (result == true) _loadUtenti();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro ruolo
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: DropdownButtonFormField<String?>(
              value: _filtroRuolo,
              decoration: const InputDecoration(
                labelText: 'Filtra per Ruolo',
                prefixIcon: Icon(Icons.filter_list),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tutti')),
                DropdownMenuItem(value: 'cliente', child: Text('Clienti')),
                DropdownMenuItem(value: 'esercente', child: Text('Esercenti')),
                DropdownMenuItem(value: 'rappresentante', child: Text('Rappresentanti')),
              ],
              onChanged: (value) {
                setState(() => _filtroRuolo = value);
                _loadUtenti();
              },
            ),
          ),

          // Lista utenti
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _utenti.length,
                    itemBuilder: (context, index) {
                      final utente = _utenti[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                          vertical: AppTheme.spacingS,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: utente['attivo']
                                ? AppTheme.success
                                : AppTheme.grigio300,
                            child: Icon(
                              _getRuoloIcon(utente['ruolo']),
                              color: Colors.white,
                            ),
                          ),
                          title: Text('${utente['nome']} ${utente['cognome']}'),
                          subtitle: Text(
                            '${utente['email']}\n${_getRuoloLabel(utente['ruolo'])}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              if (!utente['attivo'])
                                PopupMenuItem(
                                  onTap: () => _attivaUtente(utente['id']),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 18, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Attiva'),
                                    ],
                                  ),
                                ),
                              if (utente['attivo'])
                                PopupMenuItem(
                                  onTap: () => _disattivaUtente(utente['id']),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.block, size: 18, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Disattiva'),
                                    ],
                                  ),
                                ),
                              PopupMenuItem(
                                onTap: () => _eliminaUtente(utente['id'], '${utente['nome']} ${utente['cognome']}'),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete_forever, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Elimina', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getRuoloIcon(String ruolo) {
    switch (ruolo) {
      case 'cliente':
        return Icons.person;
      case 'esercente':
        return Icons.store;
      case 'rappresentante':
        return Icons.business;
      case 'centrale':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }

  String _getRuoloLabel(String ruolo) {
    switch (ruolo) {
      case 'cliente':
        return 'Cliente';
      case 'esercente':
        return 'Esercente';
      case 'rappresentante':
        return 'Rappresentante';
      case 'centrale':
        return 'Amministratore';
      default:
        return ruolo;
    }
  }
}

