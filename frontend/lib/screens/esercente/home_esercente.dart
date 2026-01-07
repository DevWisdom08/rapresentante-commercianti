import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import 'assegna_punti_screen.dart';
import 'accetta_punti_screen.dart';

/// Home Esercente
class HomeEsercente extends StatefulWidget {
  const HomeEsercente({super.key});

  @override
  State<HomeEsercente> createState() => _HomeEsercenteState();
}

class _HomeEsercenteState extends State<HomeEsercente> {
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
      final response = await _apiService.get(ApiConfig.esercenteDashboard);
      if (response['success'] == true) {
        setState(() {
          _dashboardData = response['data'];
        });
      }
    } catch (e) {
      // Ignora errori per ora
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
        title: const Text('Dashboard Esercente'),
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
                    // Benvenuto
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Benvenuto,',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              user?.nomeCompleto ?? '',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Bilancio
                    if (_dashboardData != null) ...[
                      _buildBilancioCard(context, _dashboardData!['wallet']),
                      const SizedBox(height: AppTheme.spacingM),
                    ],

                    // Azioni
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.add_circle,
                            label: 'Assegna\nPunti',
                            color: AppTheme.primario,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AssegnaPuntiScreen(),
                                ),
                              );
                              if (result == true) _loadDashboard();
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildActionCard(
                            context,
                            icon: Icons.payment,
                            label: 'Accetta\nPunti',
                            color: AppTheme.success,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AccettaPuntiScreen(),
                                ),
                              );
                              if (result == true) _loadDashboard();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Statistiche
                    if (_dashboardData != null) ...[
                      _buildStatisticheCard(context, _dashboardData!['statistiche']),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBilancioCard(BuildContext context, Map<String, dynamic> wallet) {
    final saldo = wallet['saldo'] ?? 0.0;
    final isPositivo = saldo >= 0;

    return Card(
      color: isPositivo ? AppTheme.success : AppTheme.warning,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            Text(
              'Bilancio Esercente',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBilancioItem(
                  context,
                  'Emessi',
                  '${wallet['punti_emessi'] ?? 0}',
                ),
                _buildBilancioItem(
                  context,
                  'Incassati',
                  '${wallet['punti_incassati'] ?? 0}',
                ),
                _buildBilancioItem(
                  context,
                  'Saldo',
                  '${saldo.toStringAsFixed(1)}',
                  isMain: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBilancioItem(BuildContext context, String label, String value,
      {bool isMain = false}) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: isMain ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
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

  Widget _buildStatisticheCard(BuildContext context, Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche Mese',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildStatRow('Clienti unici', '${stats['clienti_unici_mese'] ?? 0}'),
            _buildStatRow('Punti emessi', '${stats['punti_emessi_mese'] ?? 0}'),
            _buildStatRow('Punti incassati', '${stats['punti_incassati_mese'] ?? 0}'),
            _buildStatRow('Transazioni', '${stats['transazioni_mese'] ?? 0}'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

