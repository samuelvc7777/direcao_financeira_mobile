import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/plan_entity.dart';
import '../../../domain/entities/subscription_entity.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_filled_button.dart';
import 'subscription_controller.dart';

class SubscriptionView extends GetView<SubscriptionController> {
  const SubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: const CustomAppBar(title: 'Minha Assinatura'),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: cs.primary));
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return _SubscriptionErrorState(
            message: error,
            onRetry: controller.reloadData,
          );
        }

        final activeSubscription = controller.activeSubscription.value;
        return RefreshIndicator(
          color: cs.primary,
          onRefresh: controller.reloadData,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 680;
              final horizontalPadding = isWide ? 28.0 : 16.0;
              final contentWidth = isWide ? 720.0 : double.infinity;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  28,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: activeSubscription == null
                          ? _SubscribeExperience(controller: controller)
                          : _ActivePlanExperience(
                              controller: controller,
                              subscription: activeSubscription,
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}

class _SubscribeExperience extends StatelessWidget {
  const _SubscribeExperience({required this.controller});

  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final selectedPlan = controller.selectedPlan;
    final selectedColor = _planColor(selectedPlan);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumHeader(
          eyebrow: 'Premium',
          title: 'Libere todos os recursos',
          description:
              'Escolha um plano para ativar sua assinatura e manter o app sincronizado com a Google Play.',
          accentColor: selectedColor,
          trailing: _HeaderBadge(
            icon: Icons.lock_open_rounded,
            label: 'Disponivel',
            color: AppColors.emerald,
          ),
        ),
        const SizedBox(height: 18),
        _StoreHealthCard(controller: controller),
        const SizedBox(height: 18),
        Text(
          'Planos',
          style: TextStyle(
            color: cs.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        if (!controller.hasPlanCatalog.value)
          _QuietMessageCard(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum plano ativo',
            message: 'O catalogo de planos ainda nao retornou opcoes.',
          )
        else
          _PlanPicker(controller: controller),
        const SizedBox(height: 18),
        _SubscribeBottomBar(controller: controller),
      ],
    );
  }
}

class _ActivePlanExperience extends StatelessWidget {
  const _ActivePlanExperience({
    required this.controller,
    required this.subscription,
  });

