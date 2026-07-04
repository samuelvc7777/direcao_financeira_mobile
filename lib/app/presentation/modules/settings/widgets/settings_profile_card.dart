import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../settings_controller.dart';
import 'settings_profile_avatar.dart';

class SettingsProfileCard extends StatelessWidget {
  const SettingsProfileCard({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(
      () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.royalBlue.withValues(alpha: 0.22),
              context.theme.colorScheme.surface,
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.royalBlue.withValues(alpha: 0.18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.royalBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsProfileAvatar(
                  name: controller.userName.value,
                  photoBase64: controller.profilePhotoBase64.value,
                  isBusy: controller.isProfilePhotoSaving.value,
                  onTap: controller.pickProfilePhoto,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.userName.value,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.userEmail.value,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.72),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          controller.planStatus.value,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 360;
                final iconOnlyReferral = constraints.maxWidth < 320;
                final showReferral = controller.canShowReferralEntryPoint.value;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.planName.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: compactActions ? 16 : 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${controller.remainingDays.value} dias restantes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: compactActions ? 12 : 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compactActions ? 6 : 10),
                    Flexible(
                      flex: compactActions ? 2 : 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProfileActionButton(
                              label: compactActions ? 'Plano' : 'Ver plano',
                              tooltip: 'Ver plano',
                              icon: Icons.open_in_new_rounded,
                              color: colorScheme.primary,
                              compact: compactActions,
                              onPressed: controller.openSubscription,
                            ),
                            if (showReferral) ...[
                              SizedBox(width: compactActions ? 6 : 8),
                              _ProfileActionButton(
                                label: iconOnlyReferral ? null : 'Indicar',
                                tooltip: 'Indicar',
                                icon: Icons.card_giftcard_rounded,
                                color: AppColors.emerald,
                                compact: compactActions,
                                onPressed: controller.openReferrals,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: controller.planProgress.value,
                minHeight: 6,
                backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.sand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.compact,
    required this.onPressed,
  });

  final String? label;
  final String tooltip;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.34)),
      padding: EdgeInsets.symmetric(
        horizontal: label == null ? 10 : (compact ? 10 : 12),
        vertical: compact ? 10 : 12,
      ),
      visualDensity: VisualDensity.compact,
      minimumSize: Size(label == null ? 40 : 0, compact ? 40 : 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );

    final button = label == null
        ? OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Icon(icon, size: 16),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 16),
            label: Text(
              label!,
              maxLines: 1,
              overflow: TextOverflow.fade,
              softWrap: false,
            ),
          );

    return Tooltip(message: tooltip, child: button);
  }
}
