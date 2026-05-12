import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/gemini_service.dart';
import '../models/outfit_analysis.dart';
import '../widgets/loading_overlay.dart';
import 'result_screen.dart';

class AnalyzeScreen extends StatefulWidget {
  const AnalyzeScreen({super.key});
  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen>
    with TickerProviderStateMixin {
  File? _image;
  bool _loading = false;
  String _loadingMsg = '';
  final _picker = ImagePicker();
  final _service = GeminiService();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    try {
      final f = await _picker.pickImage(
        source: src,
        imageQuality: 90,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (f != null) setState(() => _image = File(f.path));
    } catch (_) {
      _err('Cannot access ${src == ImageSource.camera ? 'camera' : 'gallery'}');
    }
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _loading = true;
      _loadingMsg = 'Reading your style...';
    });
    try {
      await Future.delayed(800.ms);
      setState(() => _loadingMsg = 'Consulting AI stylist...');
      final raw = await _service.analyzeOutfit(_image!);
      setState(() => _loadingMsg = 'Building your report...');
      await Future.delayed(500.ms);
      final analysis = OutfitAnalysis.fromText(raw);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a, __) =>
              ResultScreen(image: _image!, analysis: analysis),
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      _err(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _err(String msg) {
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
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bg,
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        _buildImageZone(),
                        const SizedBox(height: 24),
                        _buildSourceButtons(),
                        if (_image != null) ...[
                          const SizedBox(height: 20),
                          _buildAnalyzeButton(),
                        ],
                        const SizedBox(height: 32),
                        _buildChecklist(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_loading) LoadingOverlay(message: _loadingMsg),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.inkMid,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Analyze Outfit',
            style: GoogleFonts.outfit(
              color: AppTheme.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageZone() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      height: _image != null ? 380 : 200,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _image != null
              ? AppTheme.ice.withOpacity(0.5)
              : AppTheme.border,
          width: _image != null ? 1.5 : 1,
        ),
        boxShadow: _image != null
            ? [
                BoxShadow(
                  color: AppTheme.ice.withOpacity(0.12),
                  blurRadius: 28,
                  spreadRadius: -4,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: _image != null ? _imagePreview() : _emptyZone(),
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _imagePreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(_image!, fit: BoxFit.cover),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 14,
          left: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'READY',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14,
          right: 14,
          child: GestureDetector(
            onTap: () => _showSheet(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Change',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyZone() {
    return GestureDetector(
      onTap: () => _pick(ImageSource.gallery),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.ice.withOpacity(
                      0.08 + _pulseCtrl.value * 0.06,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.ice.withOpacity(
                        0.2 + _pulseCtrl.value * 0.2,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: AppTheme.ice.withOpacity(
                      0.6 + _pulseCtrl.value * 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Upload Your Outfit',
                  style: GoogleFonts.outfit(
                    color: AppTheme.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to browse gallery',
                  style: GoogleFonts.outfit(
                    color: AppTheme.inkHint,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceButtons() {
    return Row(
      children: [
        Expanded(
          child: _srcBtn(
            Icons.photo_library_outlined,
            'Gallery',
            () => _pick(ImageSource.gallery),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _srcBtn(
            Icons.camera_alt_outlined,
            'Camera',
            () => _pick(ImageSource.camera),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _srcBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.iceDeep),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppTheme.inkMid,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return GestureDetector(
          onTap: _analyze,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.ink,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.ink.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle shimmer stripe
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Align(
                      alignment: Alignment(-1.5 + _pulseCtrl.value * 3, 0),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppTheme.ice.withOpacity(0.07),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Label
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.ice,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Center(
                      child: Text(
                        'Analyze My Outfit',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.15, curve: Curves.easeOut);
  }

  Widget _buildChecklist() {
    final items = [
      ('Full body photo works best', Icons.check_circle_outline_rounded, true),
      (
        'Good lighting improves accuracy',
        Icons.check_circle_outline_rounded,
        true,
      ),
      (
        'Include accessories in frame',
        Icons.check_circle_outline_rounded,
        true,
      ),
      ('Max file size: 4MB', Icons.info_outline_rounded, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHECKLIST',
          style: GoogleFonts.outfit(
            color: AppTheme.inkHint,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Padding(
                padding: EdgeInsets.only(bottom: i < items.length - 1 ? 14 : 0),
                child: Row(
                  children: [
                    Icon(
                      item.$2,
                      size: 18,
                      color: item.$3 ? AppTheme.success : AppTheme.inkHint,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      item.$1,
                      style: GoogleFonts.outfit(
                        color: item.$3 ? AppTheme.inkMid : AppTheme.inkHint,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms);
  }

  void _showSheet() {
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
            const SizedBox(height: 24),
            Text(
              'Change Photo',
              style: GoogleFonts.outfit(
                color: AppTheme.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _srcBtn(Icons.photo_library_outlined, 'Gallery', () {
                    Navigator.pop(context);
                    _pick(ImageSource.gallery);
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _srcBtn(Icons.camera_alt_outlined, 'Camera', () {
                    Navigator.pop(context);
                    _pick(ImageSource.camera);
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