  final SubscriptionController controller;
  final SubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final plan = subscription.plan ?? controller.selectedPlan;
    final accentColor = _planColor(plan);
    final planName = _planName(plan);
    final planDescription = _planDescription(plan);
    final priceLabel = plan == null
        ? controller.formatPrice(0)
        : controller.planPriceLabel(plan);
    final durationLabel = plan == null
        ? 'Periodo atual'
        : '${plan.durationDays} dias';
    final isRenewalCanceled = !subscription.autoRenew;
    final isGooglePlayManaged = subscription.isGooglePlayManaged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PremiumHeader(
          eyebrow: 'Plano ativo',
          title: planName,
          description: planDescription,
          accentColor: accentColor,
          trailing: _HeaderBadge(
            icon: Icons.verified_rounded,
            label: controller.formatStatus(subscription.status),
            color: controller.statusColor(subscription.status),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: _surfaceDecoration(cs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PlanGlyph(color: accentColor, selected: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isRenewalCanceled
                              ? 'Cancelada, acesso mantido ate o vencimento'
                              : 'Assinatura ativa',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.62),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ResponsiveInfoGrid(
                items: [
                  _InfoTileData(
                    icon: Icons.payments_outlined,
                    label: 'Valor',
                    value: priceLabel,
                    color: AppColors.amber,
                  ),
                  _InfoTileData(
                    icon: Icons.event_available_outlined,
                    label: 'Validade',
                    value: controller.formatDate(subscription.endDate),
                    color: AppColors.aqua,
                  ),
                  _InfoTileData(
                    icon: isGooglePlayManaged
                        ? Icons.shop_2_outlined
                        : Icons.admin_panel_settings_outlined,
                    label: 'Origem',
                    value: isGooglePlayManaged ? 'Google Play' : 'Painel admin',
                    color: subscription.autoRenew
                        ? AppColors.emerald
                        : AppColors.amber,
                  ),
                  _InfoTileData(
                    icon: Icons.timelapse_rounded,
                    label: 'Ciclo',
                    value: durationLabel,
                    color: accentColor,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (isRenewalCanceled) ...[
                _RenewalCanceledCard(
                  controller: controller,
                  subscription: subscription,
                ),
                const SizedBox(height: 16),
              ],
              if (isGooglePlayManaged) ...[
                _PlayStoreNote(
                  title: 'Gerenciado pela Google Play',
                  message:
                      'Use restaurar compras para sincronizar uma assinatura ativa neste aparelho.',
                ),
                const SizedBox(height: 16),
                Obx(
                  () => CustomFilledButton(
                    text: 'RESTAURAR COMPRAS',
                    icon: Icons.sync_rounded,
                    backgroundColor: cs.surfaceContainerHighest,
                    isLoading: controller.isRestoringPurchases.value,
                    onPressed: controller.restorePurchases,
                  ),
                ),
              ] else
                _PlayStoreNote(
                  title: 'Liberado pelo painel admin',
                  message:
                      'Os dados desta assinatura vem do banco de dados. Para migrar para cobranca automatica, assine pela Play Store quando o plano atual nao estiver mais ativo.',
                ),
              if (isRenewalCanceled) ...[
                const SizedBox(height: 10),
                Obx(
                  () => CustomFilledButton(
                    text: 'REATIVAR NA PLAY STORE',
                    icon: Icons.autorenew_rounded,
                    isLoading:
                        controller.isActionLoading.value ||
                        controller.isPurchaseLoading.value ||
                        controller.isStoreSyncingPurchase.value,
                    onPressed: controller.canPurchaseSelectedPlan
                        ? controller.purchaseSelectedPlan
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RenewalCanceledCard extends StatelessWidget {
  const _RenewalCanceledCard({
    required this.controller,
    required this.subscription,
  });

  final SubscriptionController controller;
  final SubscriptionEntity subscription;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final endDate = controller.formatDate(subscription.endDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.amber,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu plano foi cancelado',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Voce ainda tem acesso ate $endDate. Reative pela Play Store antes do prazo vencer para nao perder os recursos premium.',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.72),
                    height: 1.35,
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

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.trailing,
  });

  final String eyebrow;
  final String title;
  final String description;
  final Color accentColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF12151C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.32),
                    const Color(0xFF12151C),
                    const Color(0xFF090B10),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    trailing,
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 31,
                    height: 1.02,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 15,
                    height: 1.45,
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

class _StoreHealthCard extends StatelessWidget {
  const _StoreHealthCard({required this.controller});

  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final selectedPlan = controller.selectedPlan;
    final storeProduct = selectedPlan == null
        ? null
        : controller.storeProductForPlan(selectedPlan);
    final error = controller.storeErrorMessage.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(cs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallIconBox(
            icon: controller.usesPlayStoreBilling
                ? Icons.shop_2_outlined
                : Icons.cloud_done_outlined,
            color: controller.usesPlayStoreBilling
                ? AppColors.aqua
                : AppColors.emerald,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.usesPlayStoreBilling
                      ? 'Google Play conectada'
                      : 'Google Play indisponivel',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                if (controller.isStoreCatalogLoading.value)
                  LinearProgressIndicator(
                    minHeight: 4,
                    color: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest,
                  )
                else
                  Text(
                    error ??
                        (controller.usesPlayStoreBilling
                            ? storeProduct == null
                                  ? 'Selecione um plano para verificar o produto.'
                                  : '${storeProduct.productId} - ${storeProduct.priceLabel}'
                            : 'A assinatura nao sera criada pelo backend do app; tente novamente em um aparelho com Google Play.'),
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.68),
                      height: 1.35,
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

class _PlanPicker extends StatelessWidget {
  const _PlanPicker({required this.controller});

  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: controller.plans.map((plan) {
            return Obx(() {
              final selected = controller.selectedPlanId.value == plan.id;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return SizedBox(
                width: cardWidth,
                child: _PlanOptionCard(
                  controller: controller,
                  plan: plan,
                  selected: selected,
                  onTap: () => controller.selectedPlanId.value = plan.id,
                ),
              );
            });
          }).toList(),
        );
      },
    );
  }
}

class _PlanOptionCard extends StatelessWidget {
  const _PlanOptionCard({
    required this.controller,
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionController controller;
  final PlanEntity plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final color = _planColor(plan);
    final hasStoreProduct = controller.hasStoreProductForPlan(plan);
    final trialLabel = controller.planTrialLabel(plan);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _PlanGlyph(color: color, selected: selected),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected
                        ? color
                        : cs.onSurface.withValues(alpha: 0.32),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                _planName(plan),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _planDescription(plan),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.66),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              if (trialLabel != null) ...[
                _InlineStatus(label: trialLabel, color: AppColors.emerald),
                const SizedBox(height: 10),
              ],
              Text(
                controller.planBillingLabel(plan),
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (controller.usesPlayStoreBilling) ...[
                const SizedBox(height: 10),
                _InlineStatus(
                  label: hasStoreProduct ? 'Produto ativo' : 'Indisponivel',
                  color: hasStoreProduct ? AppColors.emerald : AppColors.rose,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscribeBottomBar extends StatelessWidget {
  const _SubscribeBottomBar({required this.controller});

  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        children: [
          Obx(
            () => CustomFilledButton(
              text: controller.ctaLabelForSelectedPlan(),
              icon: controller.usesPlayStoreBilling
                  ? Icons.shop_2_outlined
                  : Icons.check_circle_outline_rounded,
              isLoading:
                  controller.isActionLoading.value ||
                  controller.isPurchaseLoading.value ||
                  controller.isStoreSyncingPurchase.value,
              onPressed: controller.canPurchaseSelectedPlan
                  ? controller.purchaseSelectedPlan
                  : null,
            ),
          ),
          if (controller.usesPlayStoreBilling) ...[
            const SizedBox(height: 10),
            Obx(
              () => CustomFilledButton(
                text: 'RESTAURAR COMPRAS',
                icon: Icons.sync_rounded,
                backgroundColor: cs.surfaceContainerHighest,
                isLoading: controller.isRestoringPurchases.value,
                onPressed: controller.restorePurchases,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResponsiveInfoGrid extends StatelessWidget {
  const _ResponsiveInfoGrid({required this.items});

  final List<_InfoTileData> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final itemWidth = isWide
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items
              .map((item) => SizedBox(width: itemWidth, child: _InfoTile(item)))
              .toList(),
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.data);

  final _InfoTileData data;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          _SmallIconBox(icon: data.icon, color: data.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.56),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
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

class _InfoTileData {
  const _InfoTileData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _PlayStoreNote extends StatelessWidget {
  const _PlayStoreNote({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.aqua.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.aqua.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shop_2_outlined, color: AppColors.aqua, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.70),
                    height: 1.35,
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

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconBox extends StatelessWidget {
  const _SmallIconBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _PlanGlyph extends StatelessWidget {
  const _PlanGlyph({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: selected ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        selected ? Icons.bolt_rounded : Icons.workspace_premium_rounded,
        color: color,
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuietMessageCard extends StatelessWidget {
  const _QuietMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(cs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SmallIconBox(icon: icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.68),
                    height: 1.35,
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

class _SubscriptionErrorState extends StatelessWidget {
  const _SubscriptionErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.amber,
              size: 42,
            ),
            const SizedBox(height: 16),
            Text(
              'Nao foi possivel carregar sua assinatura.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.70),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: CustomFilledButton(
                text: 'TENTAR NOVAMENTE',
                onPressed: () => onRetry(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(ColorScheme cs) {
  return BoxDecoration(
    color: cs.surfaceContainerHigh,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: cs.outlineVariant),
  );
}

Color _planColor(PlanEntity? plan) {
  final value = plan?.color.replaceFirst('#', '') ?? '';
  if (value.length != 6) {
    return AppColors.royalBlue;
  }
  return Color(int.parse('FF$value', radix: 16));
}

String _planName(PlanEntity? plan) {
  final name = plan?.name.trim() ?? '';
  return name.isEmpty ? 'Plano premium' : name;
}

String _planDescription(PlanEntity? plan) {
  final description = plan?.description.trim() ?? '';
  return description.isEmpty
      ? 'Todos os recursos liberados para sua conta.'
      : description;
}
