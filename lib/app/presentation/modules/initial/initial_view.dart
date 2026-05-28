import 'package:direcao_financeira_mobile/app/presentation/modules/journey/journey_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_view.dart';
import '../transactions/transactions_view.dart';
import '../settings/settings_view.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import 'initial_controller.dart';

class InitialView extends GetView<InitialController> {
  const InitialView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: List.generate(4, _buildScreenForIndex),
        ),
      ),
      bottomNavigationBar: Obx(
        () => CustomBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTap: controller.changeTab,
        ),
      ),
    );
  }

  Widget _buildScreenForIndex(int index) {
    if (!controller.isTabLoaded(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return const HomeView();
      case 1:
        return const TransactionsView();
      case 2:
        return const JourneyView();
      case 3:
        return const SettingsView();
      default:
        return const SizedBox.shrink();
    }
  }
}
