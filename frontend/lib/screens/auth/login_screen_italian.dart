import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// Login Screen - Italian Theme
class LoginScreenItalian extends StatefulWidget {
  const LoginScreenItalian({super.key});

  @override
  State<LoginScreenItalian> createState() => _LoginScreenItalianState();
}

class _LoginScreenItalianState extends State<LoginScreenItalian> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;
  List<String> _allUserEmails = [];

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
  }

  Future<void> _loadRecentEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('recent_emails') ?? [];
      
      setState(() {
        _allUserEmails = [
          ...recent, // Recent logins first
          // Then test accounts
          'mario.rossi@test.it',
          'panificio@test.it',
          'rappresentante.milano@rapresentante.it',
          'admin@rapresentante.it',
        ].toSet().toList(); // Remove duplicates
      });
    } catch (e) {
      // Fallback
      setState(() {
        _allUserEmails = [
          'mario.rossi@test.it',
          'panificio@test.it',
          'admin@rapresentante.it',
        ];
      });
    }
  }

  Future<void> _saveRecentEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = prefs.getStringList('recent_emails') ?? [];
      
      // Add to beginning, keep max 20
      recent.remove(email); // Remove if exists
      recent.insert(0, email); // Add to front
      await prefs.setStringList('recent_emails', recent.take(20).toList());
    } catch (e) {
      // Ignore save errors
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      print('Login attempt: $email');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        email: email,
        password: _passwordController.text,
      );
      
      print('Login successful! User: ${authProvider.user?.nome}');
      
      // Save successful login email for future autocomplete
      await _saveRecentEmail(email);
      
      // Login successful - main.dart will handle routing automatically
      
    } catch (e) {
      print('Login error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errore,
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
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
           // Light overlay for brightness
           Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.black.withOpacity(0.1),
                     Colors.black.withOpacity(0.2),
                   ],
                 ),
               ),
             ),
           ),
           // Logo at absolute top
           Positioned(
             top: 50,
             left: 0,
             right: 0,
             child: Center(
               child: Image.asset(
                 'assets/images/logo.png',
                 width: 200,
                 height: 140,
                 fit: BoxFit.contain,
               ),
             ),
           ),
           
           // Content - form at bottom
           SafeArea(
             child: Align(
               alignment: Alignment.bottomCenter,
               child: SingleChildScrollView(
                 padding: const EdgeInsets.all(24),
                 child: Form(
               key: _formKey,
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [

                  // Email field with suggestions
                  Column(
                    children: [
                       TextFormField(
                         controller: _emailController,
                         keyboardType: TextInputType.emailAddress,
                         style: const TextStyle(color: Colors.white),
                         decoration: InputDecoration(
                           labelText: 'Email',
                           labelStyle: const TextStyle(color: Colors.white70),
                           hintText: 'mario.rossi@test.it',
                           hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                           prefixIcon: const Icon(Icons.email, color: Colors.white70),
                           filled: true,
                           fillColor: Colors.white.withOpacity(0.15),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(16),
                             borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                           ),
                           enabledBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(16),
                             borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                           ),
                         ),
                        onChanged: (value) {
                          setState(() {
                            if (value.length >= 2) {
                              _emailSuggestions = _allUserEmails
                                  .where((email) => email.toLowerCase().contains(value.toLowerCase()))
                                  .take(10)
                                  .toList();
                              _showSuggestions = _emailSuggestions.isNotEmpty;
                            } else {
                              _showSuggestions = false;
                            }
                          });
                        },
                        onTap: () {
                          if (_emailController.text.isEmpty && _allUserEmails.isNotEmpty) {
                            setState(() {
                              _emailSuggestions = _allUserEmails.take(10).toList();
                              _showSuggestions = true;
                            });
                          }
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Email richiesta' : null,
                      ),
                      
                      // Suggestions - with higher elevation
                      if (_showSuggestions && _emailSuggestions.isNotEmpty)
                        Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView(
                              shrinkWrap: true,
                              children: _emailSuggestions.take(8).map((email) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.person, size: 18, color: AppTheme.primario),
                                  title: Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.arrow_forward, size: 16),
                                  onTap: () {
                                    setState(() {
                                      _emailController.text = email;
                                      _showSuggestions = false;
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                   // Password
                   TextFormField(
                     controller: _passwordController,
                     obscureText: _obscurePassword,
                     style: const TextStyle(color: Colors.white),
                     decoration: InputDecoration(
                       labelText: 'Password',
                       labelStyle: const TextStyle(color: Colors.white70),
                       prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                       suffixIcon: IconButton(
                         icon: Icon(
                           _obscurePassword ? Icons.visibility_off : Icons.visibility,
                           color: Colors.white70,
                         ),
                         onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                       ),
                       filled: true,
                       fillColor: Colors.white.withOpacity(0.15),
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(16),
                         borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                       ),
                       enabledBorder: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(16),
                         borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                       ),
                     ),
                     validator: (v) => v == null || v.isEmpty ? 'Password richiesta' : null,
                   ),
                  const SizedBox(height: 24),

                   // Login button - Transparent green gradient
                   Container(
                     width: double.infinity,
                     height: 56,
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [
                           AppTheme.primario.withOpacity(0.5),
                           AppTheme.primario.withOpacity(0.3),
                         ],
                       ),
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(
                         color: AppTheme.primario.withOpacity(0.6),
                         width: 2,
                       ),
                     ),
                     child: ElevatedButton(
                       onPressed: _isLoading ? null : _handleLogin,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.transparent,
                         shadowColor: Colors.transparent,
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                         ),
                       ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ACCEDI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                   // Register link
                   TextButton(
                     onPressed: () => Navigator.pushNamed(context, '/registrazione'),
                     child: const Text(
                       'Non hai un account? Registrati',
                       style: TextStyle(
                         color: Colors.white,
                         fontSize: 14,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        ),
      ),
        ],
      ),
    );
  }
}

