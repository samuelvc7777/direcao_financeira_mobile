import 'package:direcao_financeira_mobile/app/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom navigation permanece livre para troca de abas', (
    tester,
  ) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: CustomBottomNavBar(
                currentIndex: selectedIndex,
                onTap: (index) => setState(() => selectedIndex = index),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.receipt_long_rounded).last);
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });
}
