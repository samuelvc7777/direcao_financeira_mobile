enum CategoryType {
  income,
  expense;

  String get label {
    switch (this) {
      case CategoryType.income:
        return 'Entrada';
      case CategoryType.expense:
        return 'Saida';
    }
  }
}

class CategoryEntity {
  final int id;
  final int userId;
  final String name;
  final CategoryType type;
  final String color;
  final String icon;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
