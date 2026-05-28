import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/google_api_config_entity.dart';
import '../providers/supabase/shared/supabase_table_names.dart';

typedef CompanySettingsLoader = Future<Map<String, dynamic>?> Function();

abstract class IGoogleApiConfigDataSource {
  Future<GoogleApiConfigEntity?> getConfig();
}

class SupabaseGoogleApiConfigDataSource implements IGoogleApiConfigDataSource {
  const SupabaseGoogleApiConfigDataSource({
    this.client,
    this.companySettingsLoader,
  });

  final SupabaseClient? client;
  final CompanySettingsLoader? companySettingsLoader;

  @override
  Future<GoogleApiConfigEntity?> getConfig() async {
    try {
      final row = await _loadCompanySettings();
      if (row == null) {
        return null;
      }

      return GoogleApiConfigEntity(
        googleApiKey: row['googleApiKey']?.toString(),
        updatedAt: DateTime.tryParse(row['updatedAt']?.toString() ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _loadCompanySettings() async {
    final loader = companySettingsLoader;
    if (loader != null) {
      return loader();
    }

    final supabase = client;
    if (supabase == null) {
      return null;
    }

    final row = await supabase
        .from(SupabaseTableNames.company)
        .select('googleApiKey, updatedAt')
        .eq('id', 1)
        .maybeSingle();

    if (row == null) {
      return null;
    }

    return Map<String, dynamic>.from(row);
  }
}
