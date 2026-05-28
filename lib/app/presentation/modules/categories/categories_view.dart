import 'package:direcao_financeira_mobile/app/presentation/widgets/scale_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/category_entity.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_filled_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/app_loading_indicator.dart';
import 'categories_controller.dart';

class CategoriesView extends GetView<CategoriesController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Categorias',
        subtitle: 'Entradas e saidas personalizadas',
        leadingIcon: Icons.category_rounded,
        actions: [
          IconButton(
            onPressed: () => _showCategoryForm(context),
            icon: Icon(Icons.add_rounded, color: context.theme.colorScheme.onSurface),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryForm(context),
        backgroundColor: AppColors.royalBlue,
        foregroundColor: context.theme.colorScheme.onSurface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Categoria'),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
        ),
        child: Obx(() {
          if (controller.isLoading.value) {
            return const AppLoadingScreen(
              label: 'Carregando categorias...',
              accentColor: AppColors.royalBlue,
            );
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return _ErrorState(
              message: error,
              onRetry: controller.loadCategories,
            );
          }

          if (controller.activeCategories.isEmpty) {
            return _EmptyState(onCreate: () => _showCategoryForm(context));
          }

          return RefreshIndicator(
            color: AppColors.royalBlue,
            onRefresh: controller.loadCategories,
            child: ListView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _SummaryCard(controller: controller),
                const SizedBox(height: 20),
                _CategorySection(
                  title: 'Entradas',
                  subtitle: 'Categorias de ganhos e recebimentos',
                  categories: controller.incomeCategories,
                  emptyMessage: 'Nenhuma categoria de entrada ativa.',
                  controller: controller,
                  onTap: (category) =>
                      _showCategoryForm(context, category: category),
                ),
                const SizedBox(height: 20),
                _CategorySection(
                  title: 'Saidas',
                  subtitle: 'Categorias de custos e despesas',
                  categories: controller.expenseCategories,
                  emptyMessage: 'Nenhuma categoria de saida ativa.',
                  controller: controller,
                  onTap: (category) =>
                      _showCategoryForm(context, category: category),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  void _showCategoryForm(BuildContext context, {CategoryEntity? category}) {
    Get.bottomSheet(
      _CategoryFormSheet(category: category, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({required this.category, required this.controller});

  final CategoryEntity? category;
  final CategoriesController controller;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _nameController;
  late CategoryType _selectedType;
  late String _selectedColor;
  late String _selectedIcon;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _selectedType = widget.category?.type ?? CategoryType.expense;
    _selectedColor =
        widget.category?.color ?? widget.controller.colorOptions.first;
    _selectedIcon =
        widget.category?.icon ?? widget.controller.iconOptions.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.theme.colorScheme.onSurface.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.category == null
                        ? 'Nova categoria'
                        : 'Editar categoria',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure os detalhes para organizar seus lancamentos.',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nome da Categoria',
                    hint: 'Ex.: Supermercado, Salario...',
                    icon: Icons.label_important_rounded,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe o nome da categoria.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Tipo de Movimentacao',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _TypeChip(
                        title: 'Entrada',
                        icon: Icons.arrow_upward_rounded,
                        isSelected: _selectedType == CategoryType.income,
                        accentColor: AppColors.emerald,
                        onTap: () => setState(() {
                          _selectedType = CategoryType.income;
                        }),
                      ),
                      const SizedBox(width: 12),
                      _TypeChip(
                        title: 'Saida',
                        icon: Icons.arrow_downward_rounded,
                        isSelected: _selectedType == CategoryType.expense,
                        accentColor: AppColors.rose,
                        onTap: () => setState(() {
                          _selectedType = CategoryType.expense;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Identificacao Visual',
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cor',
                    style: TextStyle(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.controller.colorOptions.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final colorHex = widget.controller.colorOptions[index];
                        final isSelected = _selectedColor == colorHex;
                        final color = widget.controller.colorFromHex(colorHex);

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedColor = colorHex),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? context.theme.colorScheme.onSurface
                                    : Colors.transparent,
                                width: isSelected ? 3 : 0,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.4),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check_rounded,
                                    color: context.theme.colorScheme.surface,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Icone',
                    style: TextStyle(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.controller.iconOptions.map((iconCode) {
                      final isSelected = _selectedIcon == iconCode;
                      final accentColor = widget.controller.colorFromHex(
                        _selectedColor,
                      );

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = iconCode),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.15)
                                : context.theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : context.theme.colorScheme.onSurface.withValues(alpha: 0.1),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Icon(
                            widget.controller.iconForCode(iconCode),
                            color: isSelected ? context.theme.colorScheme.onSurface : context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                            size: 24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Obx(() {
                    final isLoading = widget.controller.isSubmitting.value;

                    if (widget.category == null) {
                      return CustomFilledButton(
                        text: 'SALVAR CATEGORIA',
                        icon: Icons.add_rounded,
                        isLoading: isLoading,
                        onPressed: _handleSave,
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: ScaleButton(
                            onTap: isLoading
                                ? () {}
                                : () => widget.controller.toggleCategoryStatus(
                                    widget.category!,
                                  ),
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: (widget.category!.isActive
                                        ? AppColors.rose
                                        : AppColors.emerald)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: (widget.category!.isActive
                                          ? AppColors.rose
                                          : AppColors.emerald)
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  widget.category!.isActive
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: widget.category!.isActive
                                      ? AppColors.rose
                                      : AppColors.emerald,
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: CustomFilledButton(
                            text: 'ATUALIZAR',
                            icon: Icons.check_rounded,
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
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.category == null) {
      await widget.controller.createCategory(
        name: _nameController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
      );
    } else {
      await widget.controller.updateCategory(
        id: widget.category!.id,
        name: _nameController.text.trim(),
        type: _selectedType,
        color: _selectedColor,
        icon: _selectedIcon,
      );
    }
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.18)
                : context.theme.colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? context.theme.colorScheme.onSurface
                    : context.theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  color: context.theme.colorScheme.onSurface.withValues(alpha: isSelected ? 1 : 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.controller});

  final CategoriesController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.royalBlue.withValues(alpha: 0.22),
            context.theme.colorScheme.surface.withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.category_rounded,
              color: AppColors.amber,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorias ativas',
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${controller.incomeCategories.length} entradas • ${controller.expenseCategories.length} saidas',
                  style: TextStyle(
                    color: context.theme.colorScheme.onSurface.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.categories,
    required this.emptyMessage,
    required this.controller,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final List<CategoryEntity> categories;
  final String emptyMessage;
  final CategoriesController controller;
  final ValueChanged<CategoryEntity> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: context.theme.colorScheme.onSurface.withValues(alpha: 0.66),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.theme.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: categories.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    emptyMessage,
                    style: TextStyle(
                      color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(
                    categories.length,
                    (index) => _CategoryTile(
                      category: categories[index],
                      controller: controller,
                      isLast: index == categories.length - 1,
                      onTap: () => onTap(categories[index]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.controller,
    required this.onTap,
    required this.isLast,
  });

  final CategoryEntity category;
  final CategoriesController controller;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accentColor = controller.colorFromHex(category.color);
    final isActive = category.isActive;

    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: const Radius.circular(0),
        bottom: isLast ? const Radius.circular(24) : Radius.zero,
      ),
      onTap: onTap,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accentColor.withValues(alpha: 0.95),
                          accentColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      controller.iconForCode(category.icon),
                      color: context.theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                color: context.theme.colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: context.theme.colorScheme.onSurface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'INATIVA',
                                  style: TextStyle(
                                    color: context.theme.colorScheme.onSurface.withValues(alpha: 0.54),
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.type.label,
                              style: TextStyle(
                                color: context.theme.colorScheme.onSurface.withValues(alpha: 0.64),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isActive ? Icons.edit_rounded : Icons.visibility_off_rounded,
                    color: context.theme.colorScheme.onSurface.withValues(alpha: 0.52),
                  ),
                ],
              ),
              if (!isLast) ...[
                const SizedBox(height: 16),
                Divider(color: context.theme.colorScheme.onSurface.withValues(alpha: 0.08), height: 1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.amber,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              'Nao foi possivel carregar as categorias.',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 220,
              child: CustomFilledButton(
                text: 'TENTAR NOVAMENTE',
                onPressed: () => onRetry(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: AppColors.aqua.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.category_rounded,
                color: AppColors.aqua,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma categoria ativa ainda.',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Crie categorias de entrada e saida para organizar melhor suas financas.',
              style: TextStyle(
                color: context.theme.colorScheme.onSurface.withValues(alpha: 0.72),
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 240,
              child: CustomFilledButton(
                text: 'CRIAR PRIMEIRA CATEGORIA',
                onPressed: onCreate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
