import 'dart:convert';

import 'package:get_storage/get_storage.dart';

import '../../core/errors/exceptions.dart';
import '../../domain/entities/detected_ride_draft_entity.dart';
import '../models/ride_model.dart';

abstract class IRideLocalDataSource {
  Future<RideModel> savePendingRide(DetectedRideDraftEntity ride);
  Future<List<RideModel>> getPendingRides();
  Future<RideModel?> getPendingRideById(int localId);
  Future<void> removePendingRide(int localId);
}

class RideLocalDataSourceImpl implements IRideLocalDataSource {
  RideLocalDataSourceImpl({required this.storage});

  final GetStorage storage;
  Future<void> _writeQueue = Future.value();

  static const _pendingRidesKey = 'journey_pending_rides';

  @override
  Future<RideModel> savePendingRide(DetectedRideDraftEntity ride) async {
    return _enqueueWrite(() async {
      final pendingRides = await _readPendingRideEntries();
      final createdAt = ride.detectedAt?.toLocal() ?? DateTime.now();
      final localId = _buildUniqueLocalId(
        createdAt: createdAt,
        entries: pendingRides,
      );
      final model = RideModel.fromDetectedRideDraft(
        localId: localId,
        createdAt: createdAt,
        draft: ride,
      );

      pendingRides.add(
        _PendingRideStorageEntry(model: model, createdAt: createdAt),
      );
      await _writePendingRideEntries(pendingRides);
      return model;
    }, fallbackMessage: 'Erro ao salvar corrida pendente localmente');
  }

  Future<T> _enqueueWrite<T>(
    Future<T> Function() action, {
    required String fallbackMessage,
  }) {
    final operation = _writeQueue.then((_) => action());
    _writeQueue = operation.then<void>((_) {}, onError: (_) {});

    return operation.catchError((Object e) {
      throw LocalDataSourceException('$fallbackMessage: $e');
    });
  }

  @override
  Future<List<RideModel>> getPendingRides() async {
    try {
      await _writeQueue;
      final entries = await _readPendingRideEntries();
      return entries.map((entry) => entry.model).toList();
    } catch (e) {
      throw LocalDataSourceException(
        'Erro ao carregar corridas pendentes locais: $e',
      );
    }
  }

  @override
  Future<RideModel?> getPendingRideById(int localId) async {
    await _writeQueue;
    final entries = await _readPendingRideEntries();
    for (final entry in entries) {
      if (entry.model.id == localId) {
        return entry.model;
      }
    }
    return null;
  }

  @override
  Future<void> removePendingRide(int localId) async {
    return _enqueueWrite(() async {
      final entries = await _readPendingRideEntries();
      final updated = entries
          .where((entry) => entry.model.id != localId)
          .toList();
      await _writePendingRideEntries(updated);
    }, fallbackMessage: 'Erro ao remover corrida pendente local');
  }

  Future<List<_PendingRideStorageEntry>> _readPendingRideEntries() async {
    final raw = storage.read(_pendingRidesKey);
    if (raw is! List) {
      return [];
    }

    final entries = raw.whereType<Map>().map((item) {
      final json = Map<String, dynamic>.from(item);
      final createdAt =
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now();
      return _PendingRideStorageEntry(
        model: RideModel.fromJson(json),
        createdAt: createdAt,
      );
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final serialized = _serializePendingRideEntries(entries);
    if (!_jsonEquals(raw, serialized)) {
      await storage.write(_pendingRidesKey, serialized);
    }
    return entries;
  }

  Future<void> _writePendingRideEntries(
    List<_PendingRideStorageEntry> entries,
  ) async {
    await storage.write(
      _pendingRidesKey,
      _serializePendingRideEntries(entries),
    );
  }

  List<Map<String, dynamic>> _serializePendingRideEntries(
    List<_PendingRideStorageEntry> entries,
  ) {
    return entries
        .map((entry) => entry.model.toJson(createdAt: entry.createdAt))
        .toList();
  }

  int _buildUniqueLocalId({
    required DateTime createdAt,
    required List<_PendingRideStorageEntry> entries,
  }) {
    final usedIds = entries.map((entry) => entry.model.id).toSet();
    var candidate = -createdAt.microsecondsSinceEpoch;

    while (usedIds.contains(candidate)) {
      candidate -= 1;
    }

    return candidate;
  }
}

class _PendingRideStorageEntry {
  const _PendingRideStorageEntry({
    required this.model,
    required this.createdAt,
  });

  final RideModel model;
  final DateTime createdAt;
}

bool _jsonEquals(Object? left, Object? right) {
  try {
    return jsonEncode(left) == jsonEncode(right);
  } catch (_) {
    return false;
  }
}
