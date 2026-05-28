import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/location/location_math.dart';
import '../models/shift_route_model.dart';
import '../models/tracked_route_point_model.dart';
import '../shared/journey_datetime_parser.dart';

abstract class IJourneyRouteLocalDataSource {
  Future<void> ensureRoute({
    required int localShiftId,
    required DateTime startedAt,
  });
  Future<ShiftRouteModel?> appendPoint({
    required int localShiftId,
    required TrackedRoutePointModel point,
    bool forceRecord = false,
  });
  Future<void> markRouteFinished({
    required int localShiftId,
    required DateTime endedAt,
  });
  Future<void> assignRemoteShiftId({
    required int localShiftId,
    required int remoteShiftId,
  });
  Future<ShiftRouteModel?> getRouteByLocalShiftId(
    int localShiftId, {
    bool includePoints = true,
  });
  Future<ShiftRouteModel?> getRouteByRemoteShiftId(
    int remoteShiftId, {
    bool includePoints = true,
  });
  Future<void> deleteRoute(int localShiftId);
}

class JourneyRouteLocalDataSourceImpl implements IJourneyRouteLocalDataSource {
  static const _databaseName = 'journey_routes.db';
  static const _routesTable = 'shift_routes';
  static const _pointsTable = 'shift_route_points';
  static const _minimumSavedPointDistanceMeters = 200.0;
  static const _minimumSavedPointInterval = Duration(seconds: 30);
  static Database? _database;
  final _lastSavedPointByShift = <int, TrackedRoutePointModel>{};

