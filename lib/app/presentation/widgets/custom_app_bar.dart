import 'package:direcao_financeira_mobile/app/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.showBackButton = true,
    this.actions,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final appBarTheme = context.theme.appBarTheme;
    final titleColor =
        appBarTheme.titleTextStyle?.color ?? colorScheme.onSurface;
    final subtitleColor = titleColor.withValues(alpha: 0.66);
    final iconContainerColor = colorScheme.primary.withValues(alpha: 0.12);
    final iconColor = colorScheme.primary;
    final iconBoxSize = Responsive.sp(context, 42).clamp(38.0, 44.0);
    final iconSize = Responsive.sp(context, 22).clamp(20.0, 23.0);
    final titleFontSize = Responsive.sp(context, 21).clamp(20.0, 22.0);
    final subtitleFontSize = Responsive.sp(context, 12.5).clamp(12.0, 13.0);
    final spacing = Responsive.hp(context, 3.0).clamp(10.0, 12.0);
    final backgroundColor =
        appBarTheme.backgroundColor ?? context.theme.scaffoldBackgroundColor;

    return AppBar(
      toolbarHeight: 78,
      leadingWidth: showBackButton ? 52 : 0,
      titleSpacing: 16,
      backgroundColor: backgroundColor,
      surfaceTintColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: colorScheme.onSurface,
              ),
              onPressed: () => Get.back(),
            )
          : null,
      title: Row(
        children: [
          if (leadingIcon != null) ...[
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  Responsive.sp(context, 14).clamp(12.0, 14.0),
                ),
                color: iconContainerColor,
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(leadingIcon, color: iconColor, size: iconSize),
            ),
            SizedBox(width: spacing),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: subtitleFontSize,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(78 + (bottom?.preferredSize.height ?? 0.0));
}
