import '../../domain/entities/category_entity.dart';

class CategoryTypeCodec {
  const CategoryTypeCodec._();

  static String encode(CategoryType value) {
    switch (value) {
      case CategoryType.income:
        return 'INCOME';
      case CategoryType.expense:
        return 'EXPENSE';
    }
  }

  static CategoryType decode(String value) {
    switch (value.toUpperCase()) {
      case 'INCOME':
        return CategoryType.income;
      case 'EXPENSE':
        return CategoryType.expense;
      default:
        throw ArgumentError('Tipo de categoria invalido: $value');
    }
  }
}
