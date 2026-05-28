import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/goal_entity.dart';
import '../goals_controller.dart';

class GoalFormSheet extends StatefulWidget {
  const GoalFormSheet({super.key, this.goal});

  final GoalEntity? goal;

  @override
  State<GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<GoalFormSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _currentController;
  late final CurrencyTextInputFormatter _currencyFormatter;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  DateTime? _targetDate;

  GoalsController get _controller => Get.find<GoalsController>();
  bool get _isEditing => widget.goal != null;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();

    _currencyFormatter = CurrencyTextInputFormatter.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
      decimalDigits: 2,
    );
    _nameController = TextEditingController(text: widget.goal?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.goal?.description ?? '',
    );
    _targetController = TextEditingController(
      text: _formatInitial(widget.goal?.targetAmountCents),
    );
    _currentController = TextEditingController(
      text: _formatInitial(widget.goal?.currentAmountCents),
    );
    _targetDate = widget.goal?.targetDate;

    _nameController.addListener(_refreshPreview);
    _targetController.addListener(_refreshPreview);
    _currentController.addListener(_refreshPreview);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController
      ..removeListener(_refreshPreview)
      ..dispose();
    _descriptionController.dispose();
    _targetController
      ..removeListener(_refreshPreview)
      ..dispose();
    _currentController
      ..removeListener(_refreshPreview)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    isEditing: _isEditing,
                    onClose: () => Get.back<void>(),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _GoalPreviewCard(
                              name: _nameController.text,
                              currentAmountCents: _parseCents(
                                _currentController.text,
                              ),
                              targetAmountCents: _parseCents(
                                _targetController.text,
                              ),
                              targetDate: _targetDate,
                            ),
                            const SizedBox(height: 24),
                            _FieldGroup(
                              icon: Icons.flag_rounded,
                              title: 'Detalhes da meta',
                              children: [
                                _StyledGoalField(
                                  controller: _nameController,
                                  label: 'Nome da meta',
                                  hint: 'Ex.: Reserva do carro',
                                  icon: Icons.label_important_rounded,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (value) {
                                    if ((value ?? '').trim().isEmpty) {
                                      return 'Informe o nome da meta.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _StyledGoalField(
                                  controller: _descriptionController,
                                  label: 'Descricao',
                                  hint: 'Opcional',
                                  icon: Icons.notes_rounded,
                                  maxLines: 2,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _FieldGroup(
                              icon: Icons.savings_rounded,
                              title: 'Valores',
                              children: [
                                _StyledGoalField(
                                  controller: _targetController,
                                  label: 'Valor objetivo',
                                  hint: 'R\$ 0,00',
                                  icon: Icons.track_changes_rounded,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  inputFormatters: [_currencyFormatter],
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (_parseCents(value) <= 0) {
                                      return 'Informe um objetivo maior que zero.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                                _StyledGoalField(
                                  controller: _currentController,
                                  label: 'Valor atual',
                                  hint: 'R\$ 0,00',
                                  icon: Icons.account_balance_wallet_rounded,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  inputFormatters: [_currencyFormatter],
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _FieldGroup(
                              icon: Icons.event_available_rounded,
                              title: 'Prazo',
                              children: [
                                _TargetDateSelector(
                                  date: _targetDate,
                                  formatter: _dateFormat,
                                  onTap: _pickTargetDate,
                                ),
                                if (_targetDate == null) ...[
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Informe uma data limite para a meta.',
                                    style: TextStyle(
                                      color: AppColors.rose,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 28),
                            Obx(
                              () => _PrimaryButton(
                                label: _isEditing
                                    ? 'Salvar meta'
                                    : 'Criar meta',
                                icon: _isEditing
                                    ? Icons.check_rounded
                                    : Icons.add_rounded,
                                isLoading: _controller.isSubmitting.value,
                                onPressed: _submit,
                              ),
                            ),
                          ],
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_targetDate == null) {
      setState(() {});
      return;
    }

    final success = _isEditing
        ? await _controller.updateGoal(
            id: widget.goal!.id,
            name: _nameController.text,
            description: _descriptionController.text,
            targetAmountCents: _parseCents(_targetController.text),
            currentAmountCents: _parseCents(_currentController.text),
            targetDate: _targetDate,
          )
        : await _controller.createGoal(
            name: _nameController.text,
            description: _descriptionController.text,
            targetAmountCents: _parseCents(_targetController.text),
            currentAmountCents: _parseCents(_currentController.text),
            targetDate: _targetDate,
          );

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final initialDate = _targetDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 20),
      helpText: 'Data limite da meta',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.amber,
              secondary: AppColors.amber,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _targetDate = picked);
    }
  }

  String _formatInitial(int? cents) {
    if (cents == null) {
      return '';
    }

    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(cents / 100);
  }

  int _parseCents(String? value) {
    final onlyDigits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) {
      return 0;
    }

    return int.tryParse(onlyDigits) ?? 0;
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.isEditing, required this.onClose});

  final bool isEditing;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 14, 18),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  color: AppColors.amber,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar meta' : 'Nova meta',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Acompanhe objetivo e progresso real',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Fechar',
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalPreviewCard extends StatelessWidget {
  _GoalPreviewCard({
    required this.name,
    required this.currentAmountCents,
    required this.targetAmountCents,
    required this.targetDate,
  });

  final String name;
  final int currentAmountCents;
  final int targetAmountCents;
  final DateTime? targetDate;
  final NumberFormat _currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final progress = targetAmountCents <= 0
        ? 0.0
        : (currentAmountCents / targetAmountCents).clamp(0.0, 1.0);
    final percent = progress * 100;
    final resolvedName = name.trim().isEmpty ? 'Sua proxima meta' : name.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  resolvedName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${percent.toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: AppColors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.amber),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_currency.format(currentAmountCents / 100)} de ${_currency.format(targetAmountCents / 100)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface.withValues(alpha: 0.62),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (targetDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.42),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Limite: ${_dateFormat.format(targetDate!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.56),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TargetDateSelector extends StatelessWidget {
  const _TargetDateSelector({
    required this.date,
    required this.formatter,
    required this.onTap,
  });

  final DateTime? date;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final hasDate = date != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasDate
                  ? AppColors.amber.withValues(alpha: 0.45)
                  : AppColors.rose.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: hasDate ? AppColors.amber : AppColors.rose,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data limite',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.52),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDate ? formatter.format(date!) : 'Selecionar prazo',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.70),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }
}

class _StyledGoalField extends StatelessWidget {
  const _StyledGoalField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.validator,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      validator: validator,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      onFieldSubmitted: onFieldSubmitted,
      style: TextStyle(
        color: onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: AppColors.amber.withValues(alpha: 0.82),
          size: 20,
        ),
        labelStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.52),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.28),
          fontSize: 14,
        ),
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.035),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.8),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.amber,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.amber.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
