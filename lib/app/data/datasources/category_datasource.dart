import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

abstract class ICategoryDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  });
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  });
  Future<void> deactivateCategory(int id);
  Future<void> reactivateCategory(int id);
}
