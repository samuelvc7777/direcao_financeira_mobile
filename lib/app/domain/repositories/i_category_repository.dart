import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/category_entity.dart';

abstract class ICategoryRepository {
  Future<Either<Failure, List<CategoryEntity>>> getCategories();
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  });
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  });
  Future<Either<Failure, void>> deactivateCategory(int id);
  Future<Either<Failure, void>> reactivateCategory(int id);
}
