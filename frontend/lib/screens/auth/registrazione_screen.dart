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

  Future<void> _checkUsernameDisponibilita(String username) async {
    if (username.length < 3) return;

    setState(() => _isCheckingUsername = true);

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl.replaceAll('/v1', '')}/v1/auth/check-username'),
        headers: ApiConfig.headers,
        body: jsonEncode({
          'username': username,
          'dominio': '@rapresentante.it',
        }),
      );

      final data = jsonDecode(response.body);
      
      if (data['success'] == true) {
        final result = data['data'];
        setState(() {
          if (result['disponibile'] == false) {
            _suggerimentiUsername = List<Map<String, dynamic>>.from(result['suggerimenti'] ?? []);
          } else {
            _suggerimentiUsername = [];
          }
        });
      }
    } catch (e) {
      // Ignora errori di check
    } finally {
      if (mounted) {
        setState(() => _isCheckingUsername = false);
      }
    }
  }

  Future<void> _handleRegistrazione() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Costruisci email completa
      String emailCompleta = _emailController.text.trim();
      if (!emailCompleta.contains('@')) {
        emailCompleta = emailCompleta + '@rapresentante.it';
      }
      
      final result = await authProvider.registrazione(
        email: emailCompleta,
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

      // Registrazione diretta - vai direttamente alla home!
      if (result.containsKey('registrazione_diretta') && result['registrazione_diretta'] == true) {
        // Success popup
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.success),
                const SizedBox(width: 12),
                const Text('Benvenuto!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Registrazione completata con successo!',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (result.containsKey('user') && result['user']['ruolo'] == 'cliente')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.card_giftcard, size: 48, color: AppTheme.success),
                        const SizedBox(height: 8),
                        const Text(
                          'Bonus Benvenuto',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          '10 punti',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  
                  // Navigate to appropriate dashboard based on role
                  final user = authProvider.user;
                  if (user != null) {
                    String route = '/home-cliente';
                    if (user.ruolo == 'esercente') route = '/home-esercente';
                    if (user.ruolo == 'rappresentante') route = '/dashboard-rappresentante';
                    if (user.ruolo == 'centrale') route = '/dashboard-centrale';
                    
                    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
                  }
                },
                child: const Text('INIZIA'),
              ),
            ],
          ),
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

                // Email (semplificato con dominio auto)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Nome Utente',
                          hintText: 'mario.rossi',
                          prefixIcon: const Icon(Icons.person),
                          suffixIcon: _isCheckingUsername 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (value) async {
                          if (value.length >= 3) {
                            await _checkUsernameDisponibilita(value);
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci nome utente';
                          }
                          return null;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 16),
                      child: Text(
                        '@rapresentante.it',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.grigio500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Suggerimenti username
                if (_suggerimentiUsername.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warning),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                            const SizedBox(width: 8),
                            const Text(
                              'Nome già in uso. Prova questi:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _suggerimentiUsername.map((sug) {
                            return ActionChip(
                              label: Text(sug['username']),
                              onPressed: () {
                                setState(() {
                                  _emailController.text = sug['username'];
                                  _suggerimentiUsername = [];
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
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

