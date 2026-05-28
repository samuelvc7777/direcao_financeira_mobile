import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/credit_card_entity.dart';
import '../../../widgets/scale_button.dart';
import '../credit_cards_controller.dart';

class CreditCardFormSheet extends StatefulWidget {
  const CreditCardFormSheet({super.key, this.card, required this.controller});

  final CreditCardEntity? card;
  final CreditCardsController controller;

  @override
  State<CreditCardFormSheet> createState() => _CreditCardFormSheetState();
}

class _CreditCardFormSheetState extends State<CreditCardFormSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _limitController;
  late final TextEditingController _closingDayController;
  late final TextEditingController _dueDayController;
  late String _selectedColor;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();

    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.card?.name ?? '');
    _brandController = TextEditingController(text: widget.card?.brand ?? '');
    _limitController = TextEditingController(
      text: widget.card == null
          ? ''
          : (widget.card!.limitCents / 100.0).toStringAsFixed(2),
    );
    _closingDayController = TextEditingController(
      text: widget.card?.closingDay.toString() ?? '',
    );
    _dueDayController = TextEditingController(
      text: widget.card?.dueDay.toString() ?? '',
    );
    _selectedColor = widget.card?.color ?? widget.controller.colorOptions[5];
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _limitController.dispose();
    _closingDayController.dispose();
    _dueDayController.dispose();
    super.dispose();
  }

  Color get _accentColor => widget.controller.colorFromHex(_selectedColor);

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final isDark = context.theme.brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
              children: [
                // ── Header ──
                _SheetHeader(
                  isEditing: _isEditing,
                  accentColor: _accentColor,
                  onClose: () => Get.back(),
                ),

                // ── Conteúdo ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                    physics: const BouncingScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Card Preview ──
                          _CreditCardPreview(
                            name: _nameController.text.trim(),
                            brand: _brandController.text.trim(),
                            accentColor: _accentColor,
                          ),
                          const SizedBox(height: 28),

                          // ── Identidade ──
                          _FieldGroup(
                            icon: Icons.badge_rounded,
                            title: 'Identidade',
                            accentColor: _accentColor,
                            children: [
                              _StyledTextField(
                                controller: _nameController,
                                label: 'Nome do cartão',
                                hint: 'Ex.: Inter Black',
                                icon: Icons.credit_card_rounded,
                                accentColor: _accentColor,
                                validator: (v) => v?.trim().isEmpty ?? true
                                    ? 'Informe o nome.'
                                    : null,
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 14),
                              _StyledTextField(
                                controller: _brandController,
                                label: 'Bandeira',
                                hint: 'Visa, Mastercard',
                                icon: Icons.branding_watermark_rounded,
                                accentColor: _accentColor,
                                validator: (v) => v?.trim().isEmpty ?? true
                                    ? 'Informe.'
                                    : null,
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Fatura ──
                          _FieldGroup(
                            icon: Icons.receipt_long_rounded,
                            title: 'Fatura & Limite',
                            accentColor: _accentColor,
                            children: [
                              _StyledTextField(
                                controller: _limitController,
                                label: 'Limite total',
                                hint: 'R\$ 0,00',
                                icon: Icons.attach_money_rounded,
                                accentColor: _accentColor,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.right,
                                inputFormatters: [
                                  CurrencyTextInputFormatter.currency(
                                    locale: 'pt_BR',
                                    symbol: 'R\$',
                                  ),
                                ],
                                validator: (v) => v?.trim().isEmpty ?? true
                                    ? 'Informe o limite.'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StyledTextField(
                                      controller: _closingDayController,
                                      label: 'Fechamento',
                                      hint: 'Dia',
                                      icon: Icons.event_rounded,
                                      accentColor: _accentColor,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) {
                                        final day = int.tryParse(v ?? '');
                                        return (day == null ||
                                                day < 1 ||
                                                day > 31)
                                            ? 'Inválido.'
                                            : null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _StyledTextField(
                                      controller: _dueDayController,
                                      label: 'Vencimento',
                                      hint: 'Dia',
                                      icon: Icons.event_available_rounded,
                                      accentColor: _accentColor,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      validator: (v) {
                                        final day = int.tryParse(v ?? '');
                                        return (day == null ||
                                                day < 1 ||
                                                day > 31)
                                            ? 'Inválido.'
                                            : null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Cor ──
                          _FieldGroup(
                            icon: Icons.palette_rounded,
                            title: 'Visual',
                            accentColor: _accentColor,
                            children: [
                              _ColorPalette(
                                options: widget.controller.colorOptions,
                                selectedColor: _selectedColor,
                                controller: widget.controller,
                                onColorSelected: (hex) =>
                                    setState(() => _selectedColor = hex),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ── Botões ──
                          Obx(() {
                            final isLoading =
                                widget.controller.isSubmitting.value;

                            if (!_isEditing) {
                              return _PrimaryButton(
                                label: 'Criar Cartão',
                                icon: Icons.add_rounded,
                                color: _accentColor,
                                isLoading: isLoading,
                                onPressed: _handleSave,
                              );
                            }

                            return Row(
                              children: [
                                _ToggleStatusButton(
                                  isActive: widget.card!.isActive,
                                  isLoading: isLoading,
                                  onTap: () => widget.controller
                                      .toggleCardStatus(widget.card!),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PrimaryButton(
                                    label: 'Salvar',
                                    icon: Icons.check_rounded,
                                    color: _accentColor,
                                    isLoading: isLoading,
                                    onPressed: _handleSave,
                                  ),
                                ),
                              ],
                            );
                          }),
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
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final rawLimit = _limitController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limitCents = int.tryParse(rawLimit) ?? 0;
    final lastFourDigits = widget.card?.lastFourDigits ?? '0000';

    if (!_isEditing) {
      await widget.controller.createCreditCard(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        color: _selectedColor,
        limitCents: limitCents,
        closingDay: int.parse(_closingDayController.text),
        dueDay: int.parse(_dueDayController.text),
        lastFourDigits: lastFourDigits,
      );
      return;
    }

    await widget.controller.updateCreditCard(
      id: widget.card!.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      color: _selectedColor,
      limitCents: limitCents,
      closingDay: int.parse(_closingDayController.text),
      dueDay: int.parse(_dueDayController.text),
      lastFourDigits: lastFourDigits,
    );
  }
}

// ─────────────────────────────────────────────────────────
// HEADER DO SHEET
// ─────────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.isEditing,
    required this.accentColor,
    required this.onClose,
  });

  final bool isEditing;
  final Color accentColor;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 14, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: onSurface.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Editar Cartão' : 'Novo Cartão',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Atualize os dados do cartão'
                          : 'Preencha os dados para criar',
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.45),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: onSurface.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: onSurface.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: onSurface.withValues(alpha: 0.06)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PREVIEW DO CARTÃO DE CRÉDITO
// ─────────────────────────────────────────────────────────

class _CreditCardPreview extends StatelessWidget {
  const _CreditCardPreview({
    required this.name,
    required this.brand,
    required this.accentColor,
  });

  final String name;
  final String brand;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Nome do cartão' : name;
    final displayBrand = brand.isEmpty ? 'Bandeira' : brand;

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            Color.lerp(accentColor, Colors.black, 0.3) ?? accentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Topo: Chip + Brand
          Row(
            children: [
              // Chip do cartão simulado
              Container(
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  displayBrand.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          // Numero do cartao
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _CardNumberBlock(),
                const SizedBox(width: 14),
                _CardNumberBlock(),
                const SizedBox(width: 14),
                _CardNumberBlock(),
                const SizedBox(width: 14),
                _CardNumberBlock(),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Nome
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 6,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// GRUPO DE CAMPOS
// ─────────────────────────────────────────────────────────

class _CardNumberBlock extends StatelessWidget {
  const _CardNumberBlock();

  @override
  Widget build(BuildContext context) {
    return Text(
      '****',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 3,
      ),
    );
  }
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.children,
  });

  final IconData icon;
  final String title;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
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

// ─────────────────────────────────────────────────────────
// TEXT FIELD ESTILIZADO
// ─────────────────────────────────────────────────────────

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.accentColor,
    this.keyboardType,
    this.textAlign = TextAlign.start,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color accentColor;
  final TextInputType? keyboardType;
  final TextAlign textAlign;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      style: TextStyle(
        color: onSurface,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.5),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: onSurface.withValues(alpha: 0.25),
          fontSize: 14,
        ),
        prefixIcon: Icon(
          icon,
          color: accentColor.withValues(alpha: 0.7),
          size: 20,
        ),
        filled: true,
        fillColor: onSurface.withValues(alpha: 0.03),
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
          borderSide: BorderSide(color: accentColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.rose, width: 1.8),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// PALETA DE CORES
// ─────────────────────────────────────────────────────────

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({
    required this.options,
    required this.selectedColor,
    required this.controller,
    required this.onColorSelected,
  });

  final List<String> options;
  final String selectedColor;
  final CreditCardsController controller;
  final void Function(String) onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((colorHex) {
        final color = controller.colorFromHex(colorHex);
        final isSelected = selectedColor == colorHex;

        return GestureDetector(
          onTap: () => onColorSelected(colorHex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? context.theme.colorScheme.onSurface
                    : Colors.transparent,
                width: isSelected ? 2.5 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────
// BOTÕES
// ─────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
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
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: color.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          disabledBackgroundColor: color.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ToggleStatusButton extends StatelessWidget {
  const _ToggleStatusButton({
    required this.isActive,
    required this.isLoading,
    required this.onTap,
  });

  final bool isActive;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive ? AppColors.rose : AppColors.emerald;

    return ScaleButton(
      onTap: isLoading ? () {} : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
        ),
        child: Icon(
          isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: statusColor,
          size: 24,
        ),
      ),
    );
  }
}
