import 'package:direcao_financeira_mobile/app/core/theme/app_theme.dart';
import 'package:direcao_financeira_mobile/app/presentation/widgets/premium_access_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  testWidgets('renderiza selo, titulo, beneficios e CTA', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PremiumAccessBanner(onViewSubscription: () {})),
      ),
    );

    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.text('7 dias grátis'), findsOneWidget);
    expect(find.text('Escolha seu plano'), findsOneWidget);
    expect(find.text('Mensal'), findsOneWidget);
    expect(find.text('Anual'), findsOneWidget);
    expect(find.text('COMEÇAR TESTE GRÁTIS'), findsOneWidget);
    expect(find.text('Ver planos'), findsOneWidget);
  });

  testWidgets('renderiza sem overflow em largura compacta', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PremiumAccessBanner(onViewSubscription: () {})),
      ),
    );
    await tester.pumpAndSettle();

    FlutterError.onError = previousOnError;
    await tester.binding.setSurfaceSize(null);

    expect(
      errors.where(
        (error) => error.exceptionAsString().contains('RenderFlex overflowed'),
      ),
      isEmpty,
    );
    expect(find.byType(Scrollable), findsNothing);
  });
}
