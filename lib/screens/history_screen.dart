import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/saved_outfit.dart';
import '../services/vault_service.dart';
import 'vault_detail_screen.dart';

enum _Filter { all, favorites, highScore, casual, formal, sport }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SavedOutfit> _outfits = [];
  List<SavedOutfit> _filtered = [];
  _Filter _filter = _Filter.all;
  bool _loading = true;
  String _search = '';

  final _filterLabels = {
    _Filter.all: 'All',
    _Filter.favorites: '♥ Saved',
    _Filter.highScore: '80+ Score',
    _Filter.casual: 'Casual',
    _Filter.formal: 'Formal',
    _Filter.sport: 'Sport',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await VaultService.instance.loadAll();
    setState(() {
      _outfits = all;
      _loading = false;
    });
    _applyFilter();
  }

  void _applyFilter() {
    var list = List<SavedOutfit>.from(_outfits);

    // Search
    if (_search.isNotEmpty) {
      list = list
          .where(
            (o) =>
                o.analysis.stylePersona.toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                o.analysis.occasion.toLowerCase().contains(
                  _search.toLowerCase(),
                ) ||
                o.tags.any(
                  (t) => t.toLowerCase().contains(_search.toLowerCase()),
                ),
          )
          .toList();
    }

    // Filter
    switch (_filter) {
      case _Filter.favorites:
        list = list.where((o) => o.isFavorite).toList();
        break;
      case _Filter.highScore:
        list = list.where((o) => o.analysis.styleScore >= 80).toList();
        break;
      case _Filter.casual:
        list = list
            .where(
              (o) =>
                  o.analysis.occasion.toLowerCase().contains('casual') ||
                  o.tags.contains('casual'),
            )
            .toList();
        break;
      case _Filter.formal:
        list = list
            .where(
              (o) =>
                  o.analysis.occasion.toLowerCase().contains('formal') ||
                  o.tags.contains('formal'),
            )
            .toList();
        break;
      case _Filter.sport:
        list = list
            .where(
              (o) =>
                  o.analysis.occasion.toLowerCase().contains('sport') ||
                  o.tags.contains('sport'),
            )
            .toList();
        break;
      case _Filter.all:
        break;
    }

    setState(() => _filtered = list);
  }

  Future<void> _delete(String id) async {
    await VaultService.instance.delete(id);
    _load();
  }

  Future<void> _toggleFav(String id) async {
    await VaultService.instance.toggleFavorite(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            const SizedBox(height: 4),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : _filtered.isEmpty
                  ? _buildEmpty()
                  : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WARDROBE',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ).animate().fadeIn(duration: 400.ms),
              Text(
                'Vault',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ).animate().fadeIn(delay: 80.ms),
            ],
          ),
          Row(
            children: [
              _statPill('${_outfits.length}', 'Looks'),
              const SizedBox(width: 8),
              FutureBuilder<double>(
                future: VaultService.instance.averageScore(),
                builder: (_, snap) => _statPill(
                  snap.hasData ? snap.data!.toStringAsFixed(0) : '—',
                  'Avg',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statPill(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            val,
            style: GoogleFonts.outfit(
              color: AppTheme.iceDeep,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(color: AppTheme.inkHint, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search_rounded, size: 18, color: AppTheme.inkHint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                onChanged: (v) {
                  _search = v;
                  _applyFilter();
                },
                style: GoogleFonts.outfit(color: AppTheme.ink, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by persona, occasion, tag...',
                  hintStyle: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        children: _filterLabels.entries.map((e) {
          final active = _filter == e.key;
          return GestureDetector(
            onTap: () {
              setState(() => _filter = e.key);
              _applyFilter();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppTheme.ink : AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppTheme.ink : AppTheme.border,
                ),
              ),
              child: Text(
                e.value,
                style: GoogleFonts.outfit(
                  color: active ? Colors.white : AppTheme.inkMid,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildOutfitCard(_filtered[i], i),
    );
  }

  Widget _buildOutfitCard(SavedOutfit outfit, int i) {
    final score = outfit.analysis.styleScore;
    final scoreColor = score >= 80
        ? AppTheme.success
        : score >= 60
        ? AppTheme.iceDeep
        : AppTheme.warning;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VaultDetailScreen(outfit: outfit)),
        );
        _load();
      },
      onLongPress: () => _showOptions(outfit),
      child:
          Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            File(outfit.imagePath).existsSync()
                                ? Image.file(
                                    File(outfit.imagePath),
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppTheme.bgSecondary,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: AppTheme.inkHint,
                                    ),
                                  ),
                            // Score badge
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.92),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$score',
                                  style: GoogleFonts.outfit(
                                    color: scoreColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                            // Fav button
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _toggleFav(outfit.id),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    outfit.isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 15,
                                    color: outfit.isFavorite
                                        ? AppTheme.error
                                        : AppTheme.inkHint,
                                  ),
                                ),
                              ),
                            ),
                            // Bottom fade
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Info
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              outfit.analysis.stylePersona,
                              style: GoogleFonts.outfit(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(outfit.savedAt),
                              style: GoogleFonts.outfit(
                                color: AppTheme.inkHint,
                                fontSize: 10,
                              ),
                            ),
                            if (outfit.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                children: outfit.tags
                                    .take(2)
                                    .map(
                                      (t) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.ice.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          t,
                                          style: GoogleFonts.outfit(
                                            color: AppTheme.iceDeep,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: i * 60),
                duration: 400.ms,
              )
              .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOut),
    );
  }

  void _showOptions(SavedOutfit outfit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.chrome,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _sheetBtn(
              Icons.favorite_border_rounded,
              outfit.isFavorite ? 'Remove from Saved' : 'Save as Favorite',
              () {
                Navigator.pop(context);
                _toggleFav(outfit.id);
              },
            ),
            _sheetBtn(Icons.label_outline_rounded, 'Edit Tags', () {
              Navigator.pop(context);
              _showTagEditor(outfit);
            }),
            _sheetBtn(Icons.delete_outline_rounded, 'Delete', () {
              Navigator.pop(context);
              _delete(outfit.id);
            }, color: AppTheme.error),
          ],
        ),
      ),
    );
  }

  Widget _sheetBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color ?? AppTheme.inkMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color ?? AppTheme.inkMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagEditor(SavedOutfit outfit) {
    final tags = List<String>.from(outfit.tags);
    final presets = [
      'casual',
      'formal',
      'sport',
      'evening',
      'work',
      'date',
      'beach',
      'party',
    ];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (_, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 36,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.chrome,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Tags',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: presets.map((p) {
                  final active = tags.contains(p);
                  return GestureDetector(
                    onTap: () => setModalState(() {
                      active ? tags.remove(p) : tags.add(p);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: active ? AppTheme.ink : AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? AppTheme.ink : AppTheme.border,
                        ),
                      ),
                      child: Text(
                        p,
                        style: GoogleFonts.outfit(
                          color: active ? Colors.white : AppTheme.inkMid,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  await VaultService.instance.updateTags(outfit.id, tags);
                  if (mounted) {
                    Navigator.pop(context);
                    _load();
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.ink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Save Tags',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
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
              Icons.checkroom_outlined,
              size: 36,
              color: AppTheme.inkHint,
            ),
          ).animate().scale(
            begin: const Offset(0.7, 0.7),
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 20),
          Text(
            _filter == _Filter.all ? 'Vault is empty' : 'No matches',
            style: GoogleFonts.outfit(
              color: AppTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            _filter == _Filter.all
                ? 'Analyze an outfit and save it\nto build your wardrobe vault'
                : 'Try a different filter',
            style: GoogleFonts.outfit(
              color: AppTheme.inkHint,
              fontSize: 14,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.72,
      children: List.generate(
        4,
        (_) =>
            Container(
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .shimmer(duration: 1200.ms, color: AppTheme.border),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
