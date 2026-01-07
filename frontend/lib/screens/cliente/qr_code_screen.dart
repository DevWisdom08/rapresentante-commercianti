import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// QR Code Cliente per identificazione rapida
class QrCodeScreen extends StatelessWidget {
  const QrCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utente non trovato')),
      );
    }

    // QR data: "CLIENTE|ID|EMAIL"
    final qrData = 'CLIENTE|${user.id}|${user.email}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Il Mio QR Code'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mostra questo codice all\'esercente',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // QR Code
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Info utente
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: Column(
                    children: [
                      Text(
                        user.nomeCompleto,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${user.id}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.grigio500,
                        ),
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
}

