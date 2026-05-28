import 'dart:convert';

import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';

import '../models/active_shift_model.dart';
import '../models/pending_finished_shift_model.dart';

abstract class IJourneyLocalDataSource {
  Future<ActiveShiftModel?> getActiveShift();
  Future<void> saveActiveShift(ActiveShiftModel shift);
  Future<ActiveShiftModel> startShift();
  Future<ActiveShiftModel> pauseShift();
  Future<ActiveShiftModel> resumeShift();
  Future<PendingFinishedShiftModel> finishShift({
    required double totalDrivenKm,
  });
  Future<PendingFinishedShiftModel> addManualFinishedShift({
    required double totalDrivenKm,
    required DateTime startTime,
    required DateTime endTime,
  });
  Future<List<PendingFinishedShiftModel>> getPendingFinishedShifts();
  Future<void> removePendingFinishedShift(int localId);
  Future<void> clearActiveShift();
}

class JourneyLocalDataSourceImpl implements IJourneyLocalDataSource {
  JourneyLocalDataSourceImpl({required this.storage});

  final GetStorage storage;
  static const _activeShiftKey = 'journey_local_active_shift';
  static const _pendingShiftsKey = 'journey_pending_finished_shifts';
  static const _maxDatabaseInt = 2147483647;

  @override
  Future<ActiveShiftModel?> getActiveShift() async {
    final raw = storage.read(_activeShiftKey);
    if (raw is! Map) {
      return null;
    }

    final json = Map<String, dynamic>.from(raw);
    final remoteShiftId = json['remoteShiftId'];

    if (remoteShiftId is int && remoteShiftId > _maxDatabaseInt) {
      json['remoteShiftId'] = null;
    }

    return ActiveShiftModel.fromJson(json);
  }

  @override
  Future<void> saveActiveShift(ActiveShiftModel shift) async {
    await storage.write(_activeShiftKey, shift.toJson());
  }

  @override
  Future<ActiveShiftModel> startShift() async {
    final existingShift = await getActiveShift();
    if (existingShift != null) {
      throw StateError('Ja existe um turno ativo.');
    }

    final now = DateTime.now();
    final localId = now.millisecondsSinceEpoch;
    final shift = ActiveShiftModel(
      id: localId,
      remoteShiftId: null,
      startTime: now,
      createdAt: now,
      currentDrivenKm: 0,
      idleTimeSeconds: 0,
      pausedAt: null,
      lowSpeedSince: null,
      lastMotionIdleCheckpointAt: null,
    );

    await saveActiveShift(shift);
    return shift;
  }

  @override
  Future<ActiveShiftModel> pauseShift() async {
    final shift = await getActiveShift();
    if (shift == null) {
      throw StateError('Nao ha turno ativo para pausar.');
    }
    if (shift.isPaused) {
      throw StateError('O turno ja esta pausado.');
    }

    final updatedShift = ActiveShiftModel(
      id: shift.id,
      remoteShiftId: shift.remoteShiftId,
      startTime: shift.startTime,
      createdAt: shift.createdAt,
      currentDrivenKm: shift.currentDrivenKm,
      idleTimeSeconds: shift.idleTimeSeconds,
      pausedAt: DateTime.now(),
      lowSpeedSince: null,
      lastMotionIdleCheckpointAt: null,
    );

    await saveActiveShift(updatedShift);
    return updatedShift;
  }

  @override
  Future<ActiveShiftModel> resumeShift() async {
    final shift = await getActiveShift();
    if (shift == null) {
      throw StateError('Nao ha turno ativo para retomar.');
    }
    if (!shift.isPaused || shift.pausedAt == null) {
      throw StateError('O turno nao esta pausado.');
    }

    final now = DateTime.now();
    final pausedSeconds = now.difference(shift.pausedAt!).inSeconds;
    final updatedShift = ActiveShiftModel(
      id: shift.id,
      remoteShiftId: shift.remoteShiftId,
      startTime: shift.startTime,
      createdAt: shift.createdAt,
      currentDrivenKm: shift.currentDrivenKm,
      idleTimeSeconds: shift.idleTimeSeconds + pausedSeconds,
      pausedAt: null,
      lowSpeedSince: null,
      lastMotionIdleCheckpointAt: null,
    );

    await saveActiveShift(updatedShift);
    return updatedShift;
  }

