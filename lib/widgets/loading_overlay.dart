import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LoadingOverlay extends StatefulWidget {
  final String message;
  const LoadingOverlay({super.key, required this.message});

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _scanCtrl; // vertical scan line
  late AnimationController _pulseCtrl; // orb pulse
  late AnimationController _rotCtrl; // ring rotation
  late AnimationController _waveCtrl; // waveform
  late AnimationController _typeCtrl; // typewriter tick
  late AnimationController _nodeCtrl; // neural node pulse

  // Typewriter state
  String _displayed = '';
  int _charIdx = 0;
  int _phraseIdx = 0;

  final List<String> _phrases = [
    'Scanning color palette...',
    'Mapping style vectors...',
    'Evaluating silhouette...',
    'Analyzing fit & proportion...',
    'Detecting occasion suitability...',
    'Processing texture layers...',
    'Computing trend alignment...',
    'Generating style report...',
  ];

  // Progress steps
  final List<_Step> _steps = [
    _Step('Image ingested', true),
    _Step('Color analysis', true),
    _Step('Style mapping', false),
    _Step('Report compile', false),
  ];

  int _completedSteps = 1;

  @override
  void initState() {
    super.initState();

    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _rotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();

    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _nodeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _typeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 48),
    );
    _typeCtrl.addListener(_onTick);
    _startPhrase();

    // Simulate steps completing
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted)
        setState(() {
          _steps[2] = _Step('Style mapping', true);
          _completedSteps = 3;
        });
    });
    Future.delayed(const Duration(milliseconds: 3400), () {
      if (mounted)
        setState(() {
          _steps[3] = _Step('Report compile', true);
          _completedSteps = 4;
        });
    });
  }

  void _startPhrase() {
    _charIdx = 0;
    _displayed = '';
    _typeCtrl.repeat();
  }

  void _onTick() {
    if (!mounted) return;
    final target = _phrases[_phraseIdx];
    if (_charIdx < target.length) {
      setState(() {
        _displayed = target.substring(0, ++_charIdx);
      });
    } else {
      _typeCtrl.stop();
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          _phraseIdx = (_phraseIdx + 1) % _phrases.length;
        });
        _startPhrase();
      });
    }
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _rotCtrl.dispose();
    _waveCtrl.dispose();
    _typeCtrl.dispose();
    _nodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.98),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildScanOrb(),
              const SizedBox(height: 40),
              _buildLabel(),
              const SizedBox(height: 16),
              _buildTypewriter(),
              const SizedBox(height: 36),
              _buildStepList(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Central scan orb ──────────────────────────────────────────────
  Widget _buildScanOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotCtrl, _pulseCtrl, _scanCtrl]),
      builder: (_, __) {
        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outermost faint ring
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.ice.withOpacity(
                      0.08 + _pulseCtrl.value * 0.06,
                    ),
                    width: 1,
                  ),
                ),
              ),

              // Rotating segmented ring
              Transform.rotate(
                angle: _rotCtrl.value * 2 * pi,
                child: CustomPaint(
                  size: const Size(150, 150),
                  painter: _SegmentRingPainter(
                    color: AppTheme.iceDeep,
                    progress: _rotCtrl.value,
                  ),
                ),
              ),

              // Counter-rotating thin ring
              Transform.rotate(
                angle: -_rotCtrl.value * 2 * pi * 0.4,
                child: CustomPaint(
                  size: const Size(122, 122),
                  painter: _DashedRingPainter(
                    color: AppTheme.ice.withOpacity(0.3),
                    segments: 16,
                  ),
                ),
              ),

              // Scanning line across orb
              ClipOval(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      // orb background
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.ink,
                        ),
                      ),
                      // scan line sweep
                      Positioned(
                        top: _scanCtrl.value * 100 - 2,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppTheme.ice.withOpacity(0.8),
                                AppTheme.ice,
                                AppTheme.ice.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // trailing glow below scan
                      Positioned(
                        top: _scanCtrl.value * 100 - 30,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.ice.withOpacity(0.06),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // AI icon center
                      Center(
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.ice.withOpacity(
                            0.9 + _pulseCtrl.value * 0.1,
                          ),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Corner brackets
              ..._buildCornerBrackets(110),

              // Orbiting dot
              Transform.rotate(
                angle: _rotCtrl.value * 2 * pi,
                child: Transform.translate(
                  offset: const Offset(75, 0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.ice,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.ice.withOpacity(0.7),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Smaller counter orbit dot
              Transform.rotate(
                angle: -_rotCtrl.value * 2 * pi * 0.6 + pi / 3,
                child: Transform.translate(
                  offset: const Offset(61, 0),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.inkLight.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerBrackets(double size) {
    final half = size / 2;
    final len = 14.0;
    final thick = 1.5;
    final color = AppTheme.ice.withOpacity(0.5);

    Widget bracket(double tx, double ty, bool flipX, bool flipY) {
      return Transform.translate(
        offset: Offset(tx, ty),
        child: CustomPaint(
          size: Size(len, len),
          painter: _BracketPainter(
            color: color,
            thick: thick,
            flipX: flipX,
            flipY: flipY,
          ),
        ),
      );
    }

    return [
      bracket(-half + 2, -half + 2, false, false),
      bracket(half - len - 2, -half + 2, true, false),
      bracket(-half + 2, half - len - 2, false, true),
      bracket(half - len - 2, half - len - 2, true, true),
    ];
  }

  // ── Status label ──────────────────────────────────────────────────
  Widget _buildLabel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Text(
        widget.message,
        key: ValueKey(widget.message),
        style: GoogleFonts.outfit(
          color: AppTheme.ink,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── Typewriter terminal ───────────────────────────────────────────
  Widget _buildTypewriter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.iceDeep.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Blinking status dot
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.ice.withOpacity(0.5 + _pulseCtrl.value * 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.ice.withOpacity(0.4 * _pulseCtrl.value),
                      blurRadius: 8,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Text(
            'AI › ',
            style: GoogleFonts.robotoMono(
              color: AppTheme.ice.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              _displayed,
              style: GoogleFonts.robotoMono(color: AppTheme.ice, fontSize: 12),
            ),
          ),
          // Blinking cursor
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) {
              return Container(
                width: 2,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.ice.withOpacity(_pulseCtrl.value),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Waveform visualizer ───────────────────────────────────────────
  // Widget _buildWaveform() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text(
  //         'SIGNAL',
  //         style: GoogleFonts.outfit(
  //           color: AppTheme.inkHint,
  //           fontSize: 9,
  //           fontWeight: FontWeight.w700,
  //           letterSpacing: 2,
  //         ),
  //       ),
  //       const SizedBox(height: 10),
  //       AnimatedBuilder(
  //         animation: _waveCtrl,
  //         builder: (_, __) {
  //           return CustomPaint(
  //             size: const Size(double.infinity, 40),
  //             painter: _WaveformPainter(
  //               t: _waveCtrl.value,
  //               color: AppTheme.iceDeep,
  //               dimColor: AppTheme.iceDim.withOpacity(0.4),
  //             ),
  //           );
  //         },
  //       ),
  //     ],
  //   );
  // }

  // ── Step progress list ────────────────────────────────────────────
  Widget _buildStepList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PROGRESS',
          style: GoogleFonts.outfit(
            color: AppTheme.inkHint,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        ..._steps.asMap().entries.map((e) {
          final i = e.key;
          final step = e.value;
          final active = i == _completedSteps && !step.done;
          return _buildStepRow(step, active, i);
        }),
      ],
    );
  }

  Widget _buildStepRow(_Step step, bool active, int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) {
          return Row(
            children: [
              // Icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: step.done
                      ? AppTheme.iceDeep
                      : active
                      ? AppTheme.ink
                      : AppTheme.bgSecondary,
                  border: Border.all(
                    color: active
                        ? AppTheme.ice.withOpacity(0.5 + _pulseCtrl.value * 0.4)
                        : step.done
                        ? AppTheme.iceDeep
                        : AppTheme.border,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: step.done
                      ? const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        )
                      : active
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation(
                              AppTheme.ice.withOpacity(
                                0.7 + _pulseCtrl.value * 0.3,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.chrome,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label,
                  style: GoogleFonts.outfit(
                    color: step.done
                        ? AppTheme.ink
                        : active
                        ? AppTheme.inkMid
                        : AppTheme.inkHint,
                    fontSize: 13,
                    fontWeight: step.done ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (step.done)
                Text(
                  'Done',
                  style: GoogleFonts.outfit(
                    color: AppTheme.iceDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (active)
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) {
                    return Text(
                      'Running',
                      style: GoogleFonts.outfit(
                        color: AppTheme.inkHint.withOpacity(
                          0.5 + _pulseCtrl.value * 0.5,
                        ),
                        fontSize: 11,
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Step {
  final String label;
  final bool done;
  const _Step(this.label, this.done);
}

// ── Custom Painters ──────────────────────────────────────────────────

class _SegmentRingPainter extends CustomPainter {
  final Color color;
  final double progress;
  _SegmentRingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const segments = 8;
    const gapAngle = 0.3;
    const segAngle = (2 * pi - segments * gapAngle) / segments;

    for (int i = 0; i < segments; i++) {
      final startAngle = i * (segAngle + gapAngle) - pi / 2 + progress * 2 * pi;
      final opacity = 0.15 + ((i % segments) / segments) * 0.5;
      final paint = Paint()
        ..color = color.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        segAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentRingPainter o) => o.progress != progress;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final int segments;
  _DashedRingPainter({required this.color, required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (2 * pi / segments) * 0.45;
    for (int i = 0; i < segments; i++) {
      final start = i * (2 * pi / segments) - pi / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        start,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _BracketPainter extends CustomPainter {
  final Color color;
  final double thick;
  final bool flipX, flipY;
  _BracketPainter({
    required this.color,
    required this.thick,
    required this.flipX,
    required this.flipY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final w = size.width;
    final h = size.height;
    final x0 = flipX ? w : 0.0;
    final x1 = flipX ? 0.0 : w;
    final y0 = flipY ? h : 0.0;
    final y1 = flipY ? 0.0 : h;

    canvas.drawLine(Offset(x0, y0), Offset(x1, y0), paint); // horizontal
    canvas.drawLine(Offset(x0, y0), Offset(x0, y1), paint); // vertical
  }

  @override
  bool shouldRepaint(_) => false;
}

class _WaveformPainter extends CustomPainter {
  final double t;
  final Color color, dimColor;
  _WaveformPainter({
    required this.t,
    required this.color,
    required this.dimColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 28;
    final barW = (size.width - (barCount - 1) * 3) / barCount;
    final midY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barW + 3);
      // Create a wave pattern using sine
      final wave = sin((i / barCount) * 2 * pi * 2 + t * 2 * pi);
      final envelope = sin((i / barCount) * pi); // taper at edges
      final barH = (8 + wave * envelope * 14).abs().clamp(3.0, 20.0);

      final isActive = i > barCount * 0.2 && i < barCount * 0.8;
      final paint = Paint()
        ..color = isActive ? color.withOpacity(0.6 + envelope * 0.4) : dimColor
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x + barW / 2, midY - barH),
        Offset(x + barW / 2, midY + barH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter o) => o.t != t;
}
