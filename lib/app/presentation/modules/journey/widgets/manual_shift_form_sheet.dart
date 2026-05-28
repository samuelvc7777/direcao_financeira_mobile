import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../../../widgets/custom_text_field.dart';
import '../journey_controller.dart';

class ManualShiftFormSheet extends StatefulWidget {
  const ManualShiftFormSheet({super.key, required this.controller});

  final JourneyController controller;

  static Future<void> show(
    BuildContext context, {
    required JourneyController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualShiftFormSheet(controller: controller),
    );
  }

  @override
  State<ManualShiftFormSheet> createState() => _ManualShiftFormSheetState();
}

class _ManualShiftFormSheetState extends State<ManualShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _kmController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          Responsive.hp(context, 5).clamp(18.0, 24.0),
          Responsive.vp(context, 2.4).clamp(16.0, 24.0),
          Responsive.hp(context, 5).clamp(18.0, 24.0),
          Responsive.vp(context, 2.8).clamp(18.0, 26.0),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.deepNavy : colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.14),
              blurRadius: 22,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              SizedBox(height: Responsive.vp(context, 2).clamp(14.0, 20.0)),
              Text(
                'Adicionar turno',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: Responsive.sp(context, 20).clamp(18.0, 22.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: Responsive.vp(context, 0.8).clamp(6.0, 10.0)),
              Text(
                'Informe os dados do turno manual. Ele entra no historico sem rota registrada.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.68),
                  fontSize: Responsive.sp(context, 13).clamp(12.0, 15.0),
                  height: 1.35,
                ),
              ),
              SizedBox(height: Responsive.vp(context, 2.4).clamp(16.0, 22.0)),
              CustomTextField(
                controller: _kmController,
                label: 'Km rodados',
                hint: 'Ex: 124,5',
                icon: Icons.route_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                ],
                textInputAction: TextInputAction.next,
                validator: (value) => _validatePositiveDecimal(
                  value,
                  emptyMessage: 'Informe os km rodados.',
                ),
              ),
              SizedBox(height: Responsive.vp(context, 1.6).clamp(12.0, 18.0)),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerField(
                      label: 'Inicio',
                      value: _startTime,
                      icon: Icons.play_arrow_rounded,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  SizedBox(width: Responsive.hp(context, 3).clamp(10.0, 16.0)),
                  Expanded(
                    child: _TimePickerField(
                      label: 'Fim',
                      value: _endTime,
                      icon: Icons.stop_rounded,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              SizedBox(height: Responsive.vp(context, 2.6).clamp(18.0, 26.0)),
              Obx(() {
                final isLoading = widget.controller.isAddingManualShift.value;
                return SizedBox(
                  height: Responsive.vp(context, 6.2).clamp(48.0, 56.0),
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _submit,
                    icon: isLoading
                        ? const AppLoadingIndicator(
                            size: AppLoadingSize.compact,
                            accentColor: Colors.white,
                            onDark: true,
                          )
                        : const Icon(
                            Icons.add_circle_outline_rounded,
                            color: Colors.white,
                          ),
                    label: const Text(
                      'ADICIONAR TURNO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.royalBlue,
                      disabledBackgroundColor: AppColors.royalBlue.withValues(
                        alpha: 0.45,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
    );
  }

  String? _validatePositiveDecimal(
    String? value, {
    required String emptyMessage,
  }) {
    final parsed = _parseDecimal(value);
    if (parsed == null) {
      return emptyMessage;
    }
    if (parsed <= 0) {
      return 'Informe um valor maior que zero.';
    }
    return null;
  }

  double? _parseDecimal(String? value) {
    final normalized = value?.trim().replaceAll(',', '.');
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initialTime = isStart
        ? _startTime ?? TimeOfDay.now()
        : _endTime ?? _startTime ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.royalBlue),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit() async {
    debugPrint('[ManualShiftFormSheet] Submit iniciado.');
    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint(
        '[ManualShiftFormSheet] Submit bloqueado: formulario invalido.',
      );
      return;
    }

    if (_startTime == null || _endTime == null) {
      debugPrint(
        '[ManualShiftFormSheet] Submit bloqueado: horario inicial/final ausente.',
      );
      _showFormError('Selecione o horario de inicio e fim do turno.');
      return;
    }

    if (_startTime!.hour == _endTime!.hour &&
        _startTime!.minute == _endTime!.minute) {
      debugPrint(
        '[ManualShiftFormSheet] Submit bloqueado: horarios iguais ${_startTime!.format(context)}.',
      );
      _showFormError('O horario final precisa ser diferente do inicial.');
      return;
    }

    final (:startTime, :endTime) = _resolveShiftTimes(
      start: _startTime!,
      end: _endTime!,
    );
    final drivenKm = _parseDecimal(_kmController.text)!;
    debugPrint(
      '[ManualShiftFormSheet] Enviando turno manual: km=$drivenKm '
      'start=$startTime end=$endTime.',
    );

    final added = await widget.controller.addManualShift(
      drivenKm: drivenKm,
      startTime: startTime,
      endTime: endTime,
    );
    debugPrint('[ManualShiftFormSheet] Resultado addManualShift=$added.');

    if (!mounted || !added) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _showFormError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  ({DateTime startTime, DateTime endTime}) _resolveShiftTimes({
    required TimeOfDay start,
    required TimeOfDay end,
  }) {
    final now = DateTime.now();
    DateTime atToday(TimeOfDay value) =>
        DateTime(now.year, now.month, now.day, value.hour, value.minute);

    var startTime = atToday(start);
    var endTime = atToday(end);
    if (!endTime.isAfter(startTime)) {
      endTime = endTime.add(const Duration(days: 1));
    }

    return (startTime: startTime, endTime: endTime);
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final TimeOfDay? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value == null ? '--:--' : value!.format(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: value == null
                          ? colorScheme.onSurface.withValues(alpha: 0.32)
                          : colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
