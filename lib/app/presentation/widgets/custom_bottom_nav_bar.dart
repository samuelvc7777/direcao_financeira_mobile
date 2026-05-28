import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

import '../../core/theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = colorScheme.surface;
    final borderColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.08)
        : colorScheme.onSurface.withValues(alpha: 0.08);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.06);
    final activeNavColor = Colors.white;
    final inactiveNavColor = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.74)
        : AppColors.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            color: shadowColor,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final isCompact = constraints.maxWidth < 360 || textScale > 1.1;
              final tabPadding = EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 12,
                vertical: isCompact ? 8 : 10,
              );
              final gap = isCompact ? 2.0 : 4.0;
              final iconSize = isCompact ? 20.0 : 22.0;

              return GNav(
                rippleColor: colorScheme.primary.withValues(alpha: 0.1),
                hoverColor: colorScheme.primary.withValues(alpha: 0.1),
                gap: gap,
                activeColor: activeNavColor,
                iconSize: iconSize,
                padding: tabPadding,
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: colorScheme.primary,
                color: inactiveNavColor,
                selectedIndex: currentIndex,
                onTabChange: onTap,
                tabs: [
                  const GButton(icon: Icons.home_rounded, text: 'Início'),
                  GButton(
                    icon: Icons.receipt_long_rounded,
                    text: isCompact ? 'Finanças' : 'Transações',
                  ),
                  const GButton(
                    icon: Icons.work_history_outlined,
                    text: 'Jornada',
                  ),
                  const GButton(icon: Icons.settings_rounded, text: 'Ajustes'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
