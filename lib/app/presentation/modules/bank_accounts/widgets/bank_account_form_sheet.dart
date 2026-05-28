import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/bank_account_entity.dart';
import '../../../widgets/scale_button.dart';
import '../bank_accounts_controller.dart';

class BankAccountFormSheet extends StatefulWidget {
  const BankAccountFormSheet({
    super.key,
    this.account,
    required this.controller,
  });

  final BankAccountEntity? account;
  final BankAccountsController controller;

  @override
  State<BankAccountFormSheet> createState() => _BankAccountFormSheetState();
}

class _BankAccountFormSheetState extends State<BankAccountFormSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _balanceController;
  late AccountType _selectedType;
  late String _selectedColor;

  bool get _isEditing => widget.account != null;

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
    _nameController = TextEditingController(text: widget.account?.name ?? '');
    _bankNameController = TextEditingController(
      text: widget.account?.bankName ?? '',
    );
    _balanceController = TextEditingController(
      text: widget.account == null
          ? ''
          : (widget.account!.initialBalanceCents / 100.0).toStringAsFixed(2),
    );
    _selectedType = widget.account?.accountType ?? AccountType.wallet;
    _selectedColor = widget.account?.color ?? widget.controller.colorOptions[1];
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _bankNameController.dispose();
    _balanceController.dispose();
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
                // ── Handle + Header ──
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
                          // ── Preview Card ──
                          _LivePreviewCard(
                            name: _nameController.text.trim(),
                            bankName: _bankNameController.text.trim(),
                            accountType: _selectedType,
                            accentColor: _accentColor,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 28),

                          // ── Informações Principais ──
                          _FieldGroup(
                            icon: Icons.badge_rounded,
                            title: 'Informações',
                            accentColor: _accentColor,
                            children: [
                              _StyledTextField(
                                controller: _nameController,
                                label: 'Nome da conta',
                                hint: 'Ex.: Caixa do dia',
                                icon: Icons.label_important_rounded,
                                accentColor: _accentColor,
                                validator: (v) => v?.trim().isEmpty ?? true
                                    ? 'Informe o nome.'
                                    : null,
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 14),
                              _StyledTextField(
                                controller: _bankNameController,
                                label: 'Instituição',
                                hint: 'Ex.: Nubank, Itaú, Dinheiro',
                                icon: Icons.account_balance_rounded,
                                accentColor: _accentColor,
                                validator: (v) => v?.trim().isEmpty ?? true
                                    ? 'Informe a instituição.'
                                    : null,
                                onChanged: (_) => setState(() {}),
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 14),
                              _StyledTextField(
                                controller: _balanceController,
                                label: 'Saldo inicial',
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
                                    ? 'Informe o saldo.'
                                    : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Tipo de Conta ──
                          _FixedTypeInfo(
                            accentColor: _accentColor,
                            accountType: _selectedType,
                            isEditing: _isEditing,
                          ),
                          const SizedBox(height: 24),

                          // ── Cor ──
                          _FieldGroup(
                            icon: Icons.palette_rounded,
                            title: 'Cor do cartão',
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
                                label: 'Criar Conta',
                                icon: Icons.add_rounded,
                                color: _accentColor,
                                isLoading: isLoading,
                                onPressed: _handleSave,
                              );
                            }

                            return Row(
                              children: [
                                _ToggleStatusButton(
                                  isActive: widget.account!.isActive,
                                  accentColor: _accentColor,
                                  isLoading: isLoading,
                                  onTap: () => widget.controller
                                      .toggleAccountStatus(widget.account!),
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

    final rawBalance = _balanceController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final balanceCents = int.tryParse(rawBalance) ?? 0;

    if (!_isEditing) {
      await widget.controller.createBankAccount(
        name: _nameController.text.trim(),
        bankName: _bankNameController.text.trim(),
        color: _selectedColor,
        accountType: AccountType.wallet,
        initialBalanceCents: balanceCents,
      );
      return;
    }

    await widget.controller.updateBankAccount(
      id: widget.account!.id,
      name: _nameController.text.trim(),
      bankName: _bankNameController.text.trim(),
      color: _selectedColor,
      accountType: widget.account!.accountType,
      initialBalanceCents: balanceCents,
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
          // Handle
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
                  Icons.account_balance_wallet_rounded,
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
                      isEditing ? 'Editar Conta' : 'Nova Conta',
                      style: TextStyle(
                        color: onSurface,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      isEditing
                          ? 'Atualize os dados da conta'
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
// PREVIEW CARD AO VIVO
// ─────────────────────────────────────────────────────────

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({
    required this.name,
    required this.bankName,
    required this.accountType,
    required this.accentColor,
    required this.isEditing,
  });

  final String name;
  final String bankName;
  final AccountType accountType;
  final Color accentColor;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final displayName = name.isEmpty ? 'Nome da conta' : name;
    final displayBank = bankName.isEmpty ? 'Instituição' : bankName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            Color.lerp(accentColor, Colors.black, 0.25) ?? accentColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForType(accountType),
                color: Colors.white.withValues(alpha: 0.9),
                size: 22,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  accountType.label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayBank,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'Preview ao vivo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
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
    final colorScheme = context.theme.colorScheme;
    final onSurface = colorScheme.onSurface;

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
// TYPE CHIP
// ─────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────
// PALETA DE CORES
// ─────────────────────────────────────────────────────────

class _FixedTypeInfo extends StatelessWidget {
  const _FixedTypeInfo({
    required this.accentColor,
    required this.accountType,
    required this.isEditing,
  });

  final Color accentColor;
  final AccountType accountType;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.theme.colorScheme.onSurface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _iconForType(accountType),
              color: accentColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo fixo',
                  style: TextStyle(
                    color: onSurface.withValues(alpha: 0.55),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  accountType.label,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (!isEditing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Padrão',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({
    required this.options,
    required this.selectedColor,
    required this.controller,
    required this.onColorSelected,
  });

  final List<String> options;
  final String selectedColor;
  final BankAccountsController controller;
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
                ? Icon(Icons.check_rounded, color: Colors.white, size: 20)
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
    required this.accentColor,
    required this.isLoading,
    required this.onTap,
  });

  final bool isActive;
  final Color accentColor;
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

// ─────────────────────────────────────────────────────────
// UTILS
// ─────────────────────────────────────────────────────────

IconData _iconForType(AccountType type) {
  switch (type) {
    case AccountType.checking:
      return Icons.account_balance_rounded;
    case AccountType.savings:
      return Icons.savings_rounded;
    case AccountType.wallet:
      return Icons.account_balance_wallet_rounded;
    case AccountType.investment:
      return Icons.show_chart_rounded;
    case AccountType.other:
      return Icons.layers_clear_rounded;
  }
}
