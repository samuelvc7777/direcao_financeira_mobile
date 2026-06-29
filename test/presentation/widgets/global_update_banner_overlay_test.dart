import 'package:direcao_financeira_mobile/app/presentation/widgets/global_update_banner_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('nao renderiza aviso quando show=false', (tester) async {
    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: false,
          onUpdate: () {},
          onCancel: () {},
          child: const Text('Conteudo atual'),
        ),
      ),
    );

    expect(find.text('Conteudo atual'), findsOneWidget);
    expect(find.text('Nova versao disponivel'), findsNothing);
    expect(find.text('ATUALIZAR AGORA'), findsNothing);
  });

  testWidgets('renderiza overlay, selo, titulo e mensagem quando show=true', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: true,
          onUpdate: () {},
          onCancel: () {},
          child: const Text('Conteudo atual'),
        ),
      ),
    );

    expect(find.text('Conteudo atual'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.text('PLAY STORE'), findsOneWidget);
    expect(find.text('ATUALIZACAO RECOMENDADA'), findsOneWidget);
    expect(find.text('Nova versao disponivel'), findsOneWidget);
    expect(find.textContaining('melhorias'), findsOneWidget);
    expect(find.text('ATUALIZAR AGORA'), findsOneWidget);
    expect(find.text('Agora nao'), findsOneWidget);
  });

  testWidgets('tocar em ATUALIZAR AGORA chama callback', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: true,
          onUpdate: () => calls++,
          onCancel: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('ATUALIZAR AGORA'));

    expect(calls, 1);
  });

  testWidgets('tocar em Agora nao chama callback de cancelamento', (
    tester,
  ) async {
    var calls = 0;

    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: true,
          onUpdate: () {},
          onCancel: () => calls++,
          child: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.tap(find.text('Agora nao'));

    expect(calls, 1);
  });

  testWidgets('forceUpdate oculta acao secundaria sem bloquear MVP', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: true,
          forceUpdate: true,
          onUpdate: () {},
          onCancel: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('ATUALIZAR AGORA'), findsOneWidget);
    expect(find.text('Agora nao'), findsNothing);
  });

  testWidgets('mantem layout responsivo em viewport estreito e baixo', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 420));
    addTearDown(() async => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildApp(
        GlobalUpdateBannerOverlay(
          show: true,
          onUpdate: () {},
          onCancel: () {},
          child: const SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('ATUALIZAR AGORA'), findsOneWidget);
  });
}

Widget _buildApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );
}
