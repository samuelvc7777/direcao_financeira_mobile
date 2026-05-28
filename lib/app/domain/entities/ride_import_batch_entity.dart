const String kRideImportDescriptionPrefix = '[sistema] importacao_corridas:';

class RideImportBatchEntity {
  final String batchId;
  final List<int> rideIds;

  const RideImportBatchEntity({
    required this.batchId,
    required this.rideIds,
  });

  String encode() {
    final sortedRideIds = List<int>.from(rideIds)..sort();
    return 'batch=$batchId rides=${sortedRideIds.join(',')}';
  }

  static RideImportBatchEntity? tryParse(String description) {
    final prefix = kRideImportDescriptionPrefix;
    final normalized = description.trim();
    if (!normalized.toLowerCase().startsWith(prefix)) {
      return null;
    }

    final afterPrefix = normalized.substring(prefix.length).trim();
    final batchMatch = RegExp(r'batch=([^\s]+)').firstMatch(afterPrefix);
    final ridesMatch = RegExp(r'rides=([0-9,]+)').firstMatch(afterPrefix);

    if (batchMatch == null || ridesMatch == null) {
      return null;
    }

    final batchId = batchMatch.group(1)!.trim();
    final rideIds =
        ridesMatch.group(1)!
            .split(',')
            .map((value) => int.tryParse(value.trim()))
            .whereType<int>()
            .toList();

    if (batchId.isEmpty || rideIds.isEmpty) {
      return null;
    }

    return RideImportBatchEntity(batchId: batchId, rideIds: rideIds);
  }
}
