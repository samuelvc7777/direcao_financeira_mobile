import 'package:dio/dio.dart';

import '../../../../domain/entities/category_entity.dart';
import '../../../datasources/category_datasource.dart';
import '../../../mappers/category_type_codec.dart';
import '../../../models/category_model.dart';

class NestCategoryRemoteDataSource implements ICategoryDataSource {
  NestCategoryRemoteDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await dio.get('/finance/categories');
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
        ? (data['data'] ?? data['categories'] ?? [])
        : [];

    if (items is! List) {
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final response = await dio.post(
      '/finance/categories',
      data: {
        'name': name,
        'type': CategoryTypeCodec.encode(type),
        'color': color,
        'icon': icon,
      },
    );

    return _parseCategory(response.data);
  }

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final response = await dio.patch(
      '/finance/categories/$id',
      data: {
        'name': name,
        'type': CategoryTypeCodec.encode(type),
        'color': color,
        'icon': icon,
      },
    );

    return _parseCategory(response.data);
  }

  @override
  Future<void> deactivateCategory(int id) {
    return dio.delete('/finance/categories/$id');
  }

  @override
  Future<void> reactivateCategory(int id) {
    return dio.patch('/finance/categories/$id', data: {'isActive': true});
  }

  CategoryModel _parseCategory(dynamic data) {
    if (data is Map) {
      if (data['category'] is Map) {
        return CategoryModel.fromJson(
          Map<String, dynamic>.from(data['category'] as Map),
        );
      }
      if (data['data'] is Map) {
        return CategoryModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }

      return CategoryModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Resposta invalida da API de categorias.');
  }
}
