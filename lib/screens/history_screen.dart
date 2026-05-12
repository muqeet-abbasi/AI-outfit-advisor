import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HISTORY',
                    style: GoogleFonts.outfit(
                      color: AppTheme.inkHint,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 6),
                  Text(
                    'Past Analyses',
                    style: GoogleFonts.outfit(
                      color: AppTheme.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.bgSecondary,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            size: 36,
                            color: AppTheme.inkHint,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 500.ms)
                        .scale(begin: const Offset(0.7, 0.7)),
                    const SizedBox(height: 20),
                    Text(
                      'No analyses yet',
                      style: GoogleFonts.outfit(
                        color: AppTheme.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Your past outfit analyses\nwill appear here',
                      style: GoogleFonts.outfit(
                        color: AppTheme.inkHint,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
