class ManualShiftDraftEntity {
  const ManualShiftDraftEntity({
    required this.totalDrivenKm,
    required this.startTime,
    required this.endTime,
  });

  final double totalDrivenKm;
  final DateTime startTime;
  final DateTime endTime;
}
