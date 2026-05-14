import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

class OccasionPlan {
  final String occasion;
  final String vibe;
  final List<String> keyPieces;
  final List<String> colors;
  final List<String> avoid;
  final List<String> accessories;
  final String proTip;
  OccasionPlan({
    required this.occasion,
    required this.vibe,
    required this.keyPieces,
    required this.colors,
    required this.avoid,
    required this.accessories,
    required this.proTip,
  });
}

class OccasionPlannerScreen extends StatefulWidget {
  const OccasionPlannerScreen({super.key});
  @override
  State<OccasionPlannerScreen> createState() => _OccasionPlannerScreenState();
}

class _OccasionPlannerScreenState extends State<OccasionPlannerScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  OccasionPlan? _plan;
  String? _error;
  String _selected = '';

  final _presets = [
    ('Job Interview', Icons.work_outline_rounded),
    ('First Date', Icons.favorite_border_rounded),
    ('Wedding Guest', Icons.celebration_outlined),
    ('Beach Day', Icons.wb_sunny_outlined),
    ('Business Meeting', Icons.handshake_outlined),
    ('Night Out', Icons.nightlife_outlined),
    ('Gym Session', Icons.fitness_center_outlined),
    ('Casual Friday', Icons.weekend_outlined),
  ];

  Future<void> _plan_outfit(String occasion) async {
    if (occasion.trim().isEmpty) return;
    setState(() {
      _loading = true;
      _plan = null;
      _error = null;
      _selected = occasion;
    });
    FocusScope.of(context).unfocus();

    final prompt =
        '''
You are an expert fashion stylist. A user needs outfit advice for: "$occasion"

Respond ONLY in this exact JSON format with absolutely no markdown, no backticks, no extra text before or after:
{
  "vibe": "2-3 word aesthetic description",
  "keyPieces": ["piece 1", "piece 2", "piece 3", "piece 4"],
  "colors": ["color 1", "color 2", "color 3"],
  "avoid": ["thing to avoid 1", "thing to avoid 2", "thing to avoid 3"],
  "accessories": ["accessory 1", "accessory 2", "accessory 3"],
  "proTip": "One specific expert tip for this occasion"
}
''';

    const maxAttempts = 3;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }

      try {
        final response = await http
            .post(
              Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GeminiService.apiKey}',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {
                    'parts': [
                      {'text': prompt},
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.7,
                  'maxOutputTokens': 800,
                  'thinkingConfig': {'thinkingBudget': 0},
                },
              }),
            )
            .timeout(const Duration(seconds: 40));

        final statusCode = response.statusCode;

        // Retry silently on server overload or rate limit
        if ((statusCode == 503 || statusCode == 429) &&
            attempt < maxAttempts - 1) {
          continue;
        }

        if (statusCode != 200) {
          throw Exception('API error $statusCode');
        }

        final data = jsonDecode(response.body);

        // Retry if response was cut off
        final finishReason = data['candidates']?[0]?['finishReason'] as String?;
        if (finishReason == 'MAX_TOKENS' && attempt < maxAttempts - 1) {
          continue;
        }

        var text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String?;

        if (text == null || text.trim().isEmpty) {
          throw Exception('Empty response from API');
        }

        // Strip any markdown fences Gemini might add despite instructions
        text = text
            .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'```\s*', multiLine: true), '')
            .trim();

        // Extract JSON object even if Gemini adds surrounding text
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch == null) {
          throw FormatException('No JSON object found in response');
        }

        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

        if (!mounted) return;

        setState(() {
          _plan = OccasionPlan(
            occasion: occasion,
            vibe: json['vibe'] as String? ?? '',
            keyPieces: List<String>.from(json['keyPieces'] ?? []),
            colors: List<String>.from(json['colors'] ?? []),
            avoid: List<String>.from(json['avoid'] ?? []),
            accessories: List<String>.from(json['accessories'] ?? []),
            proTip: json['proTip'] as String? ?? '',
          );
          _loading = false;
        });
        return; // success — exit loop
      } catch (e) {
        // Only show error after all attempts exhausted
        if (attempt == maxAttempts - 1) {
          if (mounted) {
            setState(() {
              if (e is TimeoutException) {
                _error =
                    'Request timed out. Check your connection and try again.';
              } else if (e is FormatException) {
                _error = 'Could not parse AI response. Please try again.';
              } else {
                _error = 'Could not generate plan. Please try again.';
              }
              _loading = false;
            });
          }
        }
        // Otherwise loop continues to next attempt silently
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildInputSection(),
                    const SizedBox(height: 24),
                    _buildPresets(),
                    const SizedBox(height: 24),
                    if (_loading) _buildLoadingCard(),
                    if (_error != null) _buildErrorCard(),
                    if (_plan != null) _buildPlanResult(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OCCASION',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 400.ms),
              Text(
                'Planner',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 80.ms),
            ],
          ),
          Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              )
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.7, 0.7)),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s the occasion?',
          style: GoogleFonts.outfit(
            color: AppTheme.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 4),
        Text(
          'Type any event or pick from below',
          style: GoogleFonts.outfit(color: AppTheme.inkHint, fontSize: 13),
        ).animate().fadeIn(delay: 80.ms),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: _plan_outfit,
                  style: GoogleFonts.outfit(color: AppTheme.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Museum date, Job interview...',
                    hintStyle: GoogleFonts.outfit(
                      color: AppTheme.inkHint,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    prefixIcon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: AppTheme.inkHint,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _plan_outfit(_ctrl.text),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 150.ms),
      ],
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK SELECT',
          style: GoogleFonts.outfit(
            color: AppTheme.inkHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.8,
          children: _presets.asMap().entries.map((e) {
            final i = e.key;
            final preset = e.value;
            final active = _selected == preset.$1;
            return GestureDetector(
                  onTap: () {
                    _ctrl.text = preset.$1;
                    _plan_outfit(preset.$1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.ink : AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active ? AppTheme.ink : AppTheme.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          preset.$2,
                          size: 16,
                          color: active ? AppTheme.ice : AppTheme.inkMid,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            preset.$1,
                            style: GoogleFonts.outfit(
                              color: active ? Colors.white : AppTheme.inkMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(
                  delay: Duration(milliseconds: 200 + i * 50),
                  duration: 400.ms,
                )
                .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOut);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1500.ms, color: AppTheme.ice.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Planning your outfit...',
            style: GoogleFonts.outfit(
              color: AppTheme.ink,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'AI is crafting the perfect look for\n"$_selected"',
            style: GoogleFonts.outfit(
              color: AppTheme.inkHint,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          LinearProgressIndicator(
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation(AppTheme.ice),
                borderRadius: BorderRadius.circular(4),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: AppTheme.iceDim),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => _plan_outfit(_selected),
            child: Text(
              'Retry',
              style: GoogleFonts.outfit(
                color: AppTheme.iceDeep,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildPlanResult() {
    final plan = _plan!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.ice.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'OUTFIT PLAN',
                  style: GoogleFonts.outfit(
                    color: AppTheme.ice,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                plan.occasion,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                plan.vibe,
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),

        const SizedBox(height: 16),

        _resultSection(
          icon: Icons.checkroom_outlined,
          title: 'Key Pieces',
          accent: AppTheme.iceDeep,
          bg: AppTheme.iceDim.withOpacity(0.2),
          items: plan.keyPieces,
          bullet: true,
        ),

        const SizedBox(height: 12),

        _colorSection(plan.colors),

        const SizedBox(height: 12),

        _resultSection(
          icon: Icons.diamond_outlined,
          title: 'Accessories',
          accent: AppTheme.success,
          bg: AppTheme.successBg,
          items: plan.accessories,
          bullet: true,
        ),

        const SizedBox(height: 12),

        _resultSection(
          icon: Icons.not_interested_rounded,
          title: 'Avoid',
          accent: AppTheme.error,
          bg: AppTheme.error.withOpacity(0.05),
          items: plan.avoid,
          bullet: true,
        ),

        const SizedBox(height: 12),

        // Pro tip
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.warning.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.tips_and_updates_outlined,
                  size: 17,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRO TIP',
                      style: GoogleFonts.outfit(
                        color: AppTheme.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      plan.proTip,
                      style: GoogleFonts.outfit(
                        color: AppTheme.inkMid,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

        const SizedBox(height: 16),

        // Try another
        GestureDetector(
          onTap: () {
            setState(() {
              _plan = null;
              _selected = '';
              _ctrl.clear();
            });
          },
          child: Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Center(
              child: Text(
                'Plan Another Occasion',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkMid,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _resultSection({
    required IconData icon,
    required String title,
    required Color accent,
    required Color bg,
    required List<String> items,
    bool bullet = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: accent),
              ),
              const SizedBox(width: 10),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: accent,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.asMap().entries.map(
            (e) =>
                Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.only(top: 6, right: 10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(0.5),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: GoogleFonts.outfit(
                                color: AppTheme.inkMid,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: e.key * 60),
                      duration: 350.ms,
                    )
                    .slideX(begin: 0.05),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08);
  }

  Widget _colorSection(List<String> colors) {
    final colorMap = {
      'black': const Color(0xFF111111),
      'white': const Color(0xFFF5F5F5),
      'navy': const Color(0xFF1B2A4A),
      'blue': const Color(0xFF3B82F6),
      'light blue': const Color(0xFF93C5FD),
      'grey': const Color(0xFF9CA3AF),
      'gray': const Color(0xFF9CA3AF),
      'brown': const Color(0xFF92400E),
      'beige': const Color(0xFFD4B896),
      'cream': const Color(0xFFFDF6EC),
      'red': const Color(0xFFEF4444),
      'burgundy': const Color(0xFF9F1239),
      'green': const Color(0xFF22C55E),
      'olive': const Color(0xFF7A8450),
      'pink': const Color(0xFFF472B6),
      'purple': const Color(0xFFA855F7),
      'yellow': const Color(0xFFFBBF24),
      'orange': const Color(0xFFF97316),
      'gold': const Color(0xFFD4A017),
      'silver': const Color(0xFFC0C0C0),
      'camel': const Color(0xFFC19A6B),
      'blush': const Color(0xFFFFB6C1),
      'teal': const Color(0xFF14B8A6),
      'charcoal': const Color(0xFF374151),
      'khaki': const Color(0xFFC3B091),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.iceDeep.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.palette_outlined,
                  size: 15,
                  color: AppTheme.iceDeep,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'COLOR PALETTE',
                style: GoogleFonts.outfit(
                  color: AppTheme.iceDeep,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: colors.map((c) {
              final key = c.toLowerCase().trim();
              final swatch = colorMap[key] ?? AppTheme.chrome;
              final isDark = swatch.computeLuminance() < 0.4;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.08),
                      width: 0.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      c,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms);
  }
}
