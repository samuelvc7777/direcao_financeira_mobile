enum GoalStatus {
  active,
  completed,
  archived;

  String get label {
    switch (this) {
      case GoalStatus.active:
        return 'Ativa';
      case GoalStatus.completed:
        return 'Concluida';
      case GoalStatus.archived:
        return 'Arquivada';
    }
  }
}

class GoalEntity {
  const GoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.targetAmountCents,
    required this.currentAmountCents,
    required this.status,
    this.description,
    this.targetDate,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String name;
  final String? description;
  final int targetAmountCents;
  final int currentAmountCents;
  final GoalStatus status;
  final DateTime? targetDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get targetAmount => targetAmountCents / 100.0;
  double get currentAmount => currentAmountCents / 100.0;

  double get progressRatio {
    if (targetAmountCents <= 0) {
      return 0;
    }

    return currentAmountCents / targetAmountCents;
  }

  double get cappedProgressRatio {
    final value = progressRatio;
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  double get progressPercent => progressRatio * 100;
  double get cappedProgressPercent => cappedProgressRatio * 100;
  bool get isReached => currentAmountCents >= targetAmountCents;
  bool get isActive => status == GoalStatus.active;
  bool get isCompleted => status == GoalStatus.completed;
  bool get isArchived => status == GoalStatus.archived;
}
