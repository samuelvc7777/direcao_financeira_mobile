import '../../domain/entities/plan_entity.dart';

class PlanModel extends PlanEntity {
  PlanModel({
    required super.id,
    required super.code,
    required super.name,
    required super.description,
    required super.priceCents,
    required super.durationDays,
    required super.color,
    required super.isActive,
    super.createdAt,
    super.updatedAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id'],
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      priceCents: json['priceCents'] ?? 0,
      durationDays: json['durationDays'] ?? 0,
      color: json['color'] ?? '#038C8C',
      isActive: json['isActive'] ?? true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'priceCents': priceCents,
      'durationDays': durationDays,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
