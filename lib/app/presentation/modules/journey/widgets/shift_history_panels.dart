import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/subscription/subscription_access_gate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../journey_controller.dart';
import 'manual_shift_form_sheet.dart';

class ShiftStartPanel extends StatelessWidget {
  const ShiftStartPanel({super.key, required this.controller});

  final JourneyController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.sp(context, 12).clamp(10.0, 14.0)),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.deepNavy.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          Responsive.sp(context, 20).clamp(16.0, 24.0),
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: Responsive.vp(context, 6.0).clamp(48.0, 56.0),
            child: Obx(
              () => ElevatedButton.icon(
                onPressed: controller.canStartShift
                    ? controller.startShift
                    : null,
                icon: controller.isStartingShift.value
                    ? const AppLoadingIndicator(
                        size: AppLoadingSize.compact,
                        accentColor: Colors.white,
                        onDark: true,
                      )
                    : Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: Responsive.sp(context, 24).clamp(20.0, 28.0),
                      ),
                label: Text(
                  'INICIAR TURNO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(context, 15).clamp(13.0, 17.0),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B873F),
                  disabledBackgroundColor: const Color(
                    0xFF1B873F,
                  ).withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.sp(context, 14).clamp(10.0, 18.0),
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.vp(context, 1.0).clamp(6.0, 10.0)),
          SizedBox(
            width: double.infinity,
            height: Responsive.vp(context, 6.0).clamp(48.0, 56.0),
            child: Obx(
              () => ElevatedButton.icon(
                onPressed: controller.canAddManualShift
                    ? () async {
                        if (!await SubscriptionAccessGate.ensureAccess()) {
                          return;
                        }
                        if (!context.mounted) {
                          return;
                        }
                        ManualShiftFormSheet.show(
                          context,
                          controller: controller,
                        );
                      }
                    : null,
                icon: controller.isAddingManualShift.value
                    ? const AppLoadingIndicator(
                        size: AppLoadingSize.compact,
                        accentColor: Colors.white,
                        onDark: true,
                      )
                    : Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: Responsive.sp(context, 22).clamp(18.0, 26.0),
                      ),
                label: Text(
                  'ADICIONAR TURNO',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.sp(context, 15).clamp(13.0, 17.0),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.royalBlue,
                  disabledBackgroundColor: AppColors.royalBlue.withValues(
                    alpha: 0.45,
                  ),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      Responsive.sp(context, 14).clamp(10.0, 18.0),
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
          SizedBox(height: Responsive.vp(context, 1.0).clamp(6.0, 10.0)),
          ShiftQuickToggleButton.trafficLight(controller: controller),
          SizedBox(height: Responsive.vp(context, 0.2).clamp(2.0, 6.0)),
          ShiftQuickToggleButton.assistant(controller: controller),
          SizedBox(height: Responsive.vp(context, 0.2).clamp(2.0, 6.0)),
          ShiftQuickToggleButton.recording(controller: controller),
        ],
      ),
    );
  }
}

class ShiftActivePanel extends StatelessWidget {
  const ShiftActivePanel({super.key, required this.controller});

