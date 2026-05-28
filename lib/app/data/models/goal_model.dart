import '../../domain/entities/goal_entity.dart';

class GoalModel extends GoalEntity {
  const GoalModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.targetAmountCents,
    required super.currentAmountCents,
    required super.status,
    super.description,
    super.targetDate,
    super.completedAt,
    super.createdAt,
    super.updatedAt,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: _asInt(json['id']),
      userId: _asInt(json['userId']),
      name: json['name']?.toString() ?? '',
      description: _nullableTrimmed(json['description']),
      targetAmountCents: _asInt(json['targetAmountCents']),
      currentAmountCents: _asInt(json['currentAmountCents']),
      status: GoalStatusCodec.decode(json['status']?.toString()),
      targetDate: _parseDate(json['targetDate']),
      completedAt: _parseDate(json['completedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'targetAmountCents': targetAmountCents,
      'currentAmountCents': currentAmountCents,
      'status': GoalStatusCodec.encode(status),
      'targetDate': targetDate?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
      'createdAt': createdAt?.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _parseDate(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw);
  }

  static String? _nullableTrimmed(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return raw;
  }
}

class GoalStatusCodec {
  const GoalStatusCodec._();

  static GoalStatus decode(String? value) {
    switch (value?.toUpperCase()) {
      case 'COMPLETED':
        return GoalStatus.completed;
      case 'ARCHIVED':
        return GoalStatus.archived;
      case 'ACTIVE':
      default:
        return GoalStatus.active;
    }
  }

  static String encode(GoalStatus status) {
    switch (status) {
      case GoalStatus.active:
        return 'ACTIVE';
      case GoalStatus.completed:
        return 'COMPLETED';
      case GoalStatus.archived:
        return 'ARCHIVED';
    }
  }
}
