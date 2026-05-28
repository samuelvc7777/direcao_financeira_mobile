import 'package:get/get.dart';

import '../../../domain/entities/shift_entity.dart';
import '../../../domain/entities/shift_route_entity.dart';
import '../../../domain/usecases/journey_use_cases.dart';

class ShiftRouteController extends GetxController {
  ShiftRouteController({
    required this.getShiftRouteUseCase,
  });

  final GetShiftRouteUseCase getShiftRouteUseCase;

  final isLoading = false.obs;
  final route = Rxn<ShiftRouteEntity>();
  final errorMessage = RxnString();
  final shift = Rxn<ShiftEntity>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is ShiftEntity) {
      shift.value = args;
      loadRoute();
      return;
    }

    errorMessage.value = 'Nao foi possivel identificar o turno para abrir a rota.';
  }

  Future<void> loadRoute() async {
    final shiftValue = shift.value;
    if (shiftValue == null) {
      errorMessage.value = 'Turno invalido para carregar a rota.';
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    final result = await getShiftRouteUseCase(
      localShiftId: shiftValue.localId,
      remoteShiftId: shiftValue.remoteShiftId,
    );

    result.fold(
      (failure) => errorMessage.value = failure.message,
      (loadedRoute) => route.value = loadedRoute,
    );

    isLoading.value = false;
  }
}
