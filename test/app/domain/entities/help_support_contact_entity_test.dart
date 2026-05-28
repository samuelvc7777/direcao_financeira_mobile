import 'package:direcao_financeira_mobile/app/domain/entities/help_support_contact_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('monta link wa.me a partir do telefone da empresa', () {
    const contact = HelpSupportContactEntity(
      whatsappPhone: '+55 (32) 98459-0116',
      initialMessage: 'Ola, preciso de ajuda.',
    );

    final uri = contact.toUri();

    expect(contact.isConfigured, isTrue);
    expect(uri?.host, 'wa.me');
    expect(uri?.path, '/5532984590116');
    expect(uri?.queryParameters['text'], 'Ola, preciso de ajuda.');
  });

  test('url configurada tem prioridade sobre telefone', () {
    const contact = HelpSupportContactEntity(
      whatsappPhone: '553200000000',
      whatsappUrl: 'https://wa.me/5511999999999',
    );

    expect(contact.toUri().toString(), 'https://wa.me/5511999999999');
  });
}
