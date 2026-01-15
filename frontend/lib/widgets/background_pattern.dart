import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Background with animated pattern
class BackgroundPattern extends StatefulWidget {
  final Widget child;
  final String theme; // 'wallet', 'store', 'transaction'

  const BackgroundPattern({
    super.key,
    required this.child,
    this.theme = 'wallet',
  });

  @override
  State<BackgroundPattern> createState() => _BackgroundPatternState();
}

class _BackgroundPatternState extends State<BackgroundPattern> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getThemeColors(),
            ),
          ),
        ),

        // Animated pattern overlay
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _PatternPainter(
                animation: _controller.value,
                theme: widget.theme,
              ),
              size: Size.infinite,
            );
          },
        ),

        // Dark overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),

        // Content
        widget.child,
      ],
    );
  }

  List<Color> _getThemeColors() {
    switch (widget.theme) {
      case 'wallet':
        return const [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)];
      case 'store':
        return const [Color(0xFF2E1A47), Color(0xFF3D2C5A), Color(0xFF1E0E2E)];
      case 'transaction':
        return const [Color(0xFF1A472A), Color(0xFF2C5A3D), Color(0xFF0E2E1E)];
      default:
        return const [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)];
    }
  }
}

class _PatternPainter extends CustomPainter {
  final double animation;
  final String theme;

  _PatternPainter({required this.animation, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw floating coins/money symbols
    for (int i = 0; i < 15; i++) {
      final x = (size.width / 5) * (i % 5) + math.sin(animation * math.pi * 2 + i) * 30;
      final y = (size.height / 3) * (i ~/ 5) + math.cos(animation * math.pi * 2 + i) * 40;
      
      paint.color = const Color(0xFFFFD700).withOpacity(0.03 + math.sin(animation * math.pi * 2 + i) * 0.02);
      
      // Draw coin
      canvas.drawCircle(Offset(x, y), 20, paint);
      
      // Draw inner circle
      paint.color = Colors.white.withOpacity(0.02);
      canvas.drawCircle(Offset(x, y), 12, paint);
    }

    // Draw store icons
    if (theme == 'store') {
      for (int i = 0; i < 10; i++) {
        final x = (size.width / 4) * (i % 4) + math.sin(animation * math.pi + i) * 20;
        final y = (size.height / 3) * (i ~/ 4) + math.cos(animation * math.pi + i) * 30;
        
        paint.color = const Color(0xFF8B5CF6).withOpacity(0.04);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 30, height: 30),
            const Radius.circular(8),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) => true;
}

/// Glass morphism card
class GlassMorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;

  const GlassMorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.blur = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

