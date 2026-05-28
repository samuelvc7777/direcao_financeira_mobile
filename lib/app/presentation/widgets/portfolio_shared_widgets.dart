import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import 'custom_filled_button.dart';

class PortfolioPageLayout extends StatelessWidget {
  const PortfolioPageLayout({
    super.key,
    required this.accentColor,
    required this.summary,
    required this.metrics,
    required this.activeCount,
    required this.inactiveCount,
    required this.activeSectionTitle,
    required this.activeItems,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.onCreate,
    this.inactiveSectionTitle,
    this.inactiveItems = const [],
  });

  final Color accentColor;
  final Widget summary;
  final List<PortfolioMetricData> metrics;
  final int activeCount;
  final int inactiveCount;
  final String activeSectionTitle;
  final List<Widget> activeItems;
  final String? inactiveSectionTitle;
  final List<Widget> inactiveItems;
  final String emptyTitle;
  final String emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 360 ? 14.0 : width < 430 ? 18.0 : 22.0;

    if (activeItems.isEmpty && inactiveItems.isEmpty) {
      return _PortfolioBackground(
        child: ListView(
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 120),
          children: [
            summary,
            const SizedBox(height: 18),
            PortfolioEmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              message: emptyMessage,
              accentColor: accentColor,
              actionLabel: 'Cadastrar agora',
              onPressed: onCreate,
            ),
          ],
        ),
      );
    }

    return _PortfolioBackground(
      child: ListView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(horizontalPadding, 12, horizontalPadding, 120),
        children: [
          summary,
          const SizedBox(height: 16),
          _MetricsGrid(metrics: metrics),
          const SizedBox(height: 24),
          _SectionCountPills(
            accentColor: accentColor,
            activeCount: activeCount,
            inactiveCount: inactiveCount,
          ),
          const SizedBox(height: 18),
          PortfolioSectionHeader(
            title: activeSectionTitle,
            subtitle: '$activeCount itens disponiveis para movimentar e acompanhar.',
            accentColor: accentColor,
          ),
          const SizedBox(height: 14),
          ...activeItems,
          if (inactiveItems.isNotEmpty && inactiveSectionTitle != null) ...[
            const SizedBox(height: 26),
            PortfolioSectionHeader(
              title: inactiveSectionTitle!,
              subtitle: '$inactiveCount itens pausados, mas preservados no seu historico.',
              accentColor: accentColor,
              subtle: true,
            ),
            const SizedBox(height: 14),
            ...inactiveItems,
          ],
        ],
      ),
    );
  }
}

class PortfolioMetricData {
  const PortfolioMetricData({
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tint;
}

class PortfolioHeroCard extends StatelessWidget {
  const PortfolioHeroCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.value,
    required this.caption,
    required this.badge,
    required this.icon,
    required this.stats,
  });

