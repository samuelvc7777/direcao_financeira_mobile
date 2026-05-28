import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/recording/recording_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/custom_app_bar.dart';
import 'recording_settings_controller.dart';

class RecordingSettingsView extends GetView<RecordingSettingsController> {
  const RecordingSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Configurar gravação',
        subtitle: 'Qualidade, áudio e performance',
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width < 360
              ? 12.0
              : width < 430
              ? 16.0
              : 20.0;

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RecordingSummaryCard(controller: controller),
                      SizedBox(height: Responsive.vp(context, 2.4)),
                      _RecordingSection(
                        title: 'Resolução',
                        icon: Icons.aspect_ratio_rounded,
                        child: Obx(
                          () => _OptionWrap(
                            items: RecordingResolution.values
                                .map(
                                  (option) => _SelectChip(
                                    label: option.label,
                                    selected:
                                        controller.selectedResolution.value ==
                                        option,
                                    onTap: () =>
                                        controller.setResolution(option),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.vp(context, 2.2)),
                      _RecordingSection(
                        title: 'FPS',
                        icon: Icons.motion_photos_on_rounded,
                        child: Obx(
                          () => _OptionWrap(
                            items: const [24, 30, 60]
                                .map(
                                  (fps) => _SelectChip(
                                    label: '$fps fps',
                                    selected:
                                        controller.selectedFps.value == fps,
                                    onTap: () => controller.setFps(fps),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.vp(context, 2.2)),
                      Obx(
                        () => _ToggleCard(
                          title: 'Áudio',
                          subtitle: controller.isAudioEnabled.value
                              ? 'O microfone será incluído na próxima gravação.'
                              : 'A gravação ficará apenas em vídeo.',
                          icon: controller.isAudioEnabled.value
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          value: controller.isAudioEnabled.value,
                          onChanged: controller.toggleAudio,
                        ),
                      ),
                      SizedBox(height: Responsive.vp(context, 2.2)),
                      _RecordingSection(
                        title: 'Câmera',
                        icon: Icons.cameraswitch_rounded,
                        child: Obx(
                          () => _OptionWrap(
                            items: RecordingCameraFacing.values
                                .map(
                                  (option) => _SelectChip(
                                    label: option.label,
                                    selected:
                                        controller.selectedCameraFacing.value ==
                                        option,
                                    onTap: () =>
                                        controller.setCameraFacing(option),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.vp(context, 2.2)),
                      _RecordingSection(
                        title: 'Compressão',
                        icon: Icons.high_quality_rounded,
                        child: Obx(
                          () => _OptionWrap(
                            items: RecordingCompressionProfile.values
                                .map(
                                  (option) => _SelectChip(
                                    label: option.label,
                                    selected:
                                        controller
                                            .selectedCompressionProfile
                                            .value ==
                                        option,
                                    onTap: () => controller
                                        .setCompressionProfile(option),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.vp(context, 2.2)),
                      _AdviceCard(
                        title: 'O que vale mais a pena ajustar',
                        message:
                            'Se quiser economizar espaço e bateria, mantenha 720p, 30 fps, áudio ligado só quando precisar e compressão equilibrada. Para melhor nitidez, use 1080p com compressão alta.',
                      ),
                      SizedBox(height: Responsive.vp(context, 3)),
                      Obx(
                        () => SizedBox(
                          width: double.infinity,
                          height: Responsive.vp(context, 7),
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.saveSettings,
                            icon: controller.isLoading.value
                                ? SizedBox(
                                    width: Responsive.sp(context, 18),
                                    height: Responsive.sp(context, 18),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.save_rounded,
                                    color: context.theme.colorScheme.onPrimary,
                                    size: Responsive.sp(context, 20),
                                  ),
                            label: Text(
                              controller.isLoading.value
                                  ? 'Salvando...'
                                  : 'Salvar configurações',
                              style: TextStyle(
                                color: context.theme.colorScheme.onPrimary,
                                fontSize: Responsive.sp(context, 16),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Responsive.sp(context, 16),
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RecordingSummaryCard extends StatelessWidget {
  const _RecordingSummaryCard({required this.controller});

  final RecordingSettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.royalBlue.withValues(alpha: 0.96),
                    AppColors.electricCyan.withValues(alpha: 0.82),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.videocam_rounded,
                color: colorScheme.onPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perfil atual',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    controller.summaryText,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'As alterações valem na próxima gravação.',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.62),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordingSection extends StatelessWidget {
  const _RecordingSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colorScheme.onSurfaceVariant,
              size: Responsive.sp(context, 20),
            ),
            SizedBox(width: Responsive.sp(context, 8)),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: Responsive.sp(context, 13),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        SizedBox(height: Responsive.vp(context, 1.2)),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.amber.withValues(alpha: 0.96),
                  AppColors.rose.withValues(alpha: 0.86),
                ],
              ),
            ),
            child: Icon(icon, color: colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colorScheme.primary,
            activeTrackColor: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.14)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.royalBlue,
            size: Responsive.sp(context, 22),
          ),
          SizedBox(width: Responsive.sp(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.72),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionWrap extends StatelessWidget {
  const _OptionWrap({required this.items});

  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }
}

class _SelectChip extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
