import '../models/costs_gains_settings_model.dart';

abstract class ICostsGainsSettingsDataSource {
  Future<CostsGainsSettingsModel?> getCurrentUserSettings();
  Future<bool> hasCurrentUserSettings();
  Future<CostsGainsSettingsModel> saveCurrentUserSettings(
    CostsGainsSettingsModel model,
  );
}
