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
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              _buildProfileCard(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),
                    _buildSection('ACCOUNT', [
                      _SettingItem(
                        Icons.notifications_outlined,
                        'Notifications',
                        trailing: _toggle(false),
                      ),
                      _SettingItem(
                        Icons.color_lens_outlined,
                        'Style Preferences',
                        trailing: _arrow(),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildSection('GENERAL', [
                      _SettingItem(
                        Icons.share_outlined,
                        'Share App',
                        trailing: _arrow(),
                      ),
                      _SettingItem(
                        Icons.star_outline_rounded,
                        'Rate Us',
                        trailing: _arrow(),
                      ),
                      _SettingItem(
                        Icons.help_outline_rounded,
                        'Help & Support',
                        trailing: _arrow(),
                      ),
                      _SettingItem(
                        Icons.info_outline_rounded,
                        'About StyleAI',
                        trailing: _arrow(),
                        last: true,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    _buildVersionTag(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 400.ms),
              Text(
                'Profile',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 60.ms),
            ],
          ),
          // Edit button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 17,
              color: AppTheme.inkMid,
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fashion Explorer',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'user@styleai.app',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Plan badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.ice.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.ice.withOpacity(0.3)),
                  ),
                  child: Text(
                    'FREE',
                    style: GoogleFonts.outfit(
                      color: AppTheme.ice,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 150.ms, duration: 500.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }

  // ── Settings section ─────────────────────────────────────────────
  Widget _buildSection(String label, List<_SettingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.ice,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.inkHint,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Items container
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
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Icon(item.icon, size: 19, color: AppTheme.inkMid),
                        const SizedBox(width: 14),
                        // Label
                        Expanded(
                          child: Text(
                            item.label,
                            style: GoogleFonts.outfit(
                              color: AppTheme.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // Trailing
                        item.trailing,
                      ],
                    ),
                  ),
                  if (!item.last)
                    Divider(height: 1, indent: 49, color: AppTheme.border),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  // ── Version tag ──────────────────────────────────────────────────
  Widget _buildVersionTag() {
    return Center(
      child: Text(
        'StyleAI v1.0.0 — Powered by Gemini Vision',
        style: GoogleFonts.outfit(
          color: AppTheme.inkHint.withOpacity(0.5),
          fontSize: 11,
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _toggle(bool value) {
    return Transform.scale(
      scale: 0.7, // adjust size here
      child: Switch.adaptive(
        value: value,
        onChanged: (_) {},
        activeColor: AppTheme.iceDeep,
      ),
    );
  }

  Widget _arrow() {
    return const Icon(
      Icons.arrow_forward_ios_rounded,
      size: 13,
      color: AppTheme.inkHint,
    );
  }
}

class _SettingItem {
  final IconData icon;
  final String label;
  final Widget trailing;
  final bool last;

  const _SettingItem(
    this.icon,
    this.label, {
    required this.trailing,
    this.last = false,
  });
}
