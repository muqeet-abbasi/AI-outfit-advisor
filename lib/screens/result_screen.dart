import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/outfit_analysis.dart';
import '../widgets/suggestion_chip.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final OutfitAnalysis analysis;
  const ResultScreen({super.key, required this.image, required this.analysis});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [_buildAppBar()],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(analysis: widget.analysis),
                  _AnalysisTab(analysis: widget.analysis),
                  _SuggestionsTab(analysis: widget.analysis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 360,
      pinned: true,
      backgroundColor: AppTheme.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.ink,
            size: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.image, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.4, 1.0],
                  colors: [Colors.transparent, AppTheme.bg],
                ),
              ),
            ),
            // Score overlay
            Positioned(
              bottom: 24,
              left: 22,
              right: 22,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.ice.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.ice.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 12,
                              color: AppTheme.iceDeep,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.analysis.stylePersona,
                              style: GoogleFonts.outfit(
                                color: AppTheme.iceDeep,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _ScoreRing(score: widget.analysis.styleScore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabs,
            indicator: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.inkLight,
            labelStyle: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Analysis'),
              Tab(text: 'Suggestions'),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score Ring ──
class _ScoreRing extends StatelessWidget {
  final int score;
  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 80
        ? AppTheme.success
        : score >= 60
        ? AppTheme.iceDeep
        : AppTheme.warning;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100,
            strokeWidth: 4,
            backgroundColor: AppTheme.border,
            valueColor: AlwaysStoppedAnimation(color),
            strokeCap: StrokeCap.round,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/ 100',
                style: GoogleFonts.outfit(color: AppTheme.inkHint, fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Overview ──
class _OverviewTab extends StatelessWidget {
  final OutfitAnalysis analysis;
  const _OverviewTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _tile(Icons.style_outlined, 'Overall Style', analysis.overallStyle),
        _tile(Icons.palette_outlined, 'Color Palette', analysis.colorPalette),
        _tile(Icons.event_outlined, 'Best For', analysis.occasion),
        _tile(
          Icons.straighten_outlined,
          'Fit Assessment',
          analysis.fitAssessment,
        ),
        _tile(
          Icons.wb_cloudy_outlined,
          'Seasonal Advice',
          analysis.seasonalAdvice,
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgTertiary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.iceDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content,
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
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.03);
  }
}

// ── Tab 2: Analysis ──
class _AnalysisTab extends StatelessWidget {
  final OutfitAnalysis analysis;
  const _AnalysisTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final score = analysis.styleScore;
    final color = score >= 80
        ? AppTheme.success
        : score >= 60
        ? AppTheme.iceDeep
        : AppTheme.warning;
    final label = score >= 85
        ? 'Runway Ready'
        : score >= 70
        ? 'Very Stylish'
        : score >= 55
        ? 'Looking Good'
        : 'Needs Refresh';

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        // Score bar card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFF7DD3FC), Color(0xFF38BDF8)],
                    ).createShader(b),
                    child: Text(
                      '$score',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Style Score',
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 6,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF38BDF8)),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),

        const SizedBox(height: 16),
        _listCard(
          'What Works',
          analysis.strengths,
          AppTheme.success,
          AppTheme.successBg,
          Icons.check_rounded,
        ),
        const SizedBox(height: 12),
        _listCard(
          'Level It Up',
          analysis.improvements,
          AppTheme.iceDeep,
          AppTheme.iceDim.withOpacity(0.3),
          Icons.arrow_upward_rounded,
        ),
      ],
    );
  }

  Widget _listCard(
    String title,
    List<String> items,
    Color accent,
    Color bg,
    IconData icon,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
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
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(top: 6, right: 10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withOpacity(0.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.outfit(
                        color: AppTheme.inkMid,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06);
  }
}

// ── Tab 3: Suggestions ──
class _SuggestionsTab extends StatelessWidget {
  final OutfitAnalysis analysis;
  const _SuggestionsTab({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _chipSection(
          'Accessory Ideas',
          analysis.accessorySuggestions,
          Icons.diamond_outlined,
        ),
        const SizedBox(height: 20),
        _chipSection(
          'Try These Looks',
          analysis.alternativeOutfits,
          Icons.checkroom_outlined,
        ),
      ],
    );
  }

  Widget _chipSection(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.ice.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: AppTheme.iceDeep),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .asMap()
              .entries
              .map(
                (e) => StyleChip(label: e.value)
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: e.key * 60),
                      duration: 300.ms,
                    )
                    .scale(begin: const Offset(0.9, 0.9)),
              )
              .toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
