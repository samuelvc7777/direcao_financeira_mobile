import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/bank_account_entity.dart';
import '../../../../domain/entities/credit_card_entity.dart';
import '../../../../domain/services/invoice_payment_validator.dart';

class InvoicePaymentFormResult {
  const InvoicePaymentFormResult({
    required this.bankAccount,
    required this.mode,
    this.amountCents,
  });

  final BankAccountEntity bankAccount;
  final InvoicePaymentMode mode;
  final int? amountCents;
}

typedef InvoicePaymentSubmit =
    Future<String?> Function(InvoicePaymentFormResult result);

Future<bool> showInvoicePaymentSheet({
  required BuildContext context,
  required CreditCardEntity card,
  required List<BankAccountEntity> accounts,
  required InvoicePaymentSubmit onSubmit,
}) async {
  final activeAccounts = accounts.where((account) => account.isActive).toList();
  if (activeAccounts.isEmpty) {
    Get.snackbar('Atencao', 'Cadastre uma conta antes de pagar a fatura.');
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return InvoicePaymentSheet(
        card: card,
        accounts: activeAccounts,
        onSubmit: onSubmit,
      );
    },
  );

  return result ?? false;
}

class InvoicePaymentSheet extends StatefulWidget {
  const InvoicePaymentSheet({
    super.key,
    required this.card,
    required this.accounts,
    required this.onSubmit,
  });

  final CreditCardEntity card;
  final List<BankAccountEntity> accounts;
  final InvoicePaymentSubmit onSubmit;

  @override
  State<InvoicePaymentSheet> createState() => _InvoicePaymentSheetState();
}

class _InvoicePaymentSheetState extends State<InvoicePaymentSheet> {
  final _amountController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _amountFormatter = CurrencyTextInputFormatter.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  BankAccountEntity? _selectedAccount;
  InvoicePaymentMode _mode = InvoicePaymentMode.total;
  String? _errorText;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final colorScheme = context.theme.colorScheme;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.88,
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PaymentHeader(card: widget.card),
                  const SizedBox(height: 20),
                  _StepLabel(
                    number: '1',
                    title: 'Escolha a conta',
                    subtitle: 'A saida sera registrada na conta selecionada.',
                  ),
                  const SizedBox(height: 12),
                  ...widget.accounts.map(
                    (account) => _AccountOption(
                      account: account,
                      isSelected: _selectedAccount?.id == account.id,
                      currencyFormat: _currencyFormat,
                      onTap: _isSubmitting
                          ? null
                          : () => setState(() {
                              _selectedAccount = account;
                              _errorText = null;
                            }),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _StepLabel(
                    number: '2',
                    title: 'Tipo de pagamento',
                    subtitle: 'Total quita tudo; parcial reduz a fatura atual.',
                  ),
                  const SizedBox(height: 12),
                  _PaymentModeSelector(
                    selectedMode: _mode,
                    totalLabel: _currencyFormat.format(
                      widget.card.payableInvoice,
                    ),
                    onChanged: _isSubmitting
                        ? null
                        : (mode) => setState(() {
                            _mode = mode;
                            _errorText = null;
                          }),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _mode == InvoicePaymentMode.partial
                        ? Padding(
                            key: const ValueKey('partial-amount-field'),
                            padding: const EdgeInsets.only(top: 14),
                            child: TextField(
                              key: const Key('invoice-partial-amount-field'),
                              controller: _amountController,
                              enabled: !_isSubmitting,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              textAlign: TextAlign.right,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _amountFormatter,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Valor parcial',
                                hintText: 'R\$ 0,00',
                                helperText:
                                    'Informe menos que ${_currencyFormat.format(widget.card.payableInvoice)}.',
                                prefixIcon: const Icon(Icons.payments_rounded),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onChanged: (_) {
                                if (_errorText != null) {
                                  setState(() => _errorText = null);
                                }
                              },
                              onSubmitted: (_) => _submit(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: _errorText!),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('invoice-payment-confirm-button'),
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        _isSubmitting
                            ? 'Confirmando...'
                            : 'Confirmar pagamento',
                        style: const TextStyle(fontWeight: FontWeight.w800),
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
    final selectedAccount = _selectedAccount;
    if (selectedAccount == null) {
      setState(() => _errorText = 'Escolha a conta de origem.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final error = await widget.onSubmit(
      InvoicePaymentFormResult(
        bankAccount: selectedAccount,
        mode: _mode,
        amountCents: _mode == InvoicePaymentMode.partial
            ? _parseCurrencyToCents(_amountController.text)
            : null,
      ),
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _errorText = error;
      _isSubmitting = false;
    });
  }

  int _parseCurrencyToCents(String value) {
    return int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }
}

class _PaymentHeader extends StatelessWidget {
  const _PaymentHeader({required this.card});

  final CreditCardEntity card;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$',
    );
    final colorScheme = context.theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.credit_card_rounded, color: AppColors.violet),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagar fatura do ${card.name}',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saldo em aberto: ${currencyFormat.format(card.payableInvoice)}',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: AppColors.violet.withValues(alpha: 0.14),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.violet,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
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
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.54),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.account,
    required this.isSelected,
    required this.currencyFormat,
    required this.onTap,
  });

  final BankAccountEntity account;
  final bool isSelected;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final borderColor = isSelected
        ? AppColors.violet
        : colorScheme.onSurface.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        key: Key('invoice-account-${account.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.violet.withValues(alpha: 0.08)
                : colorScheme.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected
                    ? AppColors.violet
                    : colorScheme.onSurface.withValues(alpha: 0.42),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.bankName,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(account.currentBalance),
                style: const TextStyle(
                  color: AppColors.emerald,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentModeSelector extends StatelessWidget {
  const _PaymentModeSelector({
    required this.selectedMode,
    required this.totalLabel,
    required this.onChanged,
  });

  final InvoicePaymentMode selectedMode;
  final String totalLabel;
  final ValueChanged<InvoicePaymentMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeCard(
            key: const Key('invoice-total-mode-option'),
            title: 'Total',
            subtitle: totalLabel,
            icon: Icons.done_all_rounded,
            isSelected: selectedMode == InvoicePaymentMode.total,
            onTap: onChanged == null
                ? null
                : () => onChanged!(InvoicePaymentMode.total),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeCard(
            key: const Key('invoice-partial-mode-option'),
            title: 'Parcial',
            subtitle: 'Escolher valor',
            icon: Icons.tune_rounded,
            isSelected: selectedMode == InvoicePaymentMode.partial,
            onTap: onChanged == null
                ? null
                : () => onChanged!(InvoicePaymentMode.partial),
          ),
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;
    final accent = isSelected ? AppColors.violet : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isSelected ? 0.10 : 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent.withValues(alpha: isSelected ? 0.42 : 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('invoice-payment-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rose.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.rose.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppColors.rose, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(
                  alpha: 0.82,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
