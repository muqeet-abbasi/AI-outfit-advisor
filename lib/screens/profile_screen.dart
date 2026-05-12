import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 28),
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatsRow(),
              const SizedBox(height: 32),
              _buildSettingsSection(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTheme.ink,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.ice.withOpacity(0.4), width: 2),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 40,
          ),
        ).animate().scale(
          begin: const Offset(0.6, 0.6),
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        const SizedBox(height: 14),
        Text(
          'Fashion Explorer',
          style: GoogleFonts.outfit(
            color: AppTheme.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.ice.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.ice.withOpacity(0.3)),
          ),
          child: Text(
            'Free Plan',
            style: GoogleFonts.outfit(
              color: AppTheme.iceDeep,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildStatsRow() {
    final stats = [
      ('0', 'Outfits\nAnalyzed'),
      ('0', 'Avg\nScore'),
      ('0', 'Tips\nSaved'),
    ];
    return Row(
      children: stats.asMap().entries.map((e) {
        final i = e.key;
        final s = e.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i > 0 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                  ).createShader(b),
                  child: Text(
                    s.$1,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.$2,
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 11,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 300 + i * 80)),
        );
      }).toList(),
    );
  }

  Widget _buildSettingsSection() {
    final items = [
      (Icons.notifications_outlined, 'Notifications', true),
      (Icons.color_lens_outlined, 'Style Preferences', true),
      (Icons.share_outlined, 'Share App', false),
      (Icons.star_outline_rounded, 'Rate Us', false),
      (Icons.help_outline_rounded, 'Help & Support', false),
      (Icons.info_outline_rounded, 'About StyleAI', false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: GoogleFonts.outfit(
            color: AppTheme.inkHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final last = i == items.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppTheme.bgTertiary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            item.$1,
                            size: 17,
                            color: AppTheme.inkMid,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.$2,
                            style: GoogleFonts.outfit(
                              color: AppTheme.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (item.$3)
                          Switch.adaptive(
                            value: false,
                            onChanged: (_) {},
                            activeColor: AppTheme.iceDeep,
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: AppTheme.inkHint,
                          ),
                      ],
                    ),
                  ),
                  if (!last) Divider(height: 1, color: AppTheme.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }
}
