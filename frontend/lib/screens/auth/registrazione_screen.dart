import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// Schermata Registrazione
class RegistrazioneScreen extends StatefulWidget {
  const RegistrazioneScreen({super.key});

  @override
  State<RegistrazioneScreen> createState() => _RegistrazioneScreenState();
}

class _RegistrazioneScreenState extends State<RegistrazioneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  String _ruolo = 'cliente';
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistrazione() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final result = await authProvider.registrazione(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passwordConfirmController.text,
        nome: _nomeController.text.trim(),
        cognome: _cognomeController.text.trim(),
        telefono: _telefonoController.text.trim().isEmpty 
            ? null 
            : _telefonoController.text.trim(),
        ruolo: _ruolo,
      );

      if (!mounted) return;

      // Mostra OTP in dialog
      final otpCode = result['otp_code']?.toString();
      if (otpCode != null) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.mark_email_read, color: AppTheme.success),
                const SizedBox(width: 12),
                const Text('Registrazione Completata!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Il tuo codice di verifica è:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primario.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primario, width: 2),
                  ),
                  child: Text(
                    otpCode,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: AppTheme.primario,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Memorizza questo codice!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Vai a verifica OTP
                  Navigator.pushReplacementNamed(
                    context,
                    '/verifica-otp',
                    arguments: {
                      'email': _emailController.text.trim(),
                      'otp_prefill': otpCode, // Pre-compila l'OTP
                    },
                  );
                },
                child: const Text('CONTINUA'),
              ),
            ],
          ),
        );
      } else {
        // Fallback se non c'è OTP nel response
        Navigator.pushReplacementNamed(
          context,
          '/verifica-otp',
          arguments: {
            'email': _emailController.text.trim(),
          },
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Crea il tuo account',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Ruolo
                DropdownButtonFormField<String>(
                  value: _ruolo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo di account',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'cliente',
                      child: Text('Cliente'),
                    ),
                    DropdownMenuItem(
                      value: 'esercente',
                      child: Text('Esercente'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _ruolo = value);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il tuo nome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Cognome
                TextFormField(
                  controller: _cognomeController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Cognome',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci il tuo cognome';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci la tua email';
                    }
                    if (!value.contains('@')) {
                      return 'Email non valida';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Telefono (opzionale)
                TextFormField(
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Telefono (opzionale)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una password';
                    }
                    if (value.length < 8) {
                      return 'La password deve essere di almeno 8 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Conferma Password
                TextFormField(
                  controller: _passwordConfirmController,
                  obscureText: _obscurePasswordConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegistrazione(),
                  decoration: InputDecoration(
                    labelText: 'Conferma Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePasswordConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePasswordConfirm = !_obscurePasswordConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Conferma la password';
                    }
                    if (value != _passwordController.text) {
                      return 'Le password non coincidono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Pulsante Registrati
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegistrazione,
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
                      : const Text('REGISTRATI'),
                ),
                const SizedBox(height: AppTheme.spacingM),

                // Link Login
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('Hai già un account? Accedi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