  @override
  Future<PendingFinishedShiftModel> finishShift({
    required double totalDrivenKm,
  }) async {
    final shift = await getActiveShift();
    if (shift == null) {
      throw StateError('Nao ha turno ativo para finalizar.');
    }

    final endTime = DateTime.now();
    final pausedSeconds = shift.pausedAt != null
        ? endTime.difference(shift.pausedAt!).inSeconds
        : 0;
    final pendingShift = PendingFinishedShiftModel(
      localId: shift.id,
      remoteShiftId: shift.remoteShiftId,
      startTime: shift.startTime,
      endTime: endTime,
      createdAt: shift.createdAt,
      idleTimeSeconds: shift.idleTimeSeconds + pausedSeconds,
      totalDrivenKm: totalDrivenKm,
    );

    final pendingShifts = await getPendingFinishedShifts();
    pendingShifts.add(pendingShift);
    await storage.write(
      _pendingShiftsKey,
      pendingShifts.map((item) => item.toJson()).toList(),
    );
    await clearActiveShift();
    return pendingShift;
  }

  @override
  Future<PendingFinishedShiftModel> addManualFinishedShift({
    required double totalDrivenKm,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _debugLog(
      '[JourneyLocalDataSource] addManualFinishedShift inicio: '
      'km=$totalDrivenKm start=$startTime end=$endTime.',
    );
    if (totalDrivenKm <= 0) {
      _debugLog('[JourneyLocalDataSource] Falha: totalDrivenKm <= 0.');
      throw ArgumentError.value(
        totalDrivenKm,
        'totalDrivenKm',
        'A quilometragem precisa ser maior que zero.',
      );
    }
    if (!endTime.isAfter(startTime)) {
      _debugLog('[JourneyLocalDataSource] Falha: endTime <= startTime.');
      throw ArgumentError.value(
        endTime,
        'endTime',
        'O horario final precisa ser depois do horario inicial.',
      );
    }

    final pendingShift = PendingFinishedShiftModel(
      localId: DateTime.now().microsecondsSinceEpoch,
      remoteShiftId: null,
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
      idleTimeSeconds: 0,
      totalDrivenKm: totalDrivenKm,
    );

    final pendingShifts = await getPendingFinishedShifts();
    _debugLog(
      '[JourneyLocalDataSource] Pendencias antes de salvar: ${pendingShifts.length}.',
    );
    pendingShifts.add(pendingShift);
    await storage.write(
      _pendingShiftsKey,
      pendingShifts.map((item) => item.toJson()).toList(),
    );
    final savedCount = (storage.read(_pendingShiftsKey) as List?)?.length ?? 0;
    _debugLog(
      '[JourneyLocalDataSource] Turno manual salvo: '
      'localId=${pendingShift.localId} pendenciasDepois=$savedCount.',
    );
    return pendingShift;
  }

  @override
  Future<List<PendingFinishedShiftModel>> getPendingFinishedShifts() async {
    final raw = storage.read(_pendingShiftsKey);
    if (raw is! List) {
      return [];
    }

    final pendingShifts =
        raw
            .whereType<Map>()
            .map(
              (item) => PendingFinishedShiftModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
          ..sort((a, b) => b.endTime.compareTo(a.endTime));

    final serialized = pendingShifts.map((item) => item.toJson()).toList();
    if (!_jsonEquals(raw, serialized)) {
      await storage.write(_pendingShiftsKey, serialized);
    }

    return pendingShifts;
  }

  @override
  Future<void> removePendingFinishedShift(int localId) async {
    final pendingShifts = await getPendingFinishedShifts();
    final updatedShifts = pendingShifts
        .where((item) => item.localId != localId)
        .toList();
    await storage.write(
      _pendingShiftsKey,
      updatedShifts.map((item) => item.toJson()).toList(),
    );
  }

  @override
  Future<void> clearActiveShift() async {
    await storage.remove(_activeShiftKey);
  }
}

void _debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

bool _jsonEquals(Object? left, Object? right) {
  try {
    return jsonEncode(left) == jsonEncode(right);
  } catch (_) {
    return false;
  }
}
