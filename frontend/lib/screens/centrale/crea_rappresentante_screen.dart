import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

/// Admin creates new Rappresentante
class CreaRappresentanteScreen extends StatefulWidget {
  const CreaRappresentanteScreen({super.key});

  @override
  State<CreaRappresentanteScreen> createState() => _CreaRappresentanteScreenState();
}

class _CreaRappresentanteScreenState extends State<CreaRappresentanteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nomeController.dispose();
    _cognomeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleCrea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.post(
        '/centrale/crea-rappresentante',
        body: {
          'email': _emailController.text.trim(),
          'nome': _nomeController.text.trim(),
          'cognome': _cognomeController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Rappresentante creato con successo!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      // Detailed error messages
      if (errorMsg.contains('unique')) {
        errorMsg = 'Email già in uso';
      } else if (errorMsg.contains('min:8')) {
        errorMsg = 'Password deve essere almeno 8 caratteri';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
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
        title: const Text('Crea Rappresentante'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: AppTheme.info.withOpacity(0.1),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.info),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Solo Admin può creare nuovi Rappresentanti',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'nome@rapresentante.it',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Email richiesta' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nome richiesto' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cognomeController,
                decoration: const InputDecoration(
                  labelText: 'Cognome',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Cognome richiesto' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Minimo 8 caratteri',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password richiesta';
                  if (v.length < 8) return 'Minimo 8 caratteri';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleCrea,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: AppTheme.primario,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CREA RAPPRESENTANTE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
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

