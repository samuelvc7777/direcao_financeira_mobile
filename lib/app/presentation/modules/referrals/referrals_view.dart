import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../formatters/br_text_input_formatters.dart';
import '../../widgets/custom_app_bar.dart';
import 'referrals_controller.dart';
import 'widgets/referral_history_section.dart';
import 'widgets/referral_summary_section.dart';

class ReferralsView extends GetView<ReferralsController> {
  const ReferralsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Indicacoes',
        subtitle: 'Ganhe indicando assinantes',
        leadingIcon: Icons.card_giftcard_rounded,
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: SafeArea(
          top: false,
          child: Obx(() {
            if (controller.isLoading.value &&
                controller.summary.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!controller.isReferralProgramEnabled) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'O programa de indicacoes nao esta disponivel no momento.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                ReferralSummarySection(
                  controller: controller,
                  onCopyCode: controller.copyReferralCode,
                  onRequestWithdrawal: () => _showWithdrawalSheet(context),
                ),
                const SizedBox(height: 18),
                ReferralHistorySection(controller: controller),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _showWithdrawalSheet(BuildContext context) {
    final summary = controller.summary.value;
    if (summary == null || !controller.canRequestWithdrawal) {
      Get.snackbar(
        'Saque Pix',
        'O saque minimo e de ${controller.minimumWithdrawalLabel}.',
      );
      return;
    }

    Get.bottomSheet(
      _PixWithdrawalSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: context.theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

class _PixWithdrawalSheet extends StatelessWidget {
  const _PixWithdrawalSheet({required this.controller});

  final ReferralsController controller;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = context.theme.colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Solicitar saque Pix',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.cpfController,
            keyboardType: TextInputType.number,
            inputFormatters: [DigitsMaskTextInputFormatter('###.###.###-##')],
            decoration: const InputDecoration(labelText: 'CPF'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.pixKeyController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Chave Pix'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller.amountController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Valor',
              helperText:
                  'Minimo para saque: ${controller.minimumWithdrawalLabel}',
            ),
          ),
          const SizedBox(height: 18),
          Obx(
            () => FilledButton.icon(
              onPressed: controller.isRequestingWithdrawal.value
                  ? null
                  : controller.requestWithdrawal,
              icon: controller.isRequestingWithdrawal.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.pix_rounded),
              label: const Text('Enviar pedido'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