  final JourneyController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: Responsive.vp(context, 2.0).clamp(12.0, 20.0),
            horizontal: Responsive.hp(context, 4.0).clamp(12.0, 20.0),
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1B873F),
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 20).clamp(16.0, 24.0),
            ),
          ),
          child: Column(
            children: [
              Obx(
                () => Text(
                  controller.formattedElapsed,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Responsive.sp(context, 32).clamp(28.0, 36.0),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: Responsive.vp(context, 0.6).clamp(4.0, 8.0)),
              Obx(
                () => Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Responsive.hp(context, 2.5).clamp(8.0, 14.0),
                  runSpacing: Responsive.vp(context, 0.6).clamp(4.0, 8.0),
                  children: [
                    _ShiftMetricChip(
                      icon: controller.isShiftPaused
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      label: controller.startTimeStr.value,
                    ),
                    _ShiftMetricChip(
                      icon: Icons.route_outlined,
                      label:
                          '${controller.currentKm.value.toStringAsFixed(1)} Km',
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.vp(context, 0.8).clamp(4.0, 8.0)),
              Obx(
                () => AnimatedOpacity(
                  opacity: controller.isShiftPaused ? 1 : 0.75,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.hp(context, 2.5).clamp(8.0, 12.0),
                      vertical: Responsive.vp(context, 0.5).clamp(4.0, 6.0),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: controller.isShiftPaused ? 0.18 : 0.10,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      controller.isShiftPaused
                          ? 'Turno pausado'
                          : 'Turno em andamento',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: Responsive.sp(context, 11).clamp(10.0, 12.0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: Responsive.vp(context, 1.2).clamp(8.0, 14.0)),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => ShiftActionButton(
                  onPressed: controller.canPauseOrResumeShift
                      ? controller.pauseShift
                      : null,
                  icon: controller.isPauseShiftLoading.value
                      ? Icons.hourglass_top_rounded
                      : controller.isShiftPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_circle_outline,
                  label: controller.isShiftPaused ? 'Retomar' : 'Pausar',
                  color: const Color(0xFFF2994A),
                ),
              ),
            ),
            SizedBox(width: Responsive.hp(context, 2.5).clamp(8.0, 14.0)),
            Expanded(
              child: Obx(
                () => ShiftActionButton(
                  onPressed: controller.canFinishShift
                      ? controller.finishShift
                      : null,
                  icon: controller.isFinishingShift.value
                      ? Icons.hourglass_top_rounded
                      : Icons.stop,
                  label: 'Parar',
                  color: const Color(0xFFEB5757),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.vp(context, 1.2).clamp(8.0, 14.0)),
        ShiftQuickToggleButton.trafficLight(controller: controller),
        SizedBox(height: Responsive.vp(context, 0.2).clamp(2.0, 6.0)),
        ShiftQuickToggleButton.assistant(controller: controller),
        SizedBox(height: Responsive.vp(context, 0.2).clamp(2.0, 6.0)),
        ShiftQuickToggleButton.recording(controller: controller),
      ],
    );
  }
}

class ShiftActionButton extends StatelessWidget {
  const ShiftActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: Responsive.vp(context, 6.2).clamp(46.0, 54.0),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: Colors.white,
          size: Responsive.sp(context, 18).clamp(16.0, 20.0),
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.sp(context, 13).clamp(11.0, 15.0),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: onPressed == null
              ? color.withValues(alpha: 0.5)
              : color,
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.hp(context, 2.5).clamp(10.0, 14.0),
            vertical: Responsive.vp(context, 0.9).clamp(6.0, 10.0),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.sp(context, 12).clamp(10.0, 14.0),
            ),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}

class ShiftQuickToggleButton extends StatelessWidget {
  const ShiftQuickToggleButton.trafficLight({
    super.key,
    required this.controller,
  }) : _kind = _QuickToggleKind.trafficLight;

  const ShiftQuickToggleButton.assistant({super.key, required this.controller})
    : _kind = _QuickToggleKind.assistant;

  const ShiftQuickToggleButton.recording({super.key, required this.controller})
    : _kind = _QuickToggleKind.recording;

  final JourneyController controller;
  final _QuickToggleKind _kind;

  bool get _isTrafficLight => _kind == _QuickToggleKind.trafficLight;
  bool get _isRecording => _kind == _QuickToggleKind.recording;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final colorScheme = context.theme.colorScheme;
      final isDark = context.theme.brightness == Brightness.dark;
      final isActive = _isTrafficLight
          ? controller.isAccessibilityServiceEnabled &&
                controller.isTrafficLightActive.value
          : _isRecording
          ? controller.isRecordingActive
          : controller.isAssistantActive.value;
      final activeColor = _isTrafficLight
          ? AppColors.emerald
          : _isRecording
          ? AppColors.rose
          : AppColors.electricCyan;
      final inactiveColor = isDark
          ? Colors.white70
          : colorScheme.onSurface.withValues(alpha: 0.82);
      final label = _isTrafficLight
          ? (isActive ? 'Desativar semáforo' : 'Ativar semáforo')
          : (isActive ? 'Desativar Assistente' : 'Ativar Assistente');
      final effectiveLabel = _isRecording
          ? (isActive ? 'Parar gravacao' : 'Ativar gravacao')
          : label;

      return InkWell(
        onTap: _isTrafficLight
            ? controller.toggleTrafficLight
            : _isRecording
            ? controller.toggleRecording
            : controller.toggleAssistant,
        borderRadius: BorderRadius.circular(
          Responsive.sp(context, 12).clamp(8.0, 16.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: Responsive.vp(context, 1.0).clamp(6.0, 10.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isTrafficLight && isActive)
                PulseIcon(icon: Icons.traffic_rounded, color: activeColor)
              else if (_isRecording && isActive)
                PulseIcon(icon: Icons.videocam_rounded, color: activeColor)
              else
                Icon(
                  _isTrafficLight
                      ? Icons.traffic_rounded
                      : _isRecording
                      ? Icons.videocam_rounded
                      : Icons.assistant_rounded,
                  color: isActive ? activeColor : inactiveColor,
                  size: Responsive.sp(context, 18).clamp(16.0, 20.0),
                ),
              SizedBox(width: Responsive.hp(context, 2.0).clamp(6.0, 10.0)),
              Flexible(
                child: Text(
                  effectiveLabel,
                  style: TextStyle(
                    color: isActive ? activeColor : inactiveColor,
                    fontSize: Responsive.sp(context, 14).clamp(12.0, 16.0),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _ShiftMetricChip extends StatelessWidget {
  const _ShiftMetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.hp(context, 2.5).clamp(8.0, 12.0),
        vertical: Responsive.vp(context, 0.5).clamp(4.0, 6.0),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: Responsive.sp(context, 14).clamp(12.0, 16.0),
          ),
          SizedBox(width: Responsive.hp(context, 1.0).clamp(4.0, 8.0)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.sp(context, 12).clamp(10.0, 14.0),
            ),
          ),
        ],
      ),
    );
  }
}

class PulseIcon extends StatefulWidget {
  const PulseIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.92,
        end: 1.08,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Icon(
        widget.icon,
        color: widget.color,
        size: Responsive.sp(context, 18).clamp(16.0, 20.0),
      ),
    );
  }
}

enum _QuickToggleKind { trafficLight, assistant, recording }
