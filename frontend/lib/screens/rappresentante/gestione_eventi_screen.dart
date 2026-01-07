import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'crea_evento_screen.dart';

/// Gestione Eventi
class GestioneEventiScreen extends StatefulWidget {
  const GestioneEventiScreen({super.key});

  @override
  State<GestioneEventiScreen> createState() => _GestioneEventiScreenState();
}

class _GestioneEventiScreenState extends State<GestioneEventiScreen> {
  final _apiService = ApiService();
  List<dynamic> _eventi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEventi();
  }

  Future<void> _loadEventi() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(ApiConfig.rappresentanteEventi);
      if (response['success'] == true) {
        setState(() {
          _eventi = response['data'] ?? [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestione Eventi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreaEventoScreen(),
                ),
              );
              if (result == true) _loadEventi();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eventi.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event, size: 64, color: AppTheme.grigio300),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Nessun evento creato',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CreaEventoScreen(),
                            ),
                          );
                          if (result == true) _loadEventi();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Crea Primo Evento'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: _eventi.length,
                  itemBuilder: (context, index) {
                    final evento = _eventi[index];
                    return _buildEventoCard(evento);
                  },
                ),
    );
  }

  Widget _buildEventoCard(Map<String, dynamic> evento) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final isAttivo = evento['attivo'] == true;
    final isInCorso = evento['is_in_corso'] == true;

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isInCorso
                        ? AppTheme.success.withOpacity(0.2)
                        : AppTheme.grigio300.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.event,
                    color: isInCorso ? AppTheme.success : AppTheme.grigio500,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        evento['titolo'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isInCorso ? 'In corso' : 'Programmato',
                        style: TextStyle(
                          fontSize: 12,
                          color: isInCorso ? AppTheme.success : AppTheme.grigio500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+${evento['bonus_punti']} punti',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primario,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (evento['descrizione'] != null)
              Text(
                evento['descrizione'],
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.grigio500),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(DateTime.parse(evento['data_inizio'])),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Icon(Icons.people, size: 14, color: AppTheme.grigio500),
                const SizedBox(width: 4),
                Text(
                  '${evento['num_partecipanti']}${evento['max_partecipanti'] != null ? '/${evento['max_partecipanti']}' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (evento['luogo'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: AppTheme.grigio500),
                  const SizedBox(width: 4),
                  Text(
                    evento['luogo'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

