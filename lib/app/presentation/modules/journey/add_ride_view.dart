import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import 'add_ride_controller.dart';
import 'widgets/address_autocomplete_field.dart';

class AddRideView extends GetView<AddRideController> {
  const AddRideView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Adicionar corrida',
        subtitle: 'Cadastro manual no historico',
        leadingIcon: Icons.add_road_rounded,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            12,
            Responsive.hp(context, 4.5).clamp(16.0, 24.0),
            28,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.apps_rounded,
                          title: 'Plataforma',
                          subtitle: 'Selecione onde a corrida aconteceu',
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 94,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _platformOptions.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final option = _platformOptions[index];
                              return Obx(() {
                                final isSelected =
                                    controller.selectedPlatform.value ==
                                    option.label;
                                return _PlatformCard(
                                  option: option,
                                  isSelected: isSelected,
                                  onTap: () =>
                                      controller.selectedPlatform.value =
                                          option.label,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.edit_note_rounded,
                          title: 'Dados da corrida',
                          subtitle: 'Preencha as informacoes principais',
                        ),
                        const SizedBox(height: 20),
                        _RideInputField(
                          controller: controller.passengerController,
                          label: 'Nome do passageiro',
                          hint: 'Opcional',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RideInputField(
                          controller: controller.ratingController,
                          label: 'Nota do passageiro',
                          hint: 'Ex: 4,8',
                          icon: Icons.star_outline_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RideInputField(
                          controller: controller.amountController,
                          label: 'Valor da corrida',
                          hint: 'R\$ 0,00',
                          icon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          inputFormatters: [
                            CurrencyTextInputFormatter.currency(
                              locale: 'pt_BR',
                              symbol: 'R\$',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Forma de pagamento',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: Responsive.sp(
                              context,
                              14,
                            ).clamp(13.0, 15.0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Obx(
                          () => Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _paymentMethodOptions.map((option) {
                              final isSelected =
                                  controller.selectedPaymentMethod.value ==
                                  option.label;
                              return _SelectableChip(
                                option: option,
                                isSelected: isSelected,
                                onTap: () =>
                                    controller.selectedPaymentMethod.value =
                                        option.label,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          icon: Icons.route_rounded,
                          title: 'Rota',
                          subtitle: 'Origem, paradas e destino',
                        ),
                        const SizedBox(height: 20),
                        AddressAutocompleteField(
                          controller: controller.originController,
                          label: 'Endereco de origem',
                          hint: 'Digite o ponto de partida',
                          icon: Icons.my_location_rounded,
                          searchSuggestions:
                              controller.searchAddressSuggestions,
                          textInputAction: TextInputAction.next,
                        ),
                        Obx(
                          () => Column(
                            children: [
                              for (
                                var i = 0;
                                i < controller.stopControllers.length;
                                i++
                              ) ...[
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: AddressAutocompleteField(
                                        controller:
                                            controller.stopControllers[i],
                                        label: 'Parada ${i + 1}',
                                        hint: 'Digite uma parada intermediaria',
                                        icon: Icons.flag_outlined,
                                        searchSuggestions:
                                            controller.searchAddressSuggestions,
                                        textInputAction: TextInputAction.next,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: IconButton(
                                        onPressed: () =>
                                            controller.removeStop(i),
                                        icon: const Icon(
                                          Icons.remove_circle_outline_rounded,
                                          color: AppColors.rose,
                                        ),
                                        tooltip: 'Remover parada',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: controller.addStop,
                            icon: const Icon(Icons.add_location_alt_outlined),
                            label: const Text('Adicionar parada'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AddressAutocompleteField(
                          controller: controller.destinationController,
                          label: 'Endereco de destino',
                          hint: 'Digite o ponto final',
                          icon: Icons.location_on_outlined,
                          searchSuggestions:
                              controller.searchAddressSuggestions,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _EstimateCard(controller: controller),
                  const SizedBox(height: 24),
                  Obx(
                    () => SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.saveRide,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.primary
                              .withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: controller.isSubmitting.value
                            ? const AppLoadingIndicator(
                                size: AppLoadingSize.compact,
                                accentColor: Colors.white,
                                onDark: true,
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          controller.isSubmitting.value
                              ? 'SALVANDO...'
                              : 'SALVAR CORRIDA',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
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

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.controller});

  final AddRideController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: AppColors.electricCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimativa da viagem',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: Responsive.sp(context, 16).clamp(15.0, 18.0),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Calcule pela rota ou ajuste manualmente',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: Responsive.sp(context, 12).clamp(11.0, 13.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Obx(() {
            final isEstimating = controller.isEstimatingRoute.value;
            final providerLabel = controller.routeProviderLabel.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: isEstimating ? null : controller.estimateRoute,
                  icon: isEstimating
                      ? const AppLoadingIndicator(
                          size: AppLoadingSize.compact,
                          accentColor: AppColors.royalBlue,
                          onDark: false,
                        )
                      : const Icon(Icons.route_rounded),
                  label: Text(
                    isEstimating ? 'Calculando rota...' : 'Calcular km e tempo',
                  ),
                ),
                if (providerLabel.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      providerLabel,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _RideInputField(
                  controller: controller.distanceKmController,
                  label: 'Distancia (km)',
                  hint: 'Ex: 12,4',
                  icon: Icons.straighten_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RideInputField(
                  controller: controller.durationMinutesController,
                  label: 'Duracao (min)',
                  hint: 'Ex: 32',
                  icon: Icons.schedule_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller.distanceKmController,
            builder: (context, value, child) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller.durationMinutesController,
                builder: (context, durationValue, durationChild) {
                  return Column(
                    children: [
                      _EstimateLine(
                        icon: Icons.straighten_rounded,
                        label: 'Distancia',
                        value: controller.estimatedDistanceLabel,
                      ),
                      const SizedBox(height: 10),
                      _EstimateLine(
                        icon: Icons.schedule_rounded,
                        label: 'Tempo estimado',
                        value: controller.estimatedDurationLabel,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EstimateLine extends StatelessWidget {
  const _EstimateLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: Responsive.sp(context, 13).clamp(12.0, 14.0),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: Responsive.sp(context, 14).clamp(13.0, 16.0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RideInputField extends StatelessWidget {
  const _RideInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: Responsive.sp(context, 17).clamp(16.0, 19.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: Responsive.sp(context, 12).clamp(11.0, 13.0),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ChoiceOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 92,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? option.color : colorScheme.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(option.icon, color: option.color, size: 24),
            const SizedBox(height: 8),
            Text(
              option.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: Responsive.sp(context, 11).clamp(10.0, 12.0),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ChoiceOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? option.color.withValues(alpha: 0.14)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? option.color : colorScheme.outlineVariant,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(option.icon, size: 18, color: option.color),
            const SizedBox(width: 8),
            Text(
              option.label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: Responsive.sp(context, 13).clamp(12.0, 14.0),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

const List<_ChoiceOption> _platformOptions = [
  _ChoiceOption(
    label: 'Uber',
    icon: Icons.local_taxi_outlined,
    color: AppColors.primary,
  ),
  _ChoiceOption(
    label: '99',
    icon: Icons.directions_car_filled_outlined,
    color: AppColors.amber,
  ),
  _ChoiceOption(
    label: 'Indrive',
    icon: Icons.alt_route_rounded,
    color: AppColors.emerald,
  ),
  _ChoiceOption(
    label: 'Particular',
    icon: Icons.person_pin_circle_outlined,
    color: AppColors.electricCyan,
  ),
];

const List<_ChoiceOption> _paymentMethodOptions = [
  _ChoiceOption(
    label: 'Dinheiro',
    icon: Icons.payments_outlined,
    color: AppColors.emerald,
  ),
  _ChoiceOption(
    label: 'Credito',
    icon: Icons.credit_card_rounded,
    color: AppColors.electricCyan,
  ),
  _ChoiceOption(
    label: 'Debito',
    icon: Icons.credit_card_off_rounded,
    color: AppColors.amber,
  ),
  _ChoiceOption(
    label: 'Pix',
    icon: Icons.qr_code_rounded,
    color: AppColors.violet,
  ),
  _ChoiceOption(
    label: 'Voucher',
    icon: Icons.card_giftcard_rounded,
    color: AppColors.sky,
  ),
];
