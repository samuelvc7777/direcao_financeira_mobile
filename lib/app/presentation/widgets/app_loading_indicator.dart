import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppLoadingSize { compact, regular, large }

class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({
    super.key,
    this.accentColor = AppColors.royalBlue,
    this.size = AppLoadingSize.regular,
    this.label,
    this.onDark = false,
  });

  final Color accentColor;
  final AppLoadingSize size;
  final String? label;
  final bool onDark;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dimensions = _dimensionsFor(widget.size);
    final foreground = widget.onDark
        ? colorScheme.onInverseSurface
        : colorScheme.onSurface;
    final subtitleColor = widget.onDark
        ? colorScheme.onInverseSurface.withValues(alpha: 0.72)
        : colorScheme.onSurface.withValues(alpha: 0.72);

    if (widget.size == AppLoadingSize.compact && widget.label == null) {
      return SizedBox.square(
        dimension: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dimensions.containerSize,
              height: dimensions.containerSize,
              padding: EdgeInsets.all(dimensions.containerPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accentColor.withValues(alpha: 0.22),
                    widget.accentColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(dimensions.containerRadius),
                border: Border.all(
                  color: widget.onDark
                      ? colorScheme.onInverseSurface.withValues(alpha: 0.16)
                      : colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.onDark
                        ? Colors.black.withValues(alpha: 0.18)
                        : Colors.black.withValues(alpha: 0.08),
                    blurRadius: dimensions.shadowBlur,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: dimensions.barSpacing / 2,
                    ),
                    child: _AnimatedLoadingBar(
                      progress: _controller.value,
                      index: index,
                      color: widget.accentColor,
                      width: dimensions.barWidth,
                      minHeight: dimensions.barMinHeight,
                      maxHeight: dimensions.barMaxHeight,
                    ),
                  ),
                ),
              ),
            ),
            if (widget.label != null) ...[
              SizedBox(height: dimensions.labelSpacing),
              Text(
                widget.label!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: dimensions.labelFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: dimensions.captionSpacing),
              Text(
                'Aguarde um instante',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: dimensions.captionFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  _LoadingDimensions _dimensionsFor(AppLoadingSize size) {
    switch (size) {
      case AppLoadingSize.compact:
        return const _LoadingDimensions(
          containerSize: 18,
          containerPadding: 4,
          containerRadius: 8,
          barWidth: 2,
          barMinHeight: 4,
          barMaxHeight: 8,
          barSpacing: 1,
          shadowBlur: 6,
          labelSpacing: 8,
          captionSpacing: 3,
          labelFontSize: 12,
          captionFontSize: 10,
        );
      case AppLoadingSize.large:
        return const _LoadingDimensions(
          containerSize: 84,
          containerPadding: 16,
          containerRadius: 28,
          barWidth: 8,
          barMinHeight: 16,
          barMaxHeight: 38,
          barSpacing: 6,
          shadowBlur: 20,
          labelSpacing: 16,
          captionSpacing: 6,
          labelFontSize: 18,
          captionFontSize: 13,
        );
      case AppLoadingSize.regular:
        return const _LoadingDimensions(
          containerSize: 64,
          containerPadding: 12,
          containerRadius: 22,
          barWidth: 6,
          barMinHeight: 12,
          barMaxHeight: 28,
          barSpacing: 4,
          shadowBlur: 16,
          labelSpacing: 14,
          captionSpacing: 6,
          labelFontSize: 16,
          captionFontSize: 12,
        );
    }
  }
}

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({
    super.key,
    this.label = 'Carregando dados',
    this.accentColor = AppColors.royalBlue,
    this.onDark = false,
  });

  final String label;
  final Color accentColor;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppLoadingIndicator(
          accentColor: accentColor,
          size: AppLoadingSize.large,
          label: label,
          onDark: onDark,
        ),
      ),
    );
  }
}

class AppLoadingBanner extends StatelessWidget {
  const AppLoadingBanner({
    super.key,
    this.label = 'Sincronizando',
    this.accentColor = AppColors.royalBlue,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            AppLoadingIndicator(
              accentColor: accentColor,
              size: AppLoadingSize.compact,
              onDark: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLoadingBar extends StatelessWidget {
  const _AnimatedLoadingBar({
    required this.progress,
    required this.index,
    required this.color,
    required this.width,
    required this.minHeight,
    required this.maxHeight,
  });

  final double progress;
  final int index;
  final Color color;
  final double width;
  final double minHeight;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final shiftedProgress = (progress + (index * 0.18)) % 1.0;
    final wave = shiftedProgress < 0.5
        ? shiftedProgress / 0.5
        : (1 - shiftedProgress) / 0.5;
    final eased = Curves.easeInOut.transform(wave.clamp(0.0, 1.0));
    final height = minHeight + ((maxHeight - minHeight) * eased);
    final opacity = 0.35 + (0.65 * eased);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

class _LoadingDimensions {
  const _LoadingDimensions({
    required this.containerSize,
    required this.containerPadding,
    required this.containerRadius,
    required this.barWidth,
    required this.barMinHeight,
    required this.barMaxHeight,
    required this.barSpacing,
    required this.shadowBlur,
    required this.labelSpacing,
    required this.captionSpacing,
    required this.labelFontSize,
    required this.captionFontSize,
  });

  final double containerSize;
  final double containerPadding;
  final double containerRadius;
  final double barWidth;
  final double barMinHeight;
  final double barMaxHeight;
  final double barSpacing;
  final double shadowBlur;
  final double labelSpacing;
  final double captionSpacing;
  final double labelFontSize;
  final double captionFontSize;
}
