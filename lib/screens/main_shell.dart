import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _screens = const [HomeScreen(), HistoryScreen(), ProfileScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
              _navItem(
                1,
                Icons.history_rounded,
                Icons.history_outlined,
                'History',
              ),
              _navItem(
                2,
                Icons.person_rounded,
                Icons.person_outline_rounded,
                'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData active, IconData inactive, String label) {
    final selected = _index == i;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _index = i),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.ice.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? active : inactive,
                  key: ValueKey(selected),
                  color: selected ? AppTheme.iceDeep : AppTheme.inkHint,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: selected ? AppTheme.iceDeep : AppTheme.inkHint,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
