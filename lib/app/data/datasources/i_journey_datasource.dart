import '../models/active_shift_model.dart';
import '../models/journey_statistics_model.dart';
import '../models/pending_finished_shift_model.dart';
import '../models/shift_route_model.dart';
import '../models/shift_model.dart';
import '../../domain/entities/paged_result_entity.dart';

abstract class IJourneyDataSource {
  Future<ActiveShiftModel?> getActiveShift();
  Future<JourneyStatisticsModel> getDailyStatistics({
    String filter = 'day',
    String? date,
    String? endDate,
  });
  Future<PagedResultEntity<ShiftModel>> getShiftHistory({
    String filter = 'day',
    String? date,
    String? endDate,
    int offset = 0,
    int limit = 20,
  });
  Future<int> syncFinishedShift(
    PendingFinishedShiftModel shift,
    ShiftRouteModel? trackedRoute,
  );
  Future<void> deleteShift(int shiftId);
  Future<ShiftRouteModel> getShiftRoute(int shiftId);
}
