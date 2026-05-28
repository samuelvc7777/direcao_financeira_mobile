import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/custom_app_bar.dart';
import 'shift_route_controller.dart';
import 'widgets/shift_route_content.dart';

class ShiftRouteView extends GetView<ShiftRouteController> {
  const ShiftRouteView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Rota do Turno',
        showBackButton: true,
      ),
      body: const SafeArea(
        child: ShiftRouteContent(),
      ),
    );
  }
}
