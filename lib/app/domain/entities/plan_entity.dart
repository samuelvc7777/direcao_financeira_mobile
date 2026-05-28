class PlanEntity {
  final int id;
  final String code;
  final String name;
  final String description;
  final int priceCents;
  final int durationDays;
  final String color;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PlanEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.priceCents,
    required this.durationDays,
    required this.color,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });
}
