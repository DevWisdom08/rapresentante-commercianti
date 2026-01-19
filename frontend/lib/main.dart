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
      child: MaterialApp(
        title: 'Rapresentante Commercianti',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.light,
        themeMode: ThemeMode.light,
        
        // Routing basato su stato autenticazione
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            print('Consumer rebuild - isAuth: ${authProvider.isAuthenticated}, user: ${authProvider.user?.email}');
            return _buildHomeScreen(authProvider);
          },
        ),
        
        routes: {
          '/login': (context) => const LoginScreenItalian(),
          '/registrazione': (context) => const RegistrazioneScreen(),
          '/verifica-otp': (context) => const VerificaOtpScreen(),
          '/home-cliente': (context) => const WalletItalianTheme(),
          '/home-esercente': (context) => const HomeEsercente(),
          '/dashboard-rappresentante': (context) => const DashboardRappresentante(),
          '/dashboard-centrale': (context) => const DashboardCentrale(),
        },
      ),
    );
  }

  /// Determina schermata iniziale basata su stato autenticazione
  Widget _buildHomeScreen(AuthProvider authProvider) {
    print('_buildHomeScreen called - isLoading: ${authProvider.isLoading}, isAuth: ${authProvider.isAuthenticated}, role: ${authProvider.user?.ruolo}');
    
    if (authProvider.isLoading) {
      print('Showing loading screen');
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      print('Not authenticated - showing login');
      return const LoginScreenItalian();
    }

    // Routing basato su ruolo utente
    final ruolo = authProvider.user?.ruolo;
    print('Authenticated with role: $ruolo');
    
    switch (ruolo) {
      case 'cliente':
        print('Routing to WalletItalianTheme');
        return const WalletItalianTheme();
      case 'esercente':
        print('Routing to HomeEsercente');
        return const HomeEsercente();
      case 'rappresentante':
        print('Routing to DashboardRappresentante');
        return const DashboardRappresentante();
      case 'centrale':
      case 'admin':
        print('Routing to DashboardCentrale');
        return const DashboardCentrale();
      default:
        print('Unknown role: $ruolo - showing login');
        return const LoginScreenItalian();
    }
  }
}

