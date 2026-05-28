// import 'i_journey_datasource.dart';
// import '../models/journey_statistics_model.dart';
// import '../models/shift_model.dart';

// class JourneyDataSourceMockImpl implements IJourneyDataSource {
//   @override
//   Future<JourneyStatisticsModel> getDailyStatistics({String filter = 'day'}) async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     return const JourneyStatisticsModel(
//       totalShifts: 0,
//       totalTime: '00:00:00',
//       averageTime: '00:00:00',
//       drivenKm: '0.0 km',
//       rideStats: RideStatisticsModel(
//         totalRides: 0,
//         grossEarningsCents: 0,
//         netEarningsCents: 0,
//         totalCostsCents: 0,
//         ridesTotalKm: 0.0,
//         ridesTotalTime: 0,
//       ),
//     );
//   }

//   @override
//   Future<List<ShiftModel>> getShiftHistory({String filter = 'day'}) async {
//     await Future.delayed(const Duration(milliseconds: 500));
//     return const [
//       ShiftModel(
//         index: 1,
//         date: '11/03/2026',
//         startTime: '21:08',
//         endTime: '21:08',
//         duration: '00:00:01',
//       ),
//       ShiftModel(
//         index: 2,
//         date: '10/03/2026',
//         startTime: '15:44',
//         endTime: '15:44',
//         duration: '00:00:01',
//       ),
//       ShiftModel(
//         index: 3,
//         date: '10/03/2026',
//         startTime: '12:39',
//         endTime: '14:45',
//         duration: '02:05:25',
//         drivenKm: '23.6',
//       ),
//       ShiftModel(
//         index: 4,
//         date: '10/03/2026',
//         startTime: '12:38',
//         endTime: '12:38',
//         duration: '00:00:07',
//       ),
//       ShiftModel(
//         index: 5,
//         date: '10/03/2026',
//         startTime: '11:00',
//         endTime: '11:00',
//         duration: '00:00:00',
//       ),
//     ];
//   }

//   @override
//   Future<void> startShift() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     // Simulando inicio de turno
//   }

//   @override
//   Future<void> finishShift() async {
//     await Future.delayed(const Duration(milliseconds: 300));
//     // Simulando fim de turno
//   }
// }
