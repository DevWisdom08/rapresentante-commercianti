import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// Schermata Verifica OTP
class VerificaOtpScreen extends StatefulWidget {
  const VerificaOtpScreen({super.key});

  @override
  State<VerificaOtpScreen> createState() => _VerificaOtpScreenState();
}

class _VerificaOtpScreenState extends State<VerificaOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  String? _email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recupera email dai parametri route
    if (_email == null) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      _email = args?['email'];
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerificaOtp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email non trovata'),
          backgroundColor: AppTheme.errore,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      await authProvider.verificaOtp(
        email: _email!,
        otpCode: _otpController.text.trim(),
      );

      if (!mounted) return;

      // Verifica riuscita - vai alla home basata sul ruolo
      final user = authProvider.user;
      if (user != null) {
        String route = '/home-cliente';
        if (user.ruolo == 'esercente') route = '/home-esercente';
        if (user.ruolo == 'rappresentante') route = '/dashboard-rappresentante';
        if (user.ruolo == 'centrale') route = '/dashboard-centrale';
        
        Navigator.pushReplacementNamed(context, route);
      }
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleReinviaOtp() async {
    if (_email == null) return;

    setState(() => _isResending = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.reinviaOtp(_email!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codice OTP reinviato alla tua email'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errore,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifica Email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icona
                  Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: AppTheme.primario,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  Text(
                    'Verifica la tua email',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  Text(
                    'Abbiamo inviato un codice di verifica a:',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingS),

                  Text(
                    _email ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primario,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Campo OTP
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Codice OTP',
                      hintText: '123456',
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il codice OTP';
                      }
                      if (value.length != 6) {
                        return 'Il codice deve essere di 6 cifre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacingXl),

                  // Pulsante Verifica
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleVerificaOtp,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('VERIFICA'),
                  ),
                  const SizedBox(height: AppTheme.spacingM),

                  // Link Reinvia OTP
                  TextButton(
                    onPressed: (_isLoading || _isResending)
                        ? null
                        : _handleReinviaOtp,
                    child: _isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Non hai ricevuto il codice? Reinvia'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

