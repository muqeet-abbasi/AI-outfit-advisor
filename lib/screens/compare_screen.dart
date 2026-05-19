import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';

class CompareResult {
  final String winner;
  final String reasoning;
  final String outfitAStrengths;
  final String outfitBStrengths;
  final String verdict;
  final int scoreA;
  final int scoreB;

  CompareResult({
    required this.winner,
    required this.reasoning,
    required this.outfitAStrengths,
    required this.outfitBStrengths,
    required this.verdict,
    required this.scoreA,
    required this.scoreB,
  });
}

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen>
    with SingleTickerProviderStateMixin {
  File? _imageA;
  File? _imageB;
  bool _loading = false;
  CompareResult? _result;
  String? _error;
  final _picker = ImagePicker();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(bool isA, ImageSource src) async {
    try {
      final f = await _picker.pickImage(
        source: src,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (f != null) {
        HapticFeedback.lightImpact();
        setState(() {
          if (isA) {
            _imageA = File(f.path);
          } else {
            _imageB = File(f.path);
          }
          _result = null;
        });
      }
    } catch (_) {
      _showErr('Cannot access gallery');
    }
  }

  Future<void> _compare() async {
    if (_imageA == null || _imageB == null) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });

    const maxAttempts = 3;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (attempt > 0) {
        await Future.delayed(Duration(milliseconds: 1000 * attempt));
      }

      try {
        final bytesA = await _imageA!.readAsBytes();
        final bytesB = await _imageB!.readAsBytes();
        final b64A = base64Encode(bytesA);
        final b64B = base64Encode(bytesB);

        final prompt = '''
You are an expert fashion stylist. Compare these two outfits and respond ONLY in 
this exact JSON format with no markdown, no backticks, no extra text:

{
  "winner": "A or B",
  "scoreA": number 0-100,
  "scoreB": number 0-100,
  "outfitAStrengths": "2 sentences about outfit A strengths",
  "outfitBStrengths": "2 sentences about outfit B strengths",
  "reasoning": "2-3 sentences explaining why the winner is better",
  "verdict": "One punchy sentence declaring the winner"
}

The first image is Outfit A, the second image is Outfit B.
''';

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
                      {
                        'inline_data': {
                          'mime_type': 'image/jpeg',
                          'data': b64A,
                        },
                      },
                      {
                        'inline_data': {
                          'mime_type': 'image/jpeg',
                          'data': b64B,
                        },
                      },
                    ],
                  },
                ],
                'generationConfig': {
                  'temperature': 0.6,
                  'maxOutputTokens': 600,
                  'thinkingConfig': {'thinkingBudget': 0},
                },
              }),
            )
            .timeout(const Duration(seconds: 45));

        final statusCode = response.statusCode;
        if ((statusCode == 503 || statusCode == 429) &&
            attempt < maxAttempts - 1) {
          continue;
        }

        if (statusCode != 200) {
          throw Exception('API error $statusCode');
        }

        final data = jsonDecode(response.body);
        var text =
            data['candidates']?[0]?['content']?['parts']?[0]?['text']
                as String? ??
            '';

        text = text
            .replaceAll(RegExp(r'```json\s*', multiLine: true), '')
            .replaceAll(RegExp(r'```\s*', multiLine: true), '')
            .trim();

        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch == null) throw FormatException('No JSON found');

        final json = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _result = CompareResult(
              winner: json['winner'] as String? ?? 'A',
              scoreA: (json['scoreA'] as num?)?.toInt() ?? 70,
              scoreB: (json['scoreB'] as num?)?.toInt() ?? 70,
              outfitAStrengths: json['outfitAStrengths'] as String? ?? '',
              outfitBStrengths: json['outfitBStrengths'] as String? ?? '',
              reasoning: json['reasoning'] as String? ?? '',
              verdict: json['verdict'] as String? ?? '',
            );
            _loading = false;
          });
        }
        return;
      } catch (e) {
        if (attempt == maxAttempts - 1) {
          if (mounted) {
            setState(() {
              _error = e is TimeoutException
                  ? 'Request timed out. Try again.'
                  : 'Could not compare outfits. Please try again.';
              _loading = false;
            });
          }
        }
      }
    }
  }

  void _showErr(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildUploadRow(),
                    const SizedBox(height: 16),
                    _buildCompareButton(),
                    if (_loading) ...[
                      const SizedBox(height: 28),
                      _buildLoadingCard(),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 20),
                      _buildErrorCard(),
                    ],
                    if (_result != null) ...[
                      const SizedBox(height: 28),
                      _buildResult(),
                    ],
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

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 15,
                color: AppTheme.inkMid,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COMPARE',
                style: GoogleFonts.outfit(
                  color: AppTheme.inkHint,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              Text(
                'Outfit Battle',
                style: GoogleFonts.outfit(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.scale_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadRow() {
    return Row(
      children: [
        Expanded(child: _uploadSlot(true, _imageA, 'Outfit A')),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'VS',
            style: GoogleFonts.outfit(
              color: AppTheme.inkHint,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        Expanded(child: _uploadSlot(false, _imageB, 'Outfit B')),
      ],
    );
  }

  Widget _uploadSlot(bool isA, File? image, String label) {
    final hasWon = _result != null && _result!.winner == (isA ? 'A' : 'B');
    final hasLost = _result != null && _result!.winner != (isA ? 'A' : 'B');
    final score = isA ? _result?.scoreA : _result?.scoreB;

    return GestureDetector(
      onTap: () => _showPickSheet(isA),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        height: image != null ? 220 : 160,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasWon
                ? AppTheme.success
                : hasLost
                ? AppTheme.border
                : image != null
                ? AppTheme.ice.withOpacity(0.4)
                : AppTheme.border,
            width: hasWon ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image != null)
                Image.file(image, fit: BoxFit.cover)
              else
                _emptySlot(label),
              if (hasLost) Container(color: Colors.black.withOpacity(0.3)),
              if (hasWon)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child:
                      Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.emoji_events_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'WINNER',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            begin: const Offset(0.7, 0.7),
                            curve: Curves.elasticOut,
                          ),
                ),
              if (score != null)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              if (image != null)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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

  Widget _emptySlot(String label) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.bgTertiary,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: AppTheme.ice.withOpacity(
                    0.15 + _pulseCtrl.value * 0.15,
                  ),
                ),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 22,
                color: AppTheme.inkLight.withOpacity(
                  0.4 + _pulseCtrl.value * 0.3,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Tap to upload',
              style: GoogleFonts.outfit(color: AppTheme.inkHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareButton() {
    final canCompare = _imageA != null && _imageB != null && !_loading;

    return GestureDetector(
      onTap: canCompare ? _compare : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: canCompare ? AppTheme.ink : AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: canCompare ? null : Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: canCompare ? AppTheme.ice : AppTheme.chrome,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 15,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              canCompare ? 'Compare Outfits' : 'Upload both outfits first',
              style: GoogleFonts.outfit(
                color: canCompare ? Colors.white : AppTheme.inkHint,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.ink,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.scale_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1400.ms, color: AppTheme.ice.withOpacity(0.3)),
          const SizedBox(height: 14),
          Text(
            'Comparing outfits...',
            style: GoogleFonts.outfit(
              color: AppTheme.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'AI is analyzing both looks',
            style: GoogleFonts.outfit(color: AppTheme.inkHint, fontSize: 13),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation(AppTheme.ice),
                borderRadius: BorderRadius.circular(4),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: AppTheme.iceDim),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.outfit(color: AppTheme.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: _compare,
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

  // ── REDESIGNED RESULT SECTION ─────────────────────────────────

  Widget _buildResult() {
    final r = _result!;
    final winnerIsA = r.winner == 'A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Winner announcement ───────────────────────────────
        _buildWinnerCard(r, winnerIsA),

        const SizedBox(height: 12),

        // ── Head-to-head score bar ────────────────────────────
        _buildScoreBar(r.scoreA, r.scoreB),

        const SizedBox(height: 12),

        // ── Side-by-side breakdown ────────────────────────────
        _buildBreakdownCards(r, winnerIsA),

        const SizedBox(height: 12),

        // ── AI reasoning ─────────────────────────────────────
        _buildReasoningCard(r.reasoning),

        const SizedBox(height: 16),

        // ── Reset ─────────────────────────────────────────────
        _buildResetButton(),
      ],
    );
  }

  Widget _buildWinnerCard(CompareResult r, bool winnerIsA) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.ink,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row — result label + score chips
              Row(
                children: [
                  // Winner badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.success.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: AppTheme.success,
                          size: 12,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'OUTFIT ${r.winner} WINS',
                          style: GoogleFonts.outfit(
                            color: AppTheme.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Score chips side by side
                  _scoreChip('A', r.scoreA, winnerIsA),
                  const SizedBox(width: 6),
                  _scoreChip('B', r.scoreB, !winnerIsA),
                ],
              ),

              const SizedBox(height: 16),

              // Verdict text
              Text(
                r.verdict,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _scoreChip(String label, int score, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.success.withOpacity(0.18)
            : Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWinner
              ? AppTheme.success.withOpacity(0.35)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isWinner
                  ? AppTheme.success
                  : Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$score',
            style: GoogleFonts.outfit(
              color: isWinner ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(int scoreA, int scoreB) {
    final total = scoreA + scoreB;
    final fracA = total > 0 ? scoreA / total : 0.5;
    final fracB = 1 - fracA;
    final winnerIsA = _result!.winner == 'A';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          // Labels row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: winnerIsA ? AppTheme.iceDeep : AppTheme.chrome,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Outfit A',
                    style: GoogleFonts.outfit(
                      color: AppTheme.inkMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Center score diff label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgTertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(scoreA - scoreB).abs()} pt gap',
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Outfit B',
                    style: GoogleFonts.outfit(
                      color: AppTheme.inkMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: !winnerIsA ? AppTheme.iceDeep : AppTheme.chrome,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Split bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (fracA * 100).round().clamp(5, 95),
                  child: Container(
                    height: 10,
                    color: winnerIsA ? AppTheme.iceDeep : AppTheme.chrome,
                  ),
                ),
                Container(width: 2, height: 10, color: AppTheme.bg),
                Expanded(
                  flex: (fracB * 100).round().clamp(5, 95),
                  child: Container(
                    height: 10,
                    color: !winnerIsA ? AppTheme.iceDeep : AppTheme.chrome,
                  ),
                ),
              ],
            ),
          ).animate().slideX(
            begin: -0.05,
            delay: 200.ms,
            duration: 500.ms,
            curve: Curves.easeOut,
          ),

          const SizedBox(height: 10),

          // Score numbers row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$scoreA',
                style: GoogleFonts.outfit(
                  color: winnerIsA ? AppTheme.iceDeep : AppTheme.inkHint,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              Text(
                '$scoreB',
                style: GoogleFonts.outfit(
                  color: !winnerIsA ? AppTheme.iceDeep : AppTheme.inkHint,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildBreakdownCards(CompareResult r, bool winnerIsA) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _breakdownCard(
            label: 'Outfit A',
            text: r.outfitAStrengths,
            isWinner: winnerIsA,
            image: _imageA,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _breakdownCard(
            label: 'Outfit B',
            text: r.outfitBStrengths,
            isWinner: !winnerIsA,
            image: _imageB,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms, duration: 400.ms);
  }

  Widget _breakdownCard({
    required String label,
    required String text,
    required bool isWinner,
    required File? image,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? AppTheme.success.withOpacity(0.3) : AppTheme.border,
          width: isWinner ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini photo + label header
          if (image != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Stack(
                children: [
                  Image.file(
                    image,
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Dim overlay for loser
                  if (!isWinner)
                    Container(
                      height: 90,
                      color: Colors.black.withOpacity(0.25),
                    ),
                  // Winner crown
                  if (isWinner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Text content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.outfit(
                        color: isWinner ? AppTheme.success : AppTheme.inkLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isWinner) ...[
                      const SizedBox(width: 4),
                      Text(
                        '· Winner',
                        style: GoogleFonts.outfit(
                          color: AppTheme.success.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkMid,
                    fontSize: 12,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasoningCard(String reasoning) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI REASONING',
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  reasoning,
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
    ).animate().fadeIn(delay: 350.ms, duration: 400.ms);
  }

  Widget _buildResetButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _result = null;
          _imageA = null;
          _imageB = null;
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh_rounded, size: 17, color: AppTheme.inkMid),
            const SizedBox(width: 8),
            Text(
              'Compare New Outfits',
              style: GoogleFonts.outfit(
                color: AppTheme.inkMid,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  void _showPickSheet(bool isA) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: AppTheme.chrome,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Upload ${isA ? 'Outfit A' : 'Outfit B'}',
              style: GoogleFonts.outfit(
                color: AppTheme.ink,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pick(isA, ImageSource.gallery);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library_outlined,
                            size: 17,
                            color: AppTheme.iceDeep,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Gallery',
                            style: GoogleFonts.outfit(
                              color: AppTheme.inkMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pick(isA, ImageSource.camera);
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.bgSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 17,
                            color: AppTheme.iceDeep,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Camera',
                            style: GoogleFonts.outfit(
                              color: AppTheme.inkMid,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
