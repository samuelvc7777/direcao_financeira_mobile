import 'package:get/get.dart';

import '../../../core/config/app_environment.dart';
import '../../../data/services/address_autocomplete_service.dart';
import '../../../data/services/ride_route_estimator.dart';
import '../../../domain/services/auto_ride_screenshot_parser.dart';
import '../../../domain/services/resolved_google_api_key_service.dart';
import '../../../domain/usecases/create_detected_ride_usecase.dart';
import '../../../domain/usecases/get_rides_usecase.dart';
import 'import_ride_photo_controller.dart';

class ImportRidePhotoBinding extends Bindings {
  @override
  void dependencies() {
    final googleMapsApiKey = _resolveGoogleMapsApiKey();

    Get.lazyPut<ImportRidePhotoController>(
      () => ImportRidePhotoController(
        createFinishedRideUseCase: Get.find<CreateFinishedRideUseCase>(),
        updateFinishedRideUseCase: Get.find<UpdateFinishedRideUseCase>(),
        getRidesUseCase: Get.isRegistered<GetRidesUseCase>()
            ? Get.find<GetRidesUseCase>()
            : GetRidesUseCase(Get.find()),
        parser: const AutoRideScreenshotParser(),
        addressAutocompleteService: AddressAutocompleteService(
          googleMapsApiKey: googleMapsApiKey,
        ),
        routeEstimator: RideRouteEstimator(googleMapsApiKey: googleMapsApiKey),
      ),
    );
  }

  String _resolveGoogleMapsApiKey() {
    if (Get.isRegistered<ResolvedGoogleApiKeyService>()) {
      return Get.find<ResolvedGoogleApiKeyService>().currentValue;
    }

    return Get.find<AppEnvironment>().googleMapsApiKey;
  }
}
