import 'package:direcao_financeira_mobile/app/domain/services/movesj_history_screenshot_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extrai dados principais do print de historico MoveSJ', () {
    const parser = MoveSjHistoryScreenshotParser();

    final result = parser.parse('''
Detalhe
12/05/26 11:44
Endereco de Origem
Rua Doutor Antonio Freitas de Carvalho, 259 -
Sao Joao Del Rei - MG
Endereco de Destino
Paroquia Sao Jose Operario - Rua Jose Otavio
Ferreira de Assis - Aguas Ferreas (Tejuco), Sao
Joao del Rei - MG
Numero Viagem
1843891
Status
Viagem Finalizada
Forma de Pagamento
Maquina de Cartao
Valor Motorista
R\$ 17,51
Valor Total
R\$ 17,51
Cliente
Carolina
''');

    expect(result.platformName, 'MoveSJ');
    expect(result.detectedAt, DateTime(2026, 5, 12, 11, 44));
    expect(result.originAddress, contains('Rua Doutor Antonio'));
    expect(result.destinationAddress, contains('Paroquia Sao Jose'));
    expect(result.tripNumber, '1843891');
    expect(result.paymentMethod, 'Maquina de Cartao');
    expect(result.grossValueCents, 1751);
    expect(result.passengerName, 'Carolina');
  });

  test('usa valor total e limpa estrelas do nome do cliente', () {
    const parser = MoveSjHistoryScreenshotParser();

    final result = parser.parse('''
Valor Motorista Valor Total
R\$ 15,00 R\$ 17,51
Cliente
Carolina ★★★★★
''');

    expect(result.grossValueCents, 1751);
    expect(result.passengerName, 'Carolina');
  });

  test('extrai endereco e cliente quando OCR junta rotulo e valor', () {
    const parser = MoveSjHistoryScreenshotParser();

    final result = parser.parse('''
Endereco de Origem Rua Doutor Antonio Freitas de Carvalho, 259 - Sao Joao Del Rei - MG
Endereco de Destino Paroquia Sao Jose Operario - Rua Jose Otavio Ferreira de Assis - Sao Joao del Rei - MG
Cliente Carolina
Valor Motorista Valor Total
R\$ 15,00 R\$ 17,51
''');

    expect(result.originAddress, startsWith('Rua Doutor Antonio'));
    expect(result.destinationAddress, startsWith('Paroquia Sao Jose'));
    expect(result.passengerName, 'Carolina');
    expect(result.grossValueCents, 1751);
  });

  test('usa posicao dos textos para ignorar barra de status no cliente', () {
    const parser = MoveSjHistoryScreenshotParser();

    final result = parser.parsePositioned(const [
      OcrTextLine(text: 'L 49', left: 900, top: 20, right: 980, bottom: 60),
      OcrTextLine(
        text: 'Endereco de Origem',
        left: 90,
        top: 800,
        right: 390,
        bottom: 850,
      ),
      OcrTextLine(
        text: 'Rua Doutor Antonio Freitas de Carvalho, 259 -',
        left: 90,
        top: 860,
        right: 780,
        bottom: 910,
      ),
      OcrTextLine(
        text: 'Sao Joao Del Rei - MG',
        left: 90,
        top: 920,
        right: 450,
        bottom: 970,
      ),
      OcrTextLine(
        text: 'Endereco de Destino',
        left: 90,
        top: 1040,
        right: 420,
        bottom: 1090,
      ),
      OcrTextLine(
        text: 'Paroquia Sao Jose Operario - Rua Jose Otavio Ferreira',
        left: 90,
        top: 1100,
        right: 880,
        bottom: 1150,
      ),
      OcrTextLine(
        text: 'Numero Viagem',
        left: 90,
        top: 1280,
        right: 360,
        bottom: 1330,
      ),
      OcrTextLine(
        text: 'Valor Total',
        left: 720,
        top: 1600,
        right: 930,
        bottom: 1650,
      ),
      OcrTextLine(
        text: 'R\$ 17,51',
        left: 720,
        top: 1660,
        right: 900,
        bottom: 1710,
      ),
      OcrTextLine(
        text: 'Cliente',
        left: 90,
        top: 1780,
        right: 230,
        bottom: 1830,
      ),
      OcrTextLine(
        text: 'Mariana Silva',
        left: 320,
        top: 1850,
        right: 620,
        bottom: 1900,
      ),
      OcrTextLine(
        text: '★★★★★',
        left: 320,
        top: 1910,
        right: 620,
        bottom: 1960,
      ),
    ]);

    expect(result.passengerName, 'Mariana Silva');
    expect(result.originAddress, contains('Rua Doutor Antonio'));
    expect(result.destinationAddress, contains('Paroquia Sao Jose'));
    expect(result.grossValueCents, 1751);
  });
}
