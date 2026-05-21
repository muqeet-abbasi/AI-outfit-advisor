import 'dart:io';
import 'package:ai_outfit_advisor/screens/style_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/outfit_analysis.dart';
import '../models/saved_outfit.dart';
import '../services/vault_service.dart';
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
  bool _saved = false;
  bool _saving = false;

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

  Future<void> _saveToVault() async {
    if (_saved || _saving) return;
    setState(() => _saving = true);

    final outfit = SavedOutfit(
      id: const Uuid().v4(),
      imagePath: widget.image.path,
      analysis: widget.analysis,
      savedAt: DateTime.now(),
    );

    await VaultService.instance.save(outfit);

    if (!mounted) return;
    setState(() {
      _saved = true;
      _saving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Saved to Wardrobe Vault!',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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
            _buildBottomBar(),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.inkMid,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Style Chat button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => StyleChatScreen(
                  image: widget.image,
                  analysis: widget.analysis,
                ),
                transitionsBuilder: (_, a, __, child) => SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                      ),
                  child: child,
                ),
                transitionDuration: const Duration(milliseconds: 400),
              ),
            ),
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.chat_outlined,
                size: 20,
                color: AppTheme.iceDeep,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Save to vault button
          Expanded(
            child: GestureDetector(
              onTap: _saving ? null : _saveToVault,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                height: 50,
                decoration: BoxDecoration(
                  color: _saved ? AppTheme.success : AppTheme.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saving
                      ? Row(
                          key: const ValueKey('saving'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  AppTheme.ice,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Saving...',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : _saved
                      ? Row(
                          key: const ValueKey('saved'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saved to Vault',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          key: const ValueKey('idle'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.ice,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.save_outlined,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Save to Vault',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // OUTER SOFT CIRCLE
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.12),
                  blurRadius: 22,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),

          // PROGRESS RING
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: AppTheme.border.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),

          // INNER CIRCLE
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color.withOpacity(0.08), width: 1),
            ),
          ),

          // SCORE CONTENT
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                '/100',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  height: 1,
                ),
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
        color: AppTheme.bgSecondary,
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
              color: AppTheme.bgTertiary,
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