  final Color accentColor;
  final String title;
  final String value;
  final String caption;
  final String badge;
  final IconData icon;
  final List<PortfolioHeroStatData> stats;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: isDark ? 0.24 : 0.14),
            context.theme.colorScheme.surface,
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: accentColor, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accentColor.withValues(alpha: 0.12)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.62),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: onSurface,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              caption,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.56),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((stat) {
                return _HeroStatChip(
                  accentColor: accentColor,
                  data: stat,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class PortfolioHeroStatData {
  const PortfolioHeroStatData({
    required this.label,
    required this.value,
    this.highlight,
  });

  final String label;
  final String value;
  final Color? highlight;
}

class PortfolioSectionHeader extends StatelessWidget {
  const PortfolioSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.subtle = false,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;
    return Row(
      children: [
        Container(
          width: 4,
          height: 38,
          decoration: BoxDecoration(
            color: subtle ? onSurface.withValues(alpha: 0.12) : accentColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: onSurface.withValues(alpha: 0.54),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PortfolioItemCard extends StatelessWidget {
  const PortfolioItemCard({
    super.key,
    required this.accentColor,
    required this.leadingIcon,
    required this.title,
    required this.subtitle,
    required this.primaryValue,
    required this.secondaryValue,
    required this.metaItems,
    required this.onTap,
    this.progress,
    this.isInactive = false,
    this.trailingBadge,
  });

  final Color accentColor;
  final IconData leadingIcon;
  final String title;
  final String subtitle;
  final String primaryValue;
  final String secondaryValue;
  final List<String> metaItems;
  final VoidCallback onTap;
  final double? progress;
  final bool isInactive;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;
    final isColored = !isInactive;
    final coloredForeground =
        ThemeData.estimateBrightnessForColor(accentColor) == Brightness.dark
        ? Colors.white
        : const Color(0xFF0F172A);
    final titleColor = isColored ? coloredForeground : onSurface;
    final subtitleColor = isColored
        ? coloredForeground.withValues(alpha: 0.82)
        : onSurface.withValues(alpha: 0.54);
    final badgeColor = isColored ? coloredForeground : accentColor;
    final badgeBackground = isColored
        ? coloredForeground.withValues(alpha: 0.18)
        : accentColor.withValues(alpha: 0.12);
    final chipBackground = isColored
        ? coloredForeground.withValues(alpha: 0.14)
        : accentColor.withValues(alpha: 0.10);

    return Opacity(
      opacity: isInactive ? 0.72 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: isColored
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(accentColor, Colors.white, 0.08) ?? accentColor,
                        accentColor,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.10),
                        context.theme.colorScheme.surface,
                      ],
                    ),
              border: Border.all(
                color: isColored
                    ? accentColor.withValues(alpha: 0.92)
                    : accentColor.withValues(alpha: 0.16),
              ),
              boxShadow: [
                BoxShadow(
                  color: isColored
                      ? accentColor.withValues(alpha: 0.26)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isColored
                              ? coloredForeground.withValues(alpha: 0.16)
                              : accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isColored
                                ? coloredForeground.withValues(alpha: 0.12)
                                : accentColor.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(
                          leadingIcon,
                          color: isColored ? coloredForeground : accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailingBadge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: badgeBackground,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isColored
                                  ? coloredForeground.withValues(alpha: 0.14)
                                  : accentColor.withValues(alpha: 0.14),
                            ),
                          ),
                          child: Text(
                            trailingBadge!,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _ValueBlock(
                          label: 'Principal',
                          value: primaryValue,
                          labelColor: subtitleColor,
                          valueColor: titleColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ValueBlock(
                          label: 'Complemento',
                          value: secondaryValue,
                          labelColor: subtitleColor,
                          valueColor: titleColor,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 7,
                        value: progress!.clamp(0.0, 1.0),
                        backgroundColor: isColored
                            ? coloredForeground.withValues(alpha: 0.18)
                            : onSurface.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isColored
                              ? coloredForeground
                              : (progress! >= 0.9 ? AppColors.rose : accentColor),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: metaItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: chipBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isColored
                                ? coloredForeground.withValues(alpha: 0.12)
                                : accentColor.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isColored
                                ? coloredForeground.withValues(alpha: 0.92)
                                : onSurface.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PortfolioEmptyState extends StatelessWidget {
  const PortfolioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.accentColor,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.10),
            ),
            child: Icon(icon, size: 42, color: accentColor),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.58),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),
          CustomFilledButton(
            text: actionLabel,
            backgroundColor: accentColor,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}

class PortfolioErrorState extends StatelessWidget {
  const PortfolioErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.accentColor,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Color accentColor;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _PortfolioBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: context.theme.colorScheme.surface.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppColors.amber.withValues(alpha: 0.18)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.amber.withValues(alpha: 0.12),
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.amber,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomFilledButton(
                    text: 'Tentar novamente',
                    backgroundColor: accentColor,
                    onPressed: onRetry,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioBackground extends StatelessWidget {
  const _PortfolioBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final List<PortfolioMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520 ? 2 : 4;
        final spacing = 12.0;
        final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _MetricCard(data: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final PortfolioMetricData data;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;
    final tint = data.tint ?? context.theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: onSurface.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(data.icon, color: tint, size: 19),
          ),
          const SizedBox(height: 14),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.54),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCountPills extends StatelessWidget {
  const _SectionCountPills({
    required this.accentColor,
    required this.activeCount,
    required this.inactiveCount,
  });

  final Color accentColor;
  final int activeCount;
  final int inactiveCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _CountPill(
          label: '$activeCount ativos',
          color: accentColor,
          highlighted: true,
        ),
        _CountPill(
          label: '$inactiveCount inativos',
          color: context.theme.colorScheme.onSurface.withValues(alpha: 0.18),
          foreground: context.theme.colorScheme.onSurface.withValues(alpha: 0.68),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({
    required this.label,
    required this.color,
    this.foreground,
    this.highlighted = false,
  });

  final String label;
  final Color color;
  final Color? foreground;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted ? color.withValues(alpha: 0.12) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground ?? color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
    required this.accentColor,
    required this.data,
  });

  final Color accentColor;
  final PortfolioHeroStatData data;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;
    return Container(
      constraints: const BoxConstraints(minWidth: 116),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: TextStyle(
              color: onSurface.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            style: TextStyle(
              color: data.highlight ?? onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
