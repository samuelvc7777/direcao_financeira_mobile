import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../settings_controller.dart';

class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.items,
    required this.onItemTap,
  });

  final String title;
  final List<SettingsItemData> items;
  final ValueChanged<SettingsItemData> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.theme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
            ),
          ),
          child: Column(
            children: List.generate(
              items.length,
              (index) => _SettingsItemTile(
                item: items[index],
                isFirst: index == 0,
                isLast: index == items.length - 1,
                onTap: () => onItemTap(items[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsItemTile extends StatelessWidget {
  const _SettingsItemTile({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final SettingsItemData item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(24) : Radius.zero,
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _IconBadge(icon: item.icon, accentColor: item.accentColor),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: context.theme.colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: context.theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      if (item.footnote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.footnote!,
                          style: const TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.theme.colorScheme.onSurface.withValues(
                    alpha: 0.56,
                  ),
                ),
              ],
            ),
            if (!isLast) ...[
              const SizedBox(height: 16),
              Divider(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                height: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.98),
            accentColor,
            Color.lerp(accentColor, colorScheme.surface, 0.16) ?? accentColor,
          ],
        ),
        border: Border.all(
          color: colorScheme.onPrimary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.26),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(child: Icon(icon, color: colorScheme.onPrimary, size: 24)),
    );
  }
}
