import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_environment.dart';
import '../../domain/entities/help_support_contact_entity.dart';
import '../models/help_video_model.dart';
import '../providers/supabase/shared/supabase_table_names.dart';

abstract class IHelpVideoDataSource {
  Future<List<HelpVideoModel>> getVideos();
  Future<HelpSupportContactEntity> getSupportContact();
}

class HelpVideoDataSource implements IHelpVideoDataSource {
  HelpVideoDataSource({required this.environment, this.supabaseClient});

  final AppEnvironment environment;
  final SupabaseClient? supabaseClient;

  @override
  Future<List<HelpVideoModel>> getVideos() async {
    final remoteVideos = await _loadVideosFromSupabase();
    if (remoteVideos.isNotEmpty) {
      return remoteVideos;
    }

    final raw = environment.helpVideoCatalogJson.trim();
    if (raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Catalogo de videos de ajuda invalido.');
    }

    final videos =
        decoded
            .whereType<Map>()
            .map(
              (item) => HelpVideoModel.fromMap(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return videos;
  }

  Future<List<HelpVideoModel>> _loadVideosFromSupabase() async {
    final client = supabaseClient;
    if (client == null) {
      return const [];
    }

    try {
      final rows = await client
          .from(SupabaseTableNames.videos)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true)
          .order('id', ascending: true);

      return (rows as List)
          .map((row) => HelpVideoModel.fromMap(Map<String, dynamic>.from(row)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<HelpSupportContactEntity> getSupportContact() async {
    final companyPhone =
        await _loadCompanyPhoneFromSupabaseRpc() ??
        await _loadCompanyPhoneFromSupabaseUserTable();
    return HelpSupportContactEntity(
      whatsappPhone: companyPhone ?? environment.helpWhatsappPhone,
      whatsappUrl: environment.helpWhatsappUrl,
      initialMessage: environment.helpWhatsappInitialMessage,
    );
  }

  Future<String?> _loadCompanyPhoneFromSupabaseRpc() async {
    final client = supabaseClient;
    if (client == null) {
      return null;
    }

    try {
      final response = await client.rpc('get_company_support_phone');
      return _readPhone(response);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadCompanyPhoneFromSupabaseUserTable() async {
    final client = supabaseClient;
    if (client == null) {
      return null;
    }

    try {
      final rows = await client
          .from(SupabaseTableNames.users)
          .select('companyPhone, role, updatedAt')
          .order('updatedAt', ascending: false)
          .limit(50);

      for (final row in rows) {
        final map = Map<String, dynamic>.from(row as Map);
        final phone = _readPhone(map['companyPhone']);
        if (phone != null && phone.isNotEmpty) {
          return phone;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String? _readPhone(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is List) {
      for (final item in value) {
        final phone = _readPhone(item);
        if (phone != null) {
          return phone;
        }
      }
      return null;
    }

    if (value is Map) {
      return _readPhone(value['companyPhone'] ?? value['phone']);
    }

    final phone = value.toString().trim();
    return phone.isEmpty ? null : phone;
  }
}
