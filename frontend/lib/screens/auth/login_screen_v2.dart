import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

/// Premium Modern Login Screen
class LoginScreenV2 extends StatefulWidget {
  const LoginScreenV2({super.key});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  List<String> _emailSuggestions = [];
  bool _showSuggestions = false;

  late AnimationController _floatingController;
  late AnimationController _glowController;

  // Email comuni per quick login
  final List<String> _commonEmails = [
    'mario.rossi@test.it',
    'laura.bianchi@test.it',
    'panificio@test.it',
    'abbigliamento@test.it',
    'rappresentante.milano@rapresentante.it',
    'admin@rapresentante.it',
  ];

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _floatingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004D2C), // Dark Italian green
              Color(0xFF1A2E1F), // Deep forest
              Color(0xFF0F1A14), // Almost black with green tint
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background circles with harmonious colors
            ...List.generate(3, (index) {
              return AnimatedBuilder(
                animation: _floatingController,
                builder: (context, child) {
                  final offset = _floatingController.value * 100 * (index + 1);
                  return Positioned(
                    top: 100 + offset,
                    left: 50.0 * index,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            [
                              const Color(0xFF009246), // Italian green
                              const Color(0xFFCE2B37), // Italian red
                              const Color(0xFFFFFFFF), // White
                            ][index].withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo - Clear display
                        Image.asset(
                          'assets/images/logo.png',
                          width: 300,
                          height: 220,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),

                        // Branding
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFFFFF), Color(0xFFCCCCCC)],
                          ).createShader(bounds),
                          child: const Text(
                            'CO-STORIES®',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF009246), // Italian green
                              Color(0xFFFFFFFF), // White
                              Color(0xFFCE2B37), // Italian red
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'SOTTOCASA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'di Plural sas di Marco Diotallevi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Il tuo portafoglio virtuale di quartiere',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Glass Login Card - No visible border
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a1f3a).withOpacity(0.4),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Email field with suggestions
                                  Column(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: Colors.black87),
                                          decoration: const InputDecoration(
                                            labelText: 'Email',
                                            labelStyle: TextStyle(color: Colors.black54),
                                            prefixIcon: Icon(Icons.email, color: Colors.black54),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              if (value.length >= 2) {
                                                _emailSuggestions = _commonEmails
                                                    .where((email) => email.toLowerCase().contains(value.toLowerCase()))
                                                    .toList();
                                                _showSuggestions = _emailSuggestions.isNotEmpty;
                                              } else {
                                                _showSuggestions = false;
                                              }
                                            });
                                          },
                                          onTap: () {
                                            if (_emailController.text.isEmpty) {
                                              setState(() {
                                                _emailSuggestions = _commonEmails;
                                                _showSuggestions = true;
                                              });
                                            }
                                          },
                                          validator: (v) => v == null || v.isEmpty ? 'Email richiesta' : null,
                                        ),
                                      ),
                                      
                                      // Suggestions dropdown
                                      if (_showSuggestions && _emailSuggestions.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 8),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.95),
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            children: _emailSuggestions.take(5).map((email) {
                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _emailController.text = email;
                                                    _showSuggestions = false;
                                                  });
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                                  decoration: BoxDecoration(
                                                    border: Border(
                                                      bottom: BorderSide(
                                                        color: Colors.grey.withOpacity(0.2),
                                                        width: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.person, size: 18, color: Colors.black54),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          email,
                                                          style: const TextStyle(
                                                            color: Colors.black87,
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ),
                                                      const Icon(Icons.arrow_forward, size: 16, color: Colors.black38),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Password field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: const TextStyle(color: Colors.black87),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(color: Colors.black54),
                                        prefixIcon: const Icon(Icons.lock, color: Colors.black54),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                            color: Colors.black54,
                                          ),
                                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      ),
                                      validator: (v) => v == null || v.isEmpty ? 'Password richiesta' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Login button - Clean transparent
                                  Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.15),
                                          Colors.white.withOpacity(0.05),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
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
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Register link
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/registrazione'),
                          child: Text(
                            'Non hai un account? Registrati',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
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
      ),
    );
  }
}


