import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/auth/login_screen_italian.dart';
import 'screens/auth/registrazione_screen.dart';
import 'screens/auth/verifica_otp_screen.dart';
import 'screens/cliente/wallet_italian_theme.dart';
import 'screens/esercente/home_esercente.dart';
import 'screens/rappresentante/dashboard_rappresentante.dart';
import 'screens/centrale/dashboard_centrale.dart';

void main() {
  runApp(const RapresentanteApp());
}

/// Applicazione principale
class RapresentanteApp extends StatelessWidget {
  const RapresentanteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp(
            title: 'Rapresentante Commercianti',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
      darkTheme: AppTheme.light,
      themeMode: ThemeMode.light,
            
            // Routing basato su stato autenticazione
            home: _buildHomeScreen(authProvider),
            
            routes: {
              '/login': (context) => const LoginScreenItalian(),
              '/registrazione': (context) => const RegistrazioneScreen(),
              '/verifica-otp': (context) => const VerificaOtpScreen(),
              '/home-cliente': (context) => const WalletItalianTheme(),
              '/home-esercente': (context) => const HomeEsercente(),
              '/dashboard-rappresentante': (context) => const DashboardRappresentante(),
              '/dashboard-centrale': (context) => const DashboardCentrale(),
            },
          );
        },
      ),
    );
  }

  /// Determina schermata iniziale basata su stato autenticazione
  Widget _buildHomeScreen(AuthProvider authProvider) {
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
        return const LoginScreenItalian();
    }

    // Routing basato su ruolo utente
    switch (authProvider.user?.ruolo) {
      case 'cliente':
        return const WalletItalianTheme();
      case 'esercente':
        return const HomeEsercente();
      case 'rappresentante':
        return const DashboardRappresentante();
      case 'centrale':
        return const DashboardCentrale();
      default:
        return const LoginScreenItalian();
    }
  }
}

