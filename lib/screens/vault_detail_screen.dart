import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/saved_outfit.dart';
import '../services/vault_service.dart';
import '../widgets/suggestion_chip.dart';

class VaultDetailScreen extends StatefulWidget {
  final SavedOutfit outfit;
  const VaultDetailScreen({super.key, required this.outfit});
  @override
  State<VaultDetailScreen> createState() => _VaultDetailScreenState();
}

class _VaultDetailScreenState extends State<VaultDetailScreen>
    with SingleTickerProviderStateMixin {
  late SavedOutfit _outfit;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _outfit = widget.outfit;
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _toggleFav() async {
    await VaultService.instance.toggleFavorite(_outfit.id);
    final all = await VaultService.instance.loadAll();
    final updated = all.firstWhere(
      (o) => o.id == _outfit.id,
      orElse: () => _outfit,
    );
    setState(() => _outfit = updated);
  }

  @override
  Widget build(BuildContext context) {
    final score = _outfit.analysis.styleScore;
    final scoreColor = score >= 80
        ? AppTheme.success
        : score >= 60
        ? AppTheme.iceDeep
        : AppTheme.warning;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
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
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.ink,
                  size: 16,
                ),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _toggleFav,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Icon(
                    _outfit.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 18,
                    color: _outfit.isFavorite
                        ? AppTheme.error
                        : AppTheme.inkHint,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  File(_outfit.imagePath).existsSync()
                      ? Image.file(File(_outfit.imagePath), fit: BoxFit.cover)
                      : Container(color: AppTheme.bgSecondary),
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
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              child: Text(
                                _outfit.analysis.stylePersona,
                                style: GoogleFonts.outfit(
                                  color: AppTheme.iceDeep,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (_outfit.tags.isNotEmpty)
                              Wrap(
                                spacing: 6,
                                children: _outfit.tags
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          t,
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 4,
                                backgroundColor: AppTheme.border,
                                valueColor: AlwaysStoppedAnimation(scoreColor),
                                strokeCap: StrokeCap.round,
                              ),
                              Text(
                                '$score',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildOverviewTab(),
                  _buildAnalysisTab(),
                  _buildSuggestionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
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
            Tab(text: 'Tips'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final a = _outfit.analysis;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _tile(Icons.style_outlined, 'Overall Style', a.overallStyle),
        _tile(Icons.palette_outlined, 'Color Palette', a.colorPalette),
        _tile(Icons.event_outlined, 'Best For', a.occasion),
        _tile(Icons.straighten_outlined, 'Fit Assessment', a.fitAssessment),
        _tile(Icons.wb_cloudy_outlined, 'Seasonal Advice', a.seasonalAdvice),
      ],
    );
  }

  Widget _buildAnalysisTab() {
    final a = _outfit.analysis;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _listCard(
          'What Works',
          a.strengths,
          AppTheme.success,
          AppTheme.successBg,
          Icons.check_rounded,
        ),
        const SizedBox(height: 12),
        _listCard(
          'Level It Up',
          a.improvements,
          AppTheme.iceDeep,
          AppTheme.iceDim.withOpacity(0.3),
          Icons.arrow_upward_rounded,
        ),
      ],
    );
  }

  Widget _buildSuggestionsTab() {
    final a = _outfit.analysis;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 40),
      children: [
        _chipSection(
          'Accessory Ideas',
          a.accessorySuggestions,
          Icons.diamond_outlined,
        ),
        const SizedBox(height: 20),
        _chipSection(
          'Try These Looks',
          a.alternativeOutfits,
          Icons.checkroom_outlined,
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppTheme.iceDeep),
          ),
          const SizedBox(width: 12),
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
    ).animate().fadeIn(duration: 400.ms);
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
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .asMap()
              .entries
              .map(
                (e) => StyleChip(label: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: e.key * 50))
                    .scale(begin: const Offset(0.9, 0.9)),
              )
              .toList(),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
