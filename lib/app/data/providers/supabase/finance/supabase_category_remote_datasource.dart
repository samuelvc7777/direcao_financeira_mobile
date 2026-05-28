import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/entities/category_entity.dart';
import '../../../datasources/category_datasource.dart';
import '../../../mappers/category_type_codec.dart';
import '../../../models/category_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseCategoryRemoteDataSource implements ICategoryDataSource {
  SupabaseCategoryRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final userId = await userScope.getCurrentUserId();
    final rows = await client
        .from(SupabaseTableNames.categories)
        .select()
        .eq('userId', userId)
        .order('createdAt');

    return (rows as List)
        .map(
          (row) =>
              CategoryModel.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  @override
  Future<CategoryModel> createCategory({
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await client
        .from(SupabaseTableNames.categories)
        .insert({
          'userId': userId,
          'name': name,
          'type': CategoryTypeCodec.encode(type),
          'color': color,
          'icon': icon,
          'isActive': true,
          'updatedAt': now,
        })
        .select()
        .single();

    return CategoryModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<CategoryModel> updateCategory({
    required int id,
    required String name,
    required CategoryType type,
    required String color,
    required String icon,
  }) async {
    final updated = await client
        .from(SupabaseTableNames.categories)
        .update({
          'name': name,
          'type': CategoryTypeCodec.encode(type),
          'color': color,
          'icon': icon,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return CategoryModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> deactivateCategory(int id) async {
    await client
        .from(SupabaseTableNames.categories)
        .update({
          'isActive': false,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> reactivateCategory(int id) async {
    await client
        .from(SupabaseTableNames.categories)
        .update({
          'isActive': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }
}
