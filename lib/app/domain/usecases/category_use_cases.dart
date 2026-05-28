import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/i_category_repository.dart';

class DefaultCategorySeed {
  const DefaultCategorySeed({
    required this.name,
    required this.type,
    required this.color,
    required this.icon,
  });

  final String name;
  final CategoryType type;
  final String color;
  final String icon;
}

class LoadCategoriesUseCase {
  LoadCategoriesUseCase(this._repository);

  final ICategoryRepository _repository;

  Future<Either<Failure, List<CategoryEntity>>> call() {
    return _repository.getCategories();
  }
}

class EnsureDefaultCategoriesUseCase {
  EnsureDefaultCategoriesUseCase(this._repository);

  final ICategoryRepository _repository;

  static const defaultCategories = <DefaultCategorySeed>[
    DefaultCategorySeed(
      name: 'Uber',
      type: CategoryType.income,
      color: '#111827',
      icon: 'car',
    ),
    DefaultCategorySeed(
      name: '99',
      type: CategoryType.income,
      color: '#facc15',
      icon: 'car',
    ),
    DefaultCategorySeed(
      name: 'MoveSJ',
      type: CategoryType.income,
      color: '#3b82f6',
      icon: 'car',
    ),
    DefaultCategorySeed(
      name: 'inDrive',
      type: CategoryType.income,
      color: '#22c55e',
      icon: 'car',
    ),
    DefaultCategorySeed(
      name: 'iFood',
      type: CategoryType.income,
      color: '#ef4444',
      icon: 'restaurant',
    ),
    DefaultCategorySeed(
      name: 'Rappi',
      type: CategoryType.income,
      color: '#f97316',
      icon: 'shopping-cart',
    ),
    DefaultCategorySeed(
      name: 'Combustivel',
      type: CategoryType.expense,
      color: '#ef4444',
      icon: 'fuel',
    ),
    DefaultCategorySeed(
      name: 'Manutencao',
      type: CategoryType.expense,
      color: '#f97316',
      icon: 'wrench',
    ),
    DefaultCategorySeed(
      name: 'Lavagem',
      type: CategoryType.expense,
      color: '#3b82f6',
      icon: 'car',
    ),
    DefaultCategorySeed(
      name: 'Alimentacao',
      type: CategoryType.expense,
      color: '#eab308',
      icon: 'restaurant',
    ),
    DefaultCategorySeed(
      name: 'Internet e telefone',
      type: CategoryType.expense,
      color: '#6366f1',
      icon: 'tag',
    ),
    DefaultCategorySeed(
      name: 'Seguro',
      type: CategoryType.expense,
      color: '#038C8C',
      icon: 'heart',
    ),
    DefaultCategorySeed(
      name: 'Financiamento ou aluguel',
      type: CategoryType.expense,
      color: '#8b5cf6',
      icon: 'credit-card',
    ),
    DefaultCategorySeed(
      name: 'Pedagios e estacionamento',
      type: CategoryType.expense,
      color: '#64748b',
      icon: 'wallet',
    ),
  ];

  Future<Either<Failure, List<CategoryEntity>>> call() async {
    final existingResult = await _repository.getCategories();

    return existingResult.fold(Left.new, (existingCategories) async {
      final existingKeys = existingCategories
          .map((category) => _key(category.name, category.type))
          .toSet();
      final createdCategories = <CategoryEntity>[];

      for (final seed in defaultCategories) {
        if (existingKeys.contains(_key(seed.name, seed.type))) {
          continue;
        }

        final createdResult = await _repository.createCategory(
          name: seed.name,
          type: seed.type,
          color: seed.color,
          icon: seed.icon,
        );

        final failure = createdResult.fold<Failure?>((failure) => failure, (
          category,
        ) {
          createdCategories.add(category);
          existingKeys.add(_key(seed.name, seed.type));
          return null;
        });

        if (failure != null) {
          return Left(failure);
        }
      }

      return Right(createdCategories);
    });
  }

  String _key(String name, CategoryType type) =>
      '${type.name}:${name.trim().toLowerCase()}';
}

class CreateCategoryUseCase {
  CreateCategoryUseCase(this._repository);

  final ICategoryRepository _repository;

  Future<Either<Failure, CategoryEntity>> call({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) {
    return _repository.createCategory(
      name: name,
      type: type,
      color: color,
      icon: icon,
    );
  }
}

class UpdateCategoryUseCase {
  UpdateCategoryUseCase(this._repository);

  final ICategoryRepository _repository;

  Future<Either<Failure, CategoryEntity>> call({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) {
    return _repository.updateCategory(
      id: id,
      name: name,
      type: type,
      color: color,
      icon: icon,
    );
  }
}

class DeactivateCategoryUseCase {
  DeactivateCategoryUseCase(this._repository);

  final ICategoryRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.deactivateCategory(id);
  }
}

class ReactivateCategoryUseCase {
  ReactivateCategoryUseCase(this._repository);

  final ICategoryRepository _repository;

  Future<Either<Failure, void>> call(int id) {
    return _repository.reactivateCategory(id);
  }
}
