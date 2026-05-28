import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/responsive.dart';
import '../../../widgets/scale_button.dart';

class TransactionsAddButton extends StatelessWidget {
  const TransactionsAddButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final horizontalPadding = Responsive.hp(context, 6.8).clamp(22.0, 26.0);
    final verticalPadding = Responsive.vp(context, 2.5).clamp(16.0, 20.0);
    final borderRadius = Responsive.hp(context, 7.4).clamp(24.0, 28.0);
    final shadowBlur = Responsive.hp(context, 6.4).clamp(18.0, 24.0);
    final iconSize = Responsive.sp(context, 30).clamp(24.0, 30.0);
    final textSize = Responsive.sp(context, 18).clamp(16.0, 18.0);
    final contentSpacing = Responsive.hp(context, 2.6).clamp(8.0, 10.0);

    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: shadowBlur,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_rounded,
              color: colorScheme.onPrimary,
              size: iconSize,
            ),
            SizedBox(width: contentSpacing),
            Text(
              'Nova',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: textSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