  Future<Database> get _db async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_routesTable (
            local_shift_id INTEGER PRIMARY KEY,
            remote_shift_id INTEGER,
            started_at TEXT NOT NULL,
            ended_at TEXT NOT NULL,
            total_distance_meters REAL NOT NULL DEFAULT 0,
            point_count INTEGER NOT NULL DEFAULT 0,
            is_finished INTEGER NOT NULL DEFAULT 0,
            last_latitude REAL,
            last_longitude REAL,
            last_recorded_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE $_pointsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            local_shift_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy_meters REAL NOT NULL,
            recorded_at TEXT NOT NULL
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_shift_route_points_shift_time ON $_pointsTable(local_shift_id, recorded_at)',
        );
        await db.execute(
          'CREATE INDEX idx_shift_routes_remote_shift ON $_routesTable(remote_shift_id)',
        );
      },
    );

    return _database!;
  }

  @override
  Future<void> ensureRoute({
    required int localShiftId,
    required DateTime startedAt,
  }) async {
    final db = await _db;
    final existing = await db.query(
      _routesTable,
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    final startedAtUtc = startedAt.toUtc().toIso8601String();
    await db.insert(_routesTable, {
      'local_shift_id': localShiftId,
      'started_at': startedAtUtc,
      'ended_at': startedAtUtc,
      'total_distance_meters': 0.0,
      'point_count': 0,
      'is_finished': 0,
    });
  }

  @override
  Future<ShiftRouteModel?> appendPoint({
    required int localShiftId,
    required TrackedRoutePointModel point,
    bool forceRecord = false,
  }) async {
    if (point.accuracyMeters > 50) {
      return getRouteByLocalShiftId(localShiftId, includePoints: false);
    }

    final db = await _db;
    await ensureRoute(localShiftId: localShiftId, startedAt: point.recordedAt);

    final routeRow = await _getRouteRowByColumn(
      column: 'local_shift_id',
      value: localShiftId,
    );
    if (routeRow == null) {
      return null;
    }

    final lastLatitude = (routeRow['last_latitude'] as num?)?.toDouble();
    final lastLongitude = (routeRow['last_longitude'] as num?)?.toDouble();
    final lastRecordedAtRaw = routeRow['last_recorded_at'] as String?;

    if (lastLatitude != null &&
        lastLongitude != null &&
        lastRecordedAtRaw != null) {
      final lastRecordedAt = parseJourneyDateTimeToLocal(lastRecordedAtRaw);
      final incrementalDistance = LocationMath.distanceInMeters(
        startLatitude: lastLatitude,
        startLongitude: lastLongitude,
        endLatitude: point.latitude,
        endLongitude: point.longitude,
      );

      final isSameCoordinate =
          lastLatitude == point.latitude && lastLongitude == point.longitude;
      final isDuplicatedTimestamp =
          lastRecordedAt.toUtc() == point.recordedAt.toUtc();

      if (isSameCoordinate || isDuplicatedTimestamp) {
        return getRouteByLocalShiftId(localShiftId, includePoints: false);
      }

      final shouldPersistPoint =
          forceRecord ||
          await _shouldPersistPoint(
            db: db,
            localShiftId: localShiftId,
            candidatePoint: point,
          );

      if (shouldPersistPoint) {
        await db.insert(_pointsTable, point.toDb(localShiftId));
        _lastSavedPointByShift[localShiftId] = point;
      }

      await db.update(
        _routesTable,
        {
          'total_distance_meters':
              ((routeRow['total_distance_meters'] as num?)?.toDouble() ?? 0) +
              incrementalDistance,
          'point_count':
              (routeRow['point_count'] as int? ?? 0) +
              (shouldPersistPoint ? 1 : 0),
          'last_latitude': point.latitude,
          'last_longitude': point.longitude,
          'last_recorded_at': point.recordedAt.toUtc().toIso8601String(),
          'ended_at': point.recordedAt.toUtc().toIso8601String(),
        },
        where: 'local_shift_id = ?',
        whereArgs: [localShiftId],
      );

      return getRouteByLocalShiftId(localShiftId, includePoints: false);
    }

    await db.insert(_pointsTable, point.toDb(localShiftId));
    _lastSavedPointByShift[localShiftId] = point;
    await db.update(
      _routesTable,
      {
        'point_count': 1,
        'last_latitude': point.latitude,
        'last_longitude': point.longitude,
        'last_recorded_at': point.recordedAt.toUtc().toIso8601String(),
        'ended_at': point.recordedAt.toUtc().toIso8601String(),
      },
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
    );

    return getRouteByLocalShiftId(localShiftId, includePoints: false);
  }

  Future<bool> _shouldPersistPoint({
    required Database db,
    required int localShiftId,
    required TrackedRoutePointModel candidatePoint,
  }) async {
    final cachedPoint = _lastSavedPointByShift[localShiftId];
    if (cachedPoint != null) {
      return _shouldPersistPointAfter(
        lastSavedPoint: cachedPoint,
        candidatePoint: candidatePoint,
      );
    }

    final rows = await db.query(
      _pointsTable,
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    if (rows.isEmpty) {
      return true;
    }

    final lastSavedPoint = TrackedRoutePointModel.fromDb(rows.first);
    _lastSavedPointByShift[localShiftId] = lastSavedPoint;
    return _shouldPersistPointAfter(
      lastSavedPoint: lastSavedPoint,
      candidatePoint: candidatePoint,
    );
  }

  bool _shouldPersistPointAfter({
    required TrackedRoutePointModel lastSavedPoint,
    required TrackedRoutePointModel candidatePoint,
  }) {
    final distanceFromLastSavedPoint = LocationMath.distanceInMeters(
      startLatitude: lastSavedPoint.latitude,
      startLongitude: lastSavedPoint.longitude,
      endLatitude: candidatePoint.latitude,
      endLongitude: candidatePoint.longitude,
    );
    final timeSinceLastSavedPoint = candidatePoint.recordedAt.difference(
      lastSavedPoint.recordedAt,
    );

    return distanceFromLastSavedPoint >= _minimumSavedPointDistanceMeters ||
        timeSinceLastSavedPoint >= _minimumSavedPointInterval;
  }

  @override
  Future<void> markRouteFinished({
    required int localShiftId,
    required DateTime endedAt,
  }) async {
    final db = await _db;
    await db.update(
      _routesTable,
      {'ended_at': endedAt.toUtc().toIso8601String(), 'is_finished': 1},
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
    );
  }

  @override
  Future<void> assignRemoteShiftId({
    required int localShiftId,
    required int remoteShiftId,
  }) async {
    final db = await _db;
    await db.update(
      _routesTable,
      {'remote_shift_id': remoteShiftId},
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
    );
  }

  @override
  Future<ShiftRouteModel?> getRouteByLocalShiftId(
    int localShiftId, {
    bool includePoints = true,
  }) async {
    return _buildRouteFromColumn(
      column: 'local_shift_id',
      value: localShiftId,
      includePoints: includePoints,
    );
  }

  @override
  Future<ShiftRouteModel?> getRouteByRemoteShiftId(
    int remoteShiftId, {
    bool includePoints = true,
  }) async {
    return _buildRouteFromColumn(
      column: 'remote_shift_id',
      value: remoteShiftId,
      includePoints: includePoints,
    );
  }

  @override
  Future<void> deleteRoute(int localShiftId) async {
    final db = await _db;
    _lastSavedPointByShift.remove(localShiftId);
    await db.delete(
      _pointsTable,
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
    );
    await db.delete(
      _routesTable,
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
    );
  }

  Future<Map<String, Object?>?> _getRouteRowByColumn({
    required String column,
    required Object value,
  }) async {
    final db = await _db;
    final rows = await db.query(
      _routesTable,
      where: '$column = ?',
      whereArgs: [value],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first;
  }

  Future<ShiftRouteModel?> _buildRouteFromColumn({
    required String column,
    required Object value,
    required bool includePoints,
  }) async {
    final routeRow = await _getRouteRowByColumn(column: column, value: value);
    if (routeRow == null) {
      return null;
    }

    final points = includePoints
        ? await _getPoints(routeRow['local_shift_id'] as int)
        : <TrackedRoutePointModel>[];

    return ShiftRouteModel.fromDb(routeRow: routeRow, points: points);
  }

  Future<List<TrackedRoutePointModel>> _getPoints(int localShiftId) async {
    final db = await _db;
    final rows = await db.query(
      _pointsTable,
      where: 'local_shift_id = ?',
      whereArgs: [localShiftId],
      orderBy: 'recorded_at ASC',
    );

    return rows.map(TrackedRoutePointModel.fromDb).toList();
  }
}
