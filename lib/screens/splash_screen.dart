import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) => const OnboardingScreen(),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo mark
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.ice,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF7DD3FC), Color(0xFFFFFFFF)],
                  ).createShader(b),
                  child: Text(
                    'StyleAI',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2,
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms)
                .slideY(begin: 0.3, curve: Curves.easeOut),

            const SizedBox(height: 8),

            Text(
              'Your AI Fashion Advisor',
              style: GoogleFonts.outfit(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 500.ms),

            const SizedBox(height: 60),

            // Loading bar
            Container(
              width: 120,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, __) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _ctrl.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.ice,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ).animate().fadeIn(delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
