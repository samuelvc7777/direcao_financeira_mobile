import 'package:direcao_financeira_mobile/app/data/models/credit_card_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreditCardModel.fromJson', () {
    test('usa fallbacks quando campos textuais antigos vêm nulos', () {
      final model = CreditCardModel.fromJson({
        'id': 1,
        'name': null,
        'brand': null,
        'color': null,
        'limitCents': 100000,
        'availableLimitCents': null,
        'closingDay': null,
        'dueDay': null,
        'lastFourDigits': null,
        'isActive': null,
      });

      expect(model.name, 'Cartao');
      expect(model.brand, 'Cartao');
      expect(model.color, '#8B5CF6');
      expect(model.availableLimitCents, 100000);
      expect(model.closingDay, 1);
      expect(model.dueDay, 1);
      expect(model.lastFourDigits, '0000');
      expect(model.isActive, isTrue);
    });
  });
}
