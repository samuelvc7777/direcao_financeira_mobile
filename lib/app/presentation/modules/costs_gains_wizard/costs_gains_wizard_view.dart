import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/custom_app_bar.dart';
import 'costs_gains_wizard_controller.dart';
import 'costs_gains_wizard_presentation.dart';
import 'widgets/costs_gains_wizard_step_content.dart';

class CostsGainsWizardView extends GetView<CostsGainsWizardController> {
  const CostsGainsWizardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Configuracoes', showBackButton: true),
      bottomNavigationBar: Obx(
        () => _WizardBottomBar(
          isFirstStep: controller.isFirstStep,
          isLastStep: controller.isLastStep,
          isSubmitting: controller.isSubmitting.value,
          accentColor: wizardStepPresentation(controller.activeStep).accent,
          onBack: controller.goBack,
          onContinue: controller.continueOrFinish,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final presentation = wizardStepPresentation(controller.activeStep);

          return LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final horizontalPadding = width < 360
                  ? 10.0
                  : width < 430
                  ? 14.0
                  : 18.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  4,
                  horizontalPadding,
                  98,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WizardHero(
                          presentation: presentation,
                          stepIndex: controller.currentStep.value + 1,
                          totalSteps: controller.steps.length,
                          progressPercent: controller.progressPercent,
                          progress: controller.progress,
                        ),
                        const SizedBox(height: 10),
                        CostsGainsWizardStepContent(
                          controller: controller,
                          step: controller.activeStep,
                          presentation: presentation,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _WizardHero extends StatelessWidget {
  const _WizardHero({
    required this.presentation,
    required this.stepIndex,
    required this.totalSteps,
    required this.progressPercent,
    required this.progress,
  });

  final CostsGainsWizardStepPresentation presentation;
  final int stepIndex;
  final int totalSteps;
  final int progressPercent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            presentation.accent.withValues(alpha: 0.16),
            colorScheme.surface,
          ],
        ),
        border: Border.all(color: presentation.accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  presentation.accent.withValues(alpha: 0.85),
                  presentation.accent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: presentation.accent.withValues(alpha: 0.24),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(presentation.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            presentation.title,
            style: context.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            presentation.subtitle,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Etapa $stepIndex de $totalSteps',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: presentation.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$progressPercent%',
                style: context.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.52),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(presentation.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              totalSteps,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: index == stepIndex - 1 ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: index <= stepIndex - 1
                      ? presentation.accent
                      : colorScheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardBottomBar extends StatelessWidget {
  const _WizardBottomBar({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isSubmitting,
    required this.accentColor,
    required this.onBack,
    required this.onContinue,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final bool isSubmitting;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.98),
          border: Border(
            top: BorderSide(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            if (!isFirstStep) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(
                      color: accentColor.withValues(alpha: 0.42),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    foregroundColor: accentColor,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              flex: 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [accentColor.withValues(alpha: 0.85), accentColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: isSubmitting ? null : onContinue,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isLastStep
                              ? Icons.check_circle_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    isLastStep ? 'Calcular' : 'Continuar',
                    style: context.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
