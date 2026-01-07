import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'gestione_utenti_screen.dart';

/// Dashboard Centrale (Admin)
class DashboardCentrale extends StatefulWidget {
  const DashboardCentrale({super.key});

  @override
  State<DashboardCentrale> createState() => _DashboardCentraleState();
}

class _DashboardCentraleState extends State<DashboardCentrale> {
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
      final response = await _apiService.get(ApiConfig.centraleDashboard);
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
        title: const Text('Dashboard Centrale'),
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
                    // Header
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings, 
                                    size: 32, color: AppTheme.primario),
                                const SizedBox(width: AppTheme.spacingM),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Admin Centrale',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      user?.nomeCompleto ?? '',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Azioni Admin
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.people,
                            label: 'Gestione\nUtenti',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GestioneUtentiScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.assessment,
                            label: 'Report\nGlobali',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Report in sviluppo')),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Statistiche Globali
                    if (_dashboardData != null) ...[
                      _buildStatisticheGlobali(context, _dashboardData!['statistiche_globali']),
                      const SizedBox(height: AppTheme.spacingM),
                      _buildTopZone(context, _dashboardData!['top_zone']),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatisticheGlobali(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche Globali',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Rappresentanti', '${stats['num_rappresentanti']}', Icons.business),
                _buildStatItem(context, 'Esercenti', '${stats['num_esercenti']}', Icons.store),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Clienti', '${stats['num_clienti']}', Icons.people),
                _buildStatItem(context, 'Transazioni', '${stats['transazioni_totali']}', Icons.receipt),
              ],
            ),
            const Divider(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    'Punti Totali in Circolazione',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${stats['punti_totali_circolazione']}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppTheme.primario,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppTheme.primario),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildTopZone(BuildContext context, List? zone) {
    if (zone == null || zone.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Zone per Circolazione Punti',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...zone.map((z) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          z['nome_zona'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Rappresentante: ${z['rappresentante']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${z['punti_circolazione']} punti',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primario,
                        ),
                      ),
                      Text(
                        '${z['num_esercenti']} esercenti',
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

  Widget _buildActionCard(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              Icon(icon, size: 40, color: AppTheme.primario),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

