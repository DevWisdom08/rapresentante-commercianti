import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

/// Dashboard Rappresentante
class DashboardRappresentante extends StatefulWidget {
  const DashboardRappresentante({super.key});

  @override
  State<DashboardRappresentante> createState() => _DashboardRappresentanteState();
}

class _DashboardRappresentanteState extends State<DashboardRappresentante> {
  final _apiService = ApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      final response = await _apiService.get(ApiConfig.rappresentanteDashboard);
      if (response['success'] == true) {
        setState(() {
          _dashboardData = response['data'];
        });
      }
    } catch (e) {
      // Ignora errori
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Zona'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: _isLoading && _dashboardData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Zona
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rappresentante di Zona',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              user?.nomeCompleto ?? '',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            if (_dashboardData != null) ...[
                              const SizedBox(height: AppTheme.spacingS),
                              Text(
                                '${_dashboardData!['zona']['nome']} (${_dashboardData!['zona']['provincia']})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.primario,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // KPI
                    if (_dashboardData != null) ...[
                      _buildKPICard(context, _dashboardData!),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTopEsercentiCard(context, _dashboardData!['top_esercenti']),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildKPICard(BuildContext context, Map<String, dynamic> data) {
    final kpi = data['kpi'];
    final zona = data['zona'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KPI Zona',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildKPIItem(
                    context,
                    'Esercenti',
                    '${zona['num_esercenti']}',
                    Icons.store,
                  ),
                ),
                Expanded(
                  child: _buildKPIItem(
                    context,
                    'Clienti',
                    '${zona['num_clienti']}',
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildStatRow('Punti in circolazione', '${kpi['punti_totali_circolazione']}'),
            _buildStatRow('Punti emessi (mese)', '${kpi['punti_emessi_mese']}'),
            _buildStatRow('Punti spesi (mese)', '${kpi['punti_spesi_mese']}'),
            _buildStatRow('Tasso circolazione', '${kpi['tasso_circolazione']}%'),
            _buildStatRow('Nuovi clienti', '${kpi['nuovi_clienti_mese']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primario),
        const SizedBox(height: AppTheme.spacingS),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.primario,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTopEsercentiCard(BuildContext context, List? esercenti) {
    if (esercenti == null || esercenti.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Esercenti',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...esercenti.take(5).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['nome_negozio'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          e['categoria'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${e['punti_incassati']} punti',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.success,
                        ),
                      ),
                      Text(
                        '${e['clienti_unici']} clienti',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

