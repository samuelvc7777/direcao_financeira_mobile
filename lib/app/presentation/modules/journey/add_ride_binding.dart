import 'package:get/get.dart';

import '../../../core/config/app_environment.dart';
import '../../../data/services/address_autocomplete_service.dart';
import '../../../data/services/ride_route_estimator.dart';
import '../../../domain/services/resolved_google_api_key_service.dart';
import '../../../domain/usecases/create_detected_ride_usecase.dart';
import 'add_ride_controller.dart';

class AddRideBinding extends Bindings {
  @override
  void dependencies() {
    final googleMapsApiKey = _resolveGoogleMapsApiKey();

    Get.lazyPut<AddRideController>(
      () => AddRideController(
        createDetectedRideUseCase: Get.find<CreateDetectedRideUseCase>(),
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
