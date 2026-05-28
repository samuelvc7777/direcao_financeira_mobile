import 'package:get/get.dart';

abstract class DashboardRefreshNotifier {
  RxInt get refreshTick;

  void requestRefresh();
}

class DefaultDashboardRefreshNotifier implements DashboardRefreshNotifier {
  @override
  final RxInt refreshTick = 0.obs;

  @override
  void requestRefresh() {
    refreshTick.value++;
  }
}
