import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/responsive.dart';
import '../../../domain/entities/ride_entity.dart';
import '../../../domain/usecases/ride_status_use_cases.dart';
import '../../widgets/custom_app_bar.dart';
import 'journey_controller.dart';
import 'widgets/ride_details_atoms.dart';
import 'widgets/ride_details_cards.dart';
import 'widgets/ride_details_models.dart';

/// Tela de detalhes de uma corrida.
///
/// Responsabilidade: orquestrar os widgets especialistas.
/// Nao contém logica de negócio nem estilos inline.
class RideDetailsView extends StatefulWidget {
  const RideDetailsView({super.key});

  @override
  State<RideDetailsView> createState() => _RideDetailsViewState();
}

class _RideDetailsViewState extends State<RideDetailsView> {
  late final FinishRideUseCase _finishRideUseCase;
  late final CancelRideUseCase _cancelRideUseCase;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _finishRideUseCase = Get.find<FinishRideUseCase>();
    _cancelRideUseCase = Get.find<CancelRideUseCase>();
  }

  Future<void> _finishRide(
    RideEntity ride,
    RidePaymentOption paymentOption,
  ) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final result = await _finishRideUseCase(
      rideId: ride.id,
      paymentMethod: paymentOption.code,
    );
    if (!mounted) return;

    await result.fold<Future<void>>(
      (failure) async {
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'Erro ao finalizar',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (_) async {
        await _refreshJourneyMetrics();
        if (!mounted) return;

        Get.back();
        Get.snackbar(
          'Corrida finalizada',
          'Forma de pagamento salva com sucesso.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Future<void> _cancelRide(RideEntity ride, String reason) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final result = await _cancelRideUseCase(
      rideId: ride.id,
      cancelReason: reason,
    );
    if (!mounted) return;

    await result.fold<Future<void>>(
      (failure) async {
        setState(() => _isSubmitting = false);
        Get.snackbar(
          'Erro ao cancelar',
          failure.message,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      (_) async {
        await _refreshJourneyMetrics();
        if (!mounted) return;

        Get.back();
        Get.snackbar(
          'Corrida cancelada',
          'Motivo do cancelamento salvo com sucesso.',
          snackPosition: SnackPosition.BOTTOM,
        );
      },
    );
  }

  Future<void> _refreshJourneyMetrics() async {
    if (!Get.isRegistered<JourneyController>()) {
      return;
    }

    await Get.find<JourneyController>().refreshJourneyData(
      silent: true,
      showErrors: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = Get.arguments as RideEntity?;
    final colorScheme = context.theme.colorScheme;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Detalhes da Corrida',
        subtitle: 'Resumo da corrida salva',
        leadingIcon: Icons.directions_car_rounded,
      ),
      // ── Barra de ações fixa no bottom ────────────────────────────────────
      bottomNavigationBar: ride == null
          ? null
          : ride.status != 'PENDING'
          ? null
          : RideBottomActionBar(
              isLoading: _isSubmitting,
              onCancel: (reason) => _cancelRide(ride, reason),
              onFinish: (paymentOption) => _finishRide(ride, paymentOption),
            ),
      body: ride == null
          ? _RideNotFound(colorScheme: colorScheme)
          : _RideDetailsBody(ride: ride, isDark: isDark),
    );
  }
}

// ─── Estado vazio ──────────────────────────────────────────────────────────

class _RideNotFound extends StatelessWidget {
  const _RideNotFound({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.no_transfer_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Corrida nao encontrada.',
            style: context.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Corpo principal ───────────────────────────────────────────────────────

class _RideDetailsBody extends StatefulWidget {
  const _RideDetailsBody({required this.ride, required this.isDark});

  final RideEntity ride;
  final bool isDark;

  @override
  State<_RideDetailsBody> createState() => _RideDetailsBodyState();
}

class _RideDetailsBodyState extends State<_RideDetailsBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final isDark = widget.isDark;
    final status = RideStatusData.from(ride.status);

    final hPad = Responsive.hp(context, 4.0).clamp(14.0, 20.0);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RideValueHeroCard(ride: ride, isDark: isDark),
                  const SizedBox(height: 16),

                  RideSectionLabel(
                    label: 'Rota',
                    icon: Icons.map_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  RideRouteCard(ride: ride, isDark: isDark),
                  const SizedBox(height: 16),

                  RideSectionLabel(
                    label: 'Métricas',
                    icon: Icons.bar_chart_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  RideMetricsGrid(ride: ride, isDark: isDark),
                  const SizedBox(height: 16),

                  RideSectionLabel(
                    label: 'Informações',
                    icon: Icons.info_outline_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  RideInfoCard(ride: ride, status: status, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
