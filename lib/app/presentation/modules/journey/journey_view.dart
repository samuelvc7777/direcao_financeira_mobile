import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../widgets/app_loading_indicator.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../routes/app_pages.dart';
import 'journey_controller.dart';
import 'widgets/journey_status_banner.dart';
import 'widgets/recordings_list_section.dart';
import 'widgets/rides_list_section.dart';
import 'widgets/shift_history_section.dart';

class JourneyView extends StatefulWidget {
  const JourneyView({super.key});

  @override
  State<JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<JourneyView>
    with SingleTickerProviderStateMixin {
  late final JourneyController controller;
  late final TabController _tabController;
  late int _selectedTabIndex;
  Worker? _tabIndexWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.find<JourneyController>();

    final args = Get.arguments;
    final initialTabIndex = args is Map
        ? (args['journeyInitialTabIndex'] as int? ?? 0).clamp(0, 2)
        : 0;
    controller.selectJourneyTab(initialTabIndex);
    _selectedTabIndex = controller.selectedJourneyTabIndex.value;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _selectedTabIndex,
    );
    _tabController.addListener(_handleTabControllerChanged);
    _tabIndexWorker = ever<int>(
      controller.selectedJourneyTabIndex,
      _handleSelectedJourneyTabChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      unawaited(controller.refreshRuntimeStateAfterForegroundOpen());
    });
  }

  @override
  void dispose() {
    _tabIndexWorker?.dispose();
    _tabController.removeListener(_handleTabControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabControllerChanged() {
    final index = _tabController.index;
    if (_selectedTabIndex == index) {
      return;
    }

    setState(() {
      _selectedTabIndex = index;
    });

    if (controller.selectedJourneyTabIndex.value != index) {
      controller.selectJourneyTab(index);
    }
  }

  void _handleSelectedJourneyTabChanged(int index) {
    if (!mounted) {
      return;
    }

    if (_tabController.index != index) {
      _tabController.animateTo(index);
    }

    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(
        title: 'Jornada',
        subtitle: 'Controle de turnos e corridas',
        leadingIcon: Icons.work_history_rounded,
        showBackButton: false,
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const AppLoadingScreen(
              label: 'Carregando jornada...',
              accentColor: AppColors.royalBlue,
            );
          }

          return Column(
            children: [
              const JourneyStatusBanner(),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.hp(context, 4.0).clamp(16.0, 24.0),
                  vertical: Responsive.vp(context, 1.5).clamp(12.0, 20.0),
                ),
                child: Container(
                  height: Responsive.vp(context, 6.0).clamp(48.0, 56.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      Responsive.sp(context, 30).clamp(24.0, 30.0),
                    ),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: TabBar(
                      controller: _tabController,
                      onTap: controller.selectJourneyTab,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          Responsive.sp(context, 26).clamp(20.0, 26.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.24),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      labelColor: Colors.white,
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 15.0),
                      ),
                      unselectedLabelColor:
                          context.theme.brightness == Brightness.dark
                          ? colorScheme.onSurfaceVariant
                          : AppColors.textPrimary,
                      unselectedLabelStyle: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: Responsive.sp(context, 14).clamp(12.0, 15.0),
                      ),
                      splashBorderRadius: BorderRadius.circular(
                        Responsive.sp(context, 26).clamp(20.0, 26.0),
                      ),
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                size: Responsive.sp(
                                  context,
                                  18,
                                ).clamp(16.0, 20.0),
                              ),
                              SizedBox(
                                width: Responsive.hp(
                                  context,
                                  1.5,
                                ).clamp(6.0, 10.0),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Turnos'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car_rounded,
                                size: Responsive.sp(
                                  context,
                                  18,
                                ).clamp(16.0, 20.0),
                              ),
                              SizedBox(
                                width: Responsive.hp(
                                  context,
                                  1.5,
                                ).clamp(6.0, 10.0),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Corridas'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.videocam_rounded,
                                size: Responsive.sp(
                                  context,
                                  18,
                                ).clamp(16.0, 20.0),
                              ),
                              SizedBox(
                                width: Responsive.hp(
                                  context,
                                  1.5,
                                ).clamp(6.0, 10.0),
                              ),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: const Text('Gravacoes'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: _JourneyTabsBody(tabController: _tabController)),
            ],
          );
        }),
      ),
      floatingActionButton: _selectedTabIndex == 1
          ? FloatingActionButton.extended(
              heroTag: 'import-ride-photo',
              onPressed: () async {
                final result = await Get.toNamed(
                  AppRoutes.journeyImportRidePhoto,
                );
                if (result == true) {
                  await controller.refreshJourneyData(silent: true);
                }
              },
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.photo_camera_back_rounded),
              label: const Text('Importar print'),
            )
          : null,
    );
  }
}

class _JourneyTabsBody extends StatelessWidget {
  const _JourneyTabsBody({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360
            ? 8.0
            : width < 430
            ? 12.0
            : 16.0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: TabBarView(
                controller: tabController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  ShiftHistorySection(),
                  RidesListSection(),
                  RecordingsListSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
