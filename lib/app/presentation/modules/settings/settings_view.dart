import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import 'settings_controller.dart';
import 'widgets/settings_profile_card.dart';
import 'widgets/settings_section_card.dart';
import 'widgets/settings_switch_tile.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Ajustes',
        subtitle: 'Configuracoes do app',
        leadingIcon: Icons.settings_rounded,
        showBackButton: false,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final horizontalPadding = width < 360
              ? 12.0
              : width < 430
              ? 16.0
              : 20.0;

          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.theme.scaffoldBackgroundColor,
            ),
            child: SafeArea(
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
                        SettingsProfileCard(controller: controller),
                        const SizedBox(height: 22),
                        Column(
                          children: controller.sections
                              .map(
                                (section) => Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: SettingsSectionCard(
                                    title: section.title,
                                    items: section.items,
                                    onItemTap: controller.openSettingItem,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        SettingsSwitchTile(controller: controller),
                        const SizedBox(height: 16),
                        _NotificationPermissionCard(controller: controller),
                        const SizedBox(height: 24),
                        _LogoutCard(controller: controller),
                      ],
                    ),
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

class _NotificationPermissionCard extends StatelessWidget {
  const _NotificationPermissionCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Obx(() {
      final appEnabled = controller.invoiceNotificationsEnabled.value;
      final permissionEnabled = controller.areNotificationsEnabled.value;
      return InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => controller.toggleInvoiceNotifications(!appEnabled),
        child: Container(
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      (appEnabled && permissionEnabled
                              ? AppColors.emerald
                              : AppColors.amber)
                          .withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  appEnabled && permissionEnabled
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_off_rounded,
                  color: appEnabled && permissionEnabled
                      ? AppColors.emerald
                      : AppColors.amber,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificacoes de faturas',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      !appEnabled
                          ? 'Desativadas apenas para faturas.'
                          : permissionEnabled
                          ? 'Ativas para fechamento, vencimento e atraso.'
                          : 'Permissao bloqueada no Android.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.64),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: appEnabled,
                onChanged: controller.toggleInvoiceNotifications,
                activeThumbColor: AppColors.emerald,
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTA',
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: controller.logout,
          child: Container(
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
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.rose.withValues(alpha: 0.96),
                        Color.lerp(AppColors.rose, AppColors.amber, 0.20) ??
                            AppColors.rose,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.rose.withValues(alpha: 0.20),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.logout_rounded,
                      color: colorScheme.onPrimary,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Sair da conta',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.56),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
