import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../config/theme.dart';
import 'storico_transazioni_screen.dart';
import 'lista_esercenti_screen.dart';
import 'qr_code_screen.dart';
import 'promozioni_cliente_screen.dart';

/// Home Cliente con wallet e funzionalità base
class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  @override
  void initState() {
    super.initState();
    // Carica wallet e transazioni
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final walletProvider = context.read<WalletProvider>();
      walletProvider.loadWallet();
    });
  }

  Future<void> _refresh() async {
    await context.read<WalletProvider>().refresh();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Esci'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      // Routing automatico al login nel main.dart
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final walletProvider = Provider.of<WalletProvider>(context);
    final user = authProvider.user;
    final wallet = walletProvider.wallet;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CO-STORIES® SOTTOCASA'),
        backgroundColor: AppTheme.primario,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QrCodeScreen(),
                ),
              );
            },
            tooltip: 'Il Mio QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: walletProvider.isLoading && wallet == null
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

                    // Wallet Card
                    _buildWalletCard(context, wallet),
                    const SizedBox(height: AppTheme.spacingM),

                    // Azioni rapide
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.history,
                            label: 'Storico',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const StoricoTransazioniScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingM),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.store,
                            label: 'Negozi',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ListaEsercentiScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    
                    // Promozioni (NUOVO)
                    Card(
                      color: AppTheme.warning.withOpacity(0.05),
                      child: ListTile(
                        leading: Icon(Icons.local_offer, color: AppTheme.warning),
                        title: const Text('Promozioni Attive'),
                        subtitle: const Text('Scopri gli sconti disponibili'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PromozioniClienteScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),

                    // Info placeholder
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: AppTheme.info,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            Text(
                              'Dashboard Cliente',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacingS),
                            Text(
                              'Qui potrai vedere il tuo saldo punti, lo storico transazioni e i negozi dove puoi spendere i tuoi punti.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, wallet) {
    return Card(
      color: AppTheme.primario,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          children: [
            Text(
              'Saldo Punti',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              wallet != null ? wallet.saldoFormattato : '0.00',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'punti',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              '1 punto = 1 euro di sconto',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children: [
              Icon(icon, size: 32, color: AppTheme.primario),
              const SizedBox(height: AppTheme.spacingS),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

