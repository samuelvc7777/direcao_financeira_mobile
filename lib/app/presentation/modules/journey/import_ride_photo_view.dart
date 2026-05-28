import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/ride_entity.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_text_field.dart';
import 'import_ride_photo_controller.dart';
import 'widgets/address_autocomplete_field.dart';
import 'widgets/ride_details_models.dart';

class ImportRidePhotoView extends GetView<ImportRidePhotoController> {
  const ImportRidePhotoView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Importar print',
        subtitle: 'Historico MoveSJ e Me Leva SJ',
        leadingIcon: Icons.photo_camera_back_rounded,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.amber.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.image_search_rounded,
                                color: AppColors.amber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Print do detalhe da corrida',
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: Responsive.sp(
                                        context,
                                        17,
                                      ).clamp(16.0, 19.0),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Leitura automatica de MoveSJ e Me Leva SJ com rota calculada pelo Google Maps',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: Responsive.sp(
                                        context,
                                        12,
                                      ).clamp(11.0, 13.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final imageFile = controller.selectedImageFile;
                          if (imageFile == null) {
                            return _ImagePlaceholder(
                              onTap: controller.pickImage,
                            );
                          }

                          return ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              imageFile,
                              height: 260,
                              fit: BoxFit.cover,
                            ),
                          );
                        }),
                        const SizedBox(height: 14),
                        Obx(() {
                          final isBusy = controller.isReadingImage.value;
                          return OutlinedButton.icon(
                            onPressed: isBusy ? null : controller.pickImage,
                            icon: isBusy
                                ? const AppLoadingIndicator(
                                    size: AppLoadingSize.compact,
                                    accentColor: AppColors.royalBlue,
                                    onDark: false,
                                  )
                                : const Icon(Icons.upload_file_rounded),
                            label: Text(
                              isBusy ? 'LENDO PRINT...' : 'SELECIONAR PRINT',
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Obx(() {
                          final isLoading = controller.isLoadingRides.value;
                          return OutlinedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => _openRideSelector(context),
                            icon: isLoading
                                ? const AppLoadingIndicator(
                                    size: AppLoadingSize.compact,
                                    accentColor: AppColors.royalBlue,
                                    onDark: false,
                                  )
                                : const Icon(
                                    Icons.directions_car_filled_outlined,
                                  ),
                            label: Text(
                              isLoading
                                  ? 'CARREGANDO CORRIDAS...'
                                  : 'SELECIONAR CORRIDA',
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Obx(
                          () => _SelectedRideSummary(
                            label: controller.selectedRideLabel,
                            hasSelection: controller.selectedRide.value != null,
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
                        _SectionTitle(
                          icon: Icons.fact_check_outlined,
                          title: 'Dados lidos',
                          subtitle: 'Revise antes de salvar no historico',
                        ),
                        const SizedBox(height: 16),
                        Obx(
                          () => _InfoPill(
                            icon: Icons.schedule_rounded,
                            label: controller.parsedDateTimeLabel,
                          ),
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
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
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: controller.passengerController,
                          label: 'Cliente',
                          hint: 'Nome lido do print',
                          icon: Icons.person_outline_rounded,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        CustomTextField(
                          controller: controller.passengerRatingController,
                          label: 'Nota do passageiro',
                          hint: 'Ex: 5,0',
                          icon: Icons.star_outline_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9,.]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        Obx(
                          () => _PaymentMethodSelector(
                            selectedOption:
                                controller.selectedPaymentOption.value,
                            onSelected: (option) =>
                                controller.selectedPaymentOption.value = option,
                          ),
                        ),
                        const SizedBox(height: 14),
                        AddressAutocompleteField(
                          controller: controller.originController,
                          label: 'Endereco de origem',
                          hint: 'Origem lida do print',
                          icon: Icons.my_location_rounded,
                          searchSuggestions:
                              controller.searchAddressSuggestions,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        AddressAutocompleteField(
                          controller: controller.destinationController,
                          label: 'Endereco de destino',
                          hint: 'Destino lido do print',
                          icon: Icons.location_on_outlined,
                          searchSuggestions:
                              controller.searchAddressSuggestions,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
                          final isEstimating =
                              controller.isEstimatingRoute.value;
                          final providerLabel =
                              controller.routeProviderLabel.value;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: isEstimating
                                    ? null
                                    : controller.estimateRoute,
                                icon: isEstimating
                                    ? const AppLoadingIndicator(
                                        size: AppLoadingSize.compact,
                                        accentColor: AppColors.royalBlue,
                                        onDark: false,
                                      )
                                    : const Icon(Icons.route_rounded),
                                label: Text(
                                  isEstimating
                                      ? 'Calculando rota...'
                                      : 'Recalcular km e tempo',
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
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: controller.distanceKmController,
                                label: 'Distancia (km)',
                                hint: 'Ex: 12,4',
                                icon: Icons.straighten_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]'),
                                  ),
                                ],
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller:
                                    controller.durationMinutesController,
                                label: 'Duracao (min)',
                                hint: 'Ex: 18',
                                icon: Icons.timer_outlined,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller:
                                    controller.pickupDistanceKmController,
                                label: 'Deslocamento (km)',
                                hint: 'Ex: 1,0',
                                icon: Icons.near_me_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9,.]'),
                                  ),
                                ],
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller:
                                    controller.pickupDurationMinutesController,
                                label: 'Tempo ate cliente',
                                hint: 'Ex: 5',
                                icon: Icons.timer_rounded,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                textInputAction: TextInputAction.done,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Obx(() {
                          controller.totalsRevision.value;
                          return _RideTotalsPreview(
                            totalDistance: controller.totalDistanceLabel,
                            totalDuration: controller.totalDurationLabel,
                            gainPerKm: '${controller.gainPerKmLabel}/km',
                            gainPerHour: '${controller.gainPerHourLabel}/h',
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    final isBusy =
                        controller.isSaving.value ||
                        controller.isReadingImage.value ||
                        controller.isEstimatingRoute.value;
                    return SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isBusy ? null : controller.saveRide,
                        icon: controller.isSaving.value
                            ? const AppLoadingIndicator(
                                size: AppLoadingSize.compact,
                                accentColor: Colors.white,
                                onDark: true,
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(controller.saveButtonLabel),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          disabledBackgroundColor: colorScheme.primary
                              .withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openRideSelector(BuildContext context) async {
    await controller.loadAvailableRides();
    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RideSelectorSheet(
        rides: controller.availableRides,
        selectedRide: controller.selectedRide.value,
        onSelected: (ride) {
          controller.selectRide(ride);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _SelectedRideSummary extends StatelessWidget {
  const _SelectedRideSummary({required this.label, required this.hasSelection});

  final String label;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: hasSelection
            ? AppColors.emerald.withValues(alpha: 0.12)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasSelection
              ? AppColors.emerald.withValues(alpha: 0.35)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasSelection
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            color: hasSelection
                ? AppColors.emerald
                : colorScheme.onSurfaceVariant,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: hasSelection
                    ? AppColors.emerald
                    : colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideSelectorSheet extends StatelessWidget {
  const _RideSelectorSheet({
    required this.rides,
    required this.selectedRide,
    required this.onSelected,
  });

  final List<RideEntity> rides;
  final RideEntity? selectedRide;
  final ValueChanged<RideEntity> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 720),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: _SectionTitle(
                  icon: Icons.directions_car_filled_outlined,
                  title: 'Selecionar corrida',
                  subtitle: 'Mais recentes primeiro',
                ),
              ),
              Flexible(
                child: rides.isEmpty
                    ? const _RideSelectorEmptyState()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                        itemBuilder: (context, index) {
                          final ride = rides[index];
                          return _RideSelectorTile(
                            ride: ride,
                            isSelected: selectedRide?.id == ride.id,
                            onTap: () => onSelected(ride),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemCount: rides.length,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideSelectorEmptyState extends StatelessWidget {
  const _RideSelectorEmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
      child: Text(
        'Nenhuma corrida encontrada.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RideSelectorTile extends StatelessWidget {
  const _RideSelectorTile({
    required this.ride,
    required this.isSelected,
    required this.onTap,
  });

  final RideEntity ride;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.royalBlue.withValues(alpha: 0.12)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.royalBlue
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppColors.royalBlue
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride.date} ${ride.time} - ${_formatRideCents(ride.grossValueCents)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${ride.passenger} | ${ride.origin} -> ${ride.destination}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRideCents(int cents) {
  final value = cents / 100;
  return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 42,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              'Toque para selecionar o print',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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
        Icon(icon, color: AppColors.royalBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: Responsive.sp(context, 17).clamp(16.0, 19.0),
                ),
              ),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.royalBlue, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.royalBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selectedOption,
    required this.onSelected,
  });

  final RidePaymentOption? selectedOption;
  final ValueChanged<RidePaymentOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.credit_card_rounded,
              color: AppColors.royalBlue,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Forma de pagamento',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...RidePaymentOption.all.map((option) {
          final isSelected = selectedOption?.code == option.code;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(option),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.royalBlue.withValues(alpha: 0.12)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.royalBlue
                          : colorScheme.outlineVariant,
                      width: isSelected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.royalBlue
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.royalBlue
                                : colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.royalBlue.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          option.icon,
                          color: AppColors.royalBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.royalBlue
                                : colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _RideTotalsPreview extends StatelessWidget {
  const _RideTotalsPreview({
    required this.totalDistance,
    required this.totalDuration,
    required this.gainPerKm,
    required this.gainPerHour,
  });

  final String totalDistance;
  final String totalDuration;
  final String gainPerKm;
  final String gainPerHour;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.royalBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.royalBlue.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total que sera salvo',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RideTotalChip(
                icon: Icons.straighten_rounded,
                label: totalDistance,
              ),
              _RideTotalChip(icon: Icons.timer_outlined, label: totalDuration),
              _RideTotalChip(icon: Icons.trending_up_rounded, label: gainPerKm),
              _RideTotalChip(icon: Icons.speed_rounded, label: gainPerHour),
            ],
          ),
        ],
      ),
    );
  }
}

class _RideTotalChip extends StatelessWidget {
  const _RideTotalChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.royalBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
