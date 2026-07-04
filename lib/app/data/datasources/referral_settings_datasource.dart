import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/referral_settings_model.dart';
import '../providers/supabase/shared/supabase_table_names.dart';

typedef ReferralSettingsLoader = Future<Map<String, dynamic>?> Function();

abstract class IReferralSettingsDataSource {
  Future<ReferralSettingsModel> getSettings();
}

class SupabaseReferralSettingsDataSource
    implements IReferralSettingsDataSource {
  const SupabaseReferralSettingsDataSource({
    this.client,
    this.companySettingsLoader,
  });

  final SupabaseClient? client;
  final ReferralSettingsLoader? companySettingsLoader;

  @override
  Future<ReferralSettingsModel> getSettings() async {
    final loader = companySettingsLoader;
    if (loader != null) {
      return ReferralSettingsModel.fromCompanyRow(await loader());
    }

    final supabase = client;
    if (supabase == null) {
      return const ReferralSettingsModel();
    }

    final rpcSettings = await _loadSettingsFromRpc(supabase);
    if (rpcSettings != null) {
      return ReferralSettingsModel.fromCompanyRow({
        'referralSettings': rpcSettings,
      });
    }

    final row = await supabase
        .from(SupabaseTableNames.company)
        .select('referralSettings, updatedAt')
        .eq('id', 1)
        .maybeSingle();

    return ReferralSettingsModel.fromCompanyRow(
      row == null ? null : Map<String, dynamic>.from(row),
    );
  }

  Future<Map<String, dynamic>?> _loadSettingsFromRpc(
    SupabaseClient supabase,
  ) async {
    try {
      final result = await supabase.rpc('get_referral_settings');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
