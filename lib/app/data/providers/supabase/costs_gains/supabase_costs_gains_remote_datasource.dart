import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../datasources/costs_gains_settings_datasource.dart';
import '../../../models/costs_gains_settings_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseCostsGainsRemoteDataSource
    implements ICostsGainsSettingsDataSource {
  SupabaseCostsGainsRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client);

  final SupabaseClient client;
  final SupabaseUserScope userScope;

  @override
  Future<CostsGainsSettingsModel?> getCurrentUserSettings() async {
    final userId = await userScope.getCurrentUserId();
    final row = await client
        .from(SupabaseTableNames.costsGainsSettings)
        .select()
        .eq('userId', userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return CostsGainsSettingsModel.fromMap(Map<String, dynamic>.from(row));
  }

  @override
  Future<bool> hasCurrentUserSettings() async {
    final userId = await userScope.getCurrentUserId();
    final row = await client
        .from(SupabaseTableNames.costsGainsSettings)
        .select('id')
        .eq('userId', userId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<CostsGainsSettingsModel> saveCurrentUserSettings(
    CostsGainsSettingsModel model,
  ) async {
    final userId = await userScope.getCurrentUserId();
    final payload = Map<String, dynamic>.from(model.toMap())
      ..remove('id')
      ..remove('createdAt')
      ..['userId'] = userId
      ..['updatedAt'] = DateTime.now().toUtc().toIso8601String();

    final saved = await client
        .from(SupabaseTableNames.costsGainsSettings)
        .upsert(payload, onConflict: 'userId')
        .select()
        .single();

    return CostsGainsSettingsModel.fromMap(Map<String, dynamic>.from(saved));
  }
}
