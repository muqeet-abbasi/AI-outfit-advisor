import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'occasion_planner_screen.dart';

final mainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _index = 0;
  int _prevIndex = 0;

  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _iconScales;
  late final AnimationController _pillCtrl;

  final _screens = const [
    HomeScreen(),
    HistoryScreen(),
    OccasionPlannerScreen(),
    ProfileScreen(),
  ];

  final _navItems = const [
    _NavItem(Icons.home_rounded, Icons.home_outlined, 'Home'),
    _NavItem(Icons.checkroom_rounded, Icons.checkroom_outlined, 'Vault'),
    _NavItem(
      Icons.auto_fix_high_outlined,
      Icons.auto_fix_high_outlined,
      'Planner',
    ),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();

    _iconControllers = List.generate(
      _navItems.length,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      ),
    );

    _iconScales = _iconControllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween(
            begin: 1.0,
            end: 0.75,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 0.75,
            end: 1.15,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.15,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20,
        ),
      ]).animate(c);
    }).toList();

    _pillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Trigger initial icon bounce
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    _pillCtrl.dispose();
    super.dispose();
  }

  void switchTab(int index) {
    if (_index == index) return;
    _onTabTap(index);
  }

  void _onTabTap(int index) {
    if (_index == index) return;
    HapticFeedback.lightImpact();
    setState(() {
      _prevIndex = _index;
      _index = index;
    });
    _iconControllers[index].forward(from: 0);
    _pillCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          final isForward = _index > _prevIndex;
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: Offset(isForward ? 0.06 : -0.06, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                ),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        border: Border(top: BorderSide(color: AppTheme.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              return Expanded(child: _buildNavItem(i));
            }),
          ),
        ),
      ),
    ).animate().slideY(
      begin: 1,
      end: 0,
      duration: 600.ms,
      delay: 200.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildNavItem(int i) {
    final selected = _index == i;
    final item = _navItems[i];

    return GestureDetector(
      onTap: () => _onTabTap(i),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _iconControllers[i],
        builder: (_, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container with animated pill bg
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: selected ? 56 : 44,
                height: 34,
                decoration: BoxDecoration(
                  color: selected ? AppTheme.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: _iconScales[i],
                    child: Icon(
                      selected ? item.activeIcon : item.inactiveIcon,
                      size: 22,
                      color: selected ? Colors.white : AppTheme.inkHint,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 250),
                style: GoogleFonts.outfit(
                  color: selected ? AppTheme.ink : AppTheme.inkHint,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: selected ? 0.2 : 0,
                ),
                child: Text(item.label),
              ),

              // Active dot indicator
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: selected ? 16 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.ice,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
