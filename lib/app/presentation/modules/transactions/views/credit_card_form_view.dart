import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/feedback/app_snackbar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/credit_card_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../widgets/app_loading_indicator.dart';
import '../transactions_controller.dart';

class CreditCardFormView extends GetView<TransactionsController> {
  CreditCardFormView({super.key})
    : editingTransaction = Get.arguments is TransactionEntity
          ? Get.arguments as TransactionEntity
          : null {
    if (editingTransaction != null) {
      final trans = editingTransaction!;
      amountController.text = NumberFormat.currency(
        locale: 'pt_BR',
        symbol: 'R\$',
      ).format(trans.amountCents / 100);
      descriptionController.text = trans.description;
      selectedDate.value = trans.transactionDate;
      installmentCount.value = trans.installmentCount ?? 1;
      selectedCard.value = controller.activeCards.firstWhereOrNull(
        (c) => c.id == trans.creditCardId,
      );
      selectedCategory.value = controller.categories.firstWhereOrNull(
        (c) => c.id == trans.categoryId,
      );
    }
    amountFocusNode.addListener(
      () => isAmountFocused.value = amountFocusNode.hasFocus,
    );
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode amountFocusNode = FocusNode();
  final TransactionEntity? editingTransaction;
  final RxBool isAmountFocused = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxInt installmentCount = 1.obs;
  final Rx<CreditCardEntity?> selectedCard = Rx<CreditCardEntity?>(null);
  final Rx<CategoryEntity?> selectedCategory = Rx<CategoryEntity?>(null);

  void _incrementInstallments() {
    if (editingTransaction == null && installmentCount.value < 48) {
      installmentCount.value++;
    }
  }

  void _decrementInstallments() {
    if (editingTransaction == null && installmentCount.value > 1) {
      installmentCount.value--;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final editing = editingTransaction != null;
    final activeColor = AppColors.violet;
    final textColor = cs.onSurface;
    final muted = cs.onSurface.withValues(alpha: 0.64);
    final subtle = cs.onSurface.withValues(alpha: 0.48);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          editing ? 'Editar Compra' : 'Nova Compra',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppLoadingScreen(
            label: 'Carregando compra',
            accentColor: AppColors.violet,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TypeTab(
                  label: editing ? 'Editar Cartão' : 'Cartão de Crédito',
                  icon: Icons.credit_card_rounded,
                  activeColor: activeColor,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: amountController,
                  focusNode: amountFocusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                  ),
                  decoration: InputDecoration(
                    hintText: 'R\$ 0,00',
                    hintStyle: TextStyle(
                      color: subtle,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  inputFormatters: [
                    CurrencyTextInputFormatter.currency(
                      locale: 'pt_BR',
                      symbol: 'R\$',
                    ),
                  ],
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Informe o valor.';
                    final numValue =
                        int.tryParse(v!.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    return numValue <= 0 ? 'Maior que zero.' : null;
                  },
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => isAmountFocused.value
                      ? amountFocusNode.unfocus()
                      : amountFocusNode.requestFocus(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isAmountFocused.value
                            ? 'Toque para sair'
                            : 'Toque para digitar',
                        style: TextStyle(
                          color: subtle,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isAmountFocused.value
                            ? Icons.keyboard_hide_outlined
                            : Icons.keyboard_alt_outlined,
                        size: 16,
                        color: subtle,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DETALHES DA COMPRA',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: activeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.view_agenda_rounded,
                          color: activeColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parcelamento',
                              style: TextStyle(color: muted, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              editing ? 'Parcela atual' : 'Quantidade de vezes',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (editing)
                        Text(
                          '${editingTransaction!.installmentNumber}/${editingTransaction!.installmentCount}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _decrementInstallments,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Icon(
                                    Icons.remove_rounded,
                                    color: installmentCount.value > 1
                                        ? textColor
                                        : textColor.withValues(alpha: 0.24),
                                    size: 20,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                child: Text(
                                  '${installmentCount.value}x',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _incrementInstallments,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: installmentCount.value < 48
                                        ? textColor
                                        : textColor.withValues(alpha: 0.24),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _DateChip(
                        label: 'Hoje',
                        isSelected: _isSameDay(
                          selectedDate.value,
                          DateTime.now(),
                        ),
                        activeColor: activeColor,
                        onTap: () => selectedDate.value = DateTime.now(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateChip(
                        label: 'Ontem',
                        isSelected: _isSameDay(
                          selectedDate.value,
                          DateTime.now().subtract(const Duration(days: 1)),
                        ),
                        activeColor: activeColor,
                        onTap: () => selectedDate.value = DateTime.now()
                            .subtract(const Duration(days: 1)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateChip(
                        label: 'Data',
                        icon: Icons.calendar_today_outlined,
                        isSelected:
                            !_isSameDay(selectedDate.value, DateTime.now()) &&
                            !_isSameDay(
                              selectedDate.value,
                              DateTime.now().subtract(const Duration(days: 1)),
                            ),
                        activeColor: activeColor,
                        onTap: () => _pickDate(context, activeColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _SelectionField<CreditCardEntity>(
                  label: 'Cartão',
                  hint: 'Toque para selecionar',
                  icon: Icons.credit_card_rounded,
                  value: selectedCard.value,
                  items: controller.activeCards,
                  itemLabelBuilder: (c) => c.name,
                  onChanged: (v) => selectedCard.value = v,
                ),
                const SizedBox(height: 14),
                _SelectionField<CategoryEntity>(
                  label: 'Categoria',
                  hint: 'Toque para selecionar',
                  icon: Icons.category_outlined,
                  value: selectedCategory.value,
                  items: controller.expenseCategories,
                  itemLabelBuilder: (c) => c.name,
                  onChanged: (v) => selectedCategory.value = v,
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  child: Row(
                    children: [
                      Icon(Icons.notes_rounded, color: muted, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: descriptionController,
                          style: TextStyle(color: textColor, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Descrição (opcional)',
                            hintStyle: TextStyle(color: muted, fontSize: 15),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: cs.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: cs.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            editing ? 'Salvar Alterações' : 'Salvar Compra',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      }),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickDate(BuildContext context, Color activeColor) async {
    final theme = context.theme;
    final cs = theme.colorScheme;
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: cs.copyWith(
            primary: activeColor,
            onPrimary: cs.onPrimary,
            surface: cs.surface,
            onSurface: cs.onSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) selectedDate.value = date;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCard.value == null) {
      AppSnackbar.show('Atenção', 'Selecione o cartão.');
      return;
    }
    if (selectedCategory.value == null) {
      AppSnackbar.show('Atenção', 'Selecione a categoria.');
      return;
    }
    final amountCents =
        int.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    if (editingTransaction != null) {
      if (editingTransaction!.installmentGroupId != null) {
        _showScopeDialog(amountCents);
      } else {
        await controller.updateTransaction(
          editingTransaction!.id,
          categoryId: selectedCategory.value!.id,
          description: descriptionController.text.trim().isEmpty
              ? selectedCategory.value!.name
              : descriptionController.text.trim(),
          amountCents: amountCents,
          transactionDate: selectedDate.value,
          scope: TransactionMutationScope.current,
        );
      }
    } else {
      await controller.createTransaction(
        type: TransactionType.expense,
        assetType: AssetType.creditCard,
        amountCents: amountCents,
        categoryId: selectedCategory.value!.id,
        description: descriptionController.text.trim().isEmpty
            ? selectedCategory.value!.name
            : descriptionController.text.trim(),
        transactionDate: selectedDate.value,
        creditCardId: selectedCard.value!.id,
        installmentCount: installmentCount.value,
      );
    }
  }

  void _showScopeDialog(int amountCents) {
    final cs = Get.theme.colorScheme;
    Get.dialog(
      AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Editar Parcelamento',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Deseja aplicar as mudanças apenas nesta parcela ou em todas?',
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.72)),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.62)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performUpdate(amountCents, TransactionMutationScope.all);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
              elevation: 0,
            ),
            child: const Text('Todas'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _performUpdate(amountCents, TransactionMutationScope.current);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: cs.onPrimary,
            ),
            child: const Text('Apenas esta'),
          ),
        ],
      ),
    );
  }

  void _performUpdate(int amountCents, TransactionMutationScope scope) {
    controller.updateTransaction(
      editingTransaction!.id,
      categoryId: selectedCategory.value!.id,
      description: descriptionController.text.trim().isEmpty
          ? selectedCategory.value!.name
          : descriptionController.text.trim(),
      amountCents: amountCents,
      transactionDate: selectedDate.value,
      scope: scope,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.activeColor,
  });
  final String label;
  final IconData icon;
  final Color activeColor;
  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: activeColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: activeColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
    this.icon,
  });
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final textColor = isSelected
        ? activeColor
        : cs.onSurface.withValues(alpha: 0.58);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.3)
                : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionField<T> extends StatelessWidget {
  const _SelectionField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final IconData icon;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final ValueChanged<T?> onChanged;

  void _showSelectionModal(BuildContext context) {
    final theme = context.theme;
    final cs = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: cs.primary, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Selecionar $label',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = item == value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onChanged(item);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? cs.primary.withValues(alpha: 0.08)
                                : cs.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? cs.primary.withValues(alpha: 0.45)
                                  : cs.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  itemLabelBuilder(item),
                                  style: TextStyle(
                                    color: selected ? cs.primary : cs.onSurface,
                                    fontSize: 16,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: cs.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.theme.colorScheme;
    final hasValue = value != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSelectionModal(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.onSurfaceVariant, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.onSurface.withValues(alpha: 0.56),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasValue ? itemLabelBuilder(value as T) : hint,
                      style: TextStyle(
                        color: hasValue
                            ? cs.onSurface
                            : cs.onSurface.withValues(alpha: 0.5),
                        fontSize: 15,
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
