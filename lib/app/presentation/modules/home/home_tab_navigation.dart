import 'package:get/get.dart';

import '../initial/initial_controller.dart';

abstract class HomeTabNavigation {
  void openTransactionsTab();
}

class GetHomeTabNavigation implements HomeTabNavigation {
  @override
  void openTransactionsTab() {
    if (Get.isRegistered<InitialController>()) {
      Get.find<InitialController>().changeTab(1);
    }
  }
}
