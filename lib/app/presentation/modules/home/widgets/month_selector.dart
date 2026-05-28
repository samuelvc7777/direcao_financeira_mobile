import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../widgets/app_month_selector.dart';
import '../home_controller.dart';

class MonthSelector extends GetView<HomeController> {
  const MonthSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final month = controller.selectedMonth.value;
      final formatted = DateFormat(
        'MMMM yyyy',
        'pt_BR',
      ).format(month).toUpperCase();

      return AppMonthSelector(
        label: formatted,
        onPrevious: controller.previousMonth,
        onNext: controller.nextMonth,
      );
    });
  }
}
