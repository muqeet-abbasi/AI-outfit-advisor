import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = [
    _OnboardPage(
      icon: Icons.camera_alt_outlined,
      color: Color(0xFF38BDF8),
      title: 'Snap Your\nOutfit',
      subtitle:
          'Upload any photo of your look — full body shots work best for the most accurate analysis.',
      bg: Color(0xFFE0F2FE),
    ),
    _OnboardPage(
      icon: Icons.auto_awesome_rounded,
      color: Color(0xFF0284C7),
      title: 'AI Reads\nYour Style',
      subtitle:
          'Gemini Vision analyzes color harmony, fit, occasion suitability, and your unique style persona.',
      bg: Color(0xFFF0F9FF),
    ),
    _OnboardPage(
      icon: Icons.star_rounded,
      color: Color(0xFF0F172A),
      title: 'Get Expert\nAdvice',
      subtitle:
          'Receive a detailed style report with actionable tips, accessory ideas, and outfit alternatives.',
      bg: Color(0xFFF8FAFC),
    ),
  ];

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const MainShell(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _buildPage(_pages[i], i),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 48),
              child: Column(
                children: [
                  // Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? AppTheme.ink : AppTheme.chrome,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      if (_page < 2) ...[
                        GestureDetector(
                          onTap: _goHome,
                          child: Text(
                            'Skip',
                            style: GoogleFonts.outfit(
                              color: AppTheme.inkHint,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                      Expanded(
                        flex: _page < 2 ? 0 : 1,
                        child: GestureDetector(
                          onTap: _next,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: _page == 2 ? double.infinity : null,
                            padding: EdgeInsets.symmetric(
                              horizontal: _page == 2 ? 0 : 28,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.ink,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _page == 2 ? 'Get Started' : 'Next',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardPage p, int i) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 160),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large icon card
            Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: p.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Icon(p.icon, size: 48, color: p.color),
                    ),
                  ),
                )
                .animate(key: ValueKey(i))
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut),

            const SizedBox(height: 40),

            Text(
                  p.title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.ink,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                )
                .animate(key: ValueKey('t$i'))
                .fadeIn(delay: 150.ms, duration: 500.ms)
                .slideY(begin: 0.2, curve: Curves.easeOut),

            const SizedBox(height: 16),

            Text(
                  p.subtitle,
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkLight,
                    fontSize: 15,
                    height: 1.7,
                  ),
                )
                .animate(key: ValueKey('s$i'))
                .fadeIn(delay: 250.ms, duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final Color color, bg;
  final String title, subtitle;
  const _OnboardPage({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
  });
}
