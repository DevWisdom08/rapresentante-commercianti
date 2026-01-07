import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// Lista Esercenti Disponibili
class ListaEsercentiScreen extends StatefulWidget {
  const ListaEsercentiScreen({super.key});

  @override
  State<ListaEsercentiScreen> createState() => _ListaEsercentiScreenState();
}

class _ListaEsercentiScreenState extends State<ListaEsercentiScreen> {
  final _apiService = ApiService();
  List<dynamic> _esercenti = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEsercenti();
  }

  Future<void> _loadEsercenti() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(ApiConfig.esercenteListaZona);
      if (response['success'] == true) {
        setState(() {
          _esercenti = response['data'] ?? [];
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
        title: const Text('Negozi Zona'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _esercenti.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store, size: 64, color: AppTheme.grigio300),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        'Nessun esercente trovato',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: _esercenti.length,
                  itemBuilder: (context, index) {
                    final esercente = _esercenti[index];
                    return _buildEsercenteCard(esercente);
                  },
                ),
    );
  }

  Widget _buildEsercenteCard(Map<String, dynamic> esercente) {
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoriaIcon(esercente['categoria']),
                    color: AppTheme.primario,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esercente['nome_negozio'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        esercente['categoria_formattata'] ?? esercente['categoria'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.grigio500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (esercente['indirizzo'] != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppTheme.grigio500),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      esercente['indirizzo'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
            if (esercente['telefono'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.grigio500),
                  const SizedBox(width: 4),
                  Text(
                    esercente['telefono'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (esercente['descrizione'] != null) ...[
              const SizedBox(height: AppTheme.spacingM),
              Text(
                esercente['descrizione'],
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoriaIcon(String? categoria) {
    switch (categoria) {
      case 'alimentari':
        return Icons.restaurant;
      case 'abbigliamento':
        return Icons.checkroom;
      case 'bar_ristoranti':
        return Icons.local_cafe;
      case 'servizi':
        return Icons.build;
      case 'salute_benessere':
        return Icons.spa;
      case 'casa_arredamento':
        return Icons.home;
      case 'elettronica':
        return Icons.devices;
      default:
        return Icons.store;
    }
  }
}

