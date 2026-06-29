import 'package:direcao_financeira_mobile/app/domain/services/movesj_history_screenshot_parser.dart';
import 'package:direcao_financeira_mobile/app/domain/services/ninety_nine_screenshot_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le print posicionado da 99 entrega carro premium', () {
    const parser = NinetyNineScreenshotParser();

    final result = parser.parsePositioned(const [
      OcrTextLine(
        text: 'Barbacena',
        left: 70,
        top: 110,
        right: 145,
        bottom: 130,
      ),
      OcrTextLine(
        text: 'Entrega Carro',
        left: 120,
        top: 150,
        right: 225,
        bottom: 172,
      ),
      OcrTextLine(
        text: 'R\$13,00',
        left: 95,
        top: 180,
        right: 245,
        bottom: 225,
      ),
      OcrTextLine(
        text: 'R\$2,28/km',
        left: 125,
        top: 230,
        right: 215,
        bottom: 250,
      ),
      OcrTextLine(
        text: 'Preco x1,4',
        left: 120,
        top: 260,
        right: 220,
        bottom: 282,
      ),
      OcrTextLine(
        text: '4,93 · Perfil Premium',
        left: 38,
        top: 315,
        right: 235,
        bottom: 338,
      ),
      OcrTextLine(
        text: '5min (1,4km)',
        left: 38,
        top: 370,
        right: 165,
        bottom: 394,
      ),
      OcrTextLine(
        text:
            'Acougue, Rua Mal. Floriano Peixoto, 135 - Centro, Barbacena - MG',
        left: 52,
        top: 400,
        right: 315,
        bottom: 444,
      ),
      OcrTextLine(
        text: '10min (4,3km)',
        left: 38,
        top: 460,
        right: 175,
        bottom: 484,
      ),
      OcrTextLine(
        text: 'Rua Luis Claudio dos Santos, 318 - Jardim das Alterosas',
        left: 52,
        top: 490,
        right: 315,
        bottom: 534,
      ),
    ]);

    expect(result.platformName, '99');
    expect(result.grossValueCents, 1300);
    expect(result.passengerName, 'Perfil Premium');
    expect(result.passengerRating, 4.93);
    expect(result.originAddress, contains('Acougue'));
    expect(result.destinationAddress, contains('Rua Luis Claudio'));
  });

  test('le print posicionado da 99 negocia dinheiro e ignora botoes', () {
    const parser = NinetyNineScreenshotParser();

    final result = parser.parsePositioned(const [
      OcrTextLine(
        text: 'Remedios',
        left: 270,
        top: 80,
        right: 335,
        bottom: 100,
      ),
      OcrTextLine(
        text: 'Negocia · Dinheiro',
        left: 105,
        top: 130,
        right: 255,
        bottom: 154,
      ),
      OcrTextLine(
        text: 'R\$12,60',
        left: 105,
        top: 165,
        right: 245,
        bottom: 210,
      ),
      OcrTextLine(
        text: 'R\$2,17/km',
        left: 125,
        top: 218,
        right: 220,
        bottom: 238,
      ),
      OcrTextLine(
        text: 'Preco x1,7',
        left: 125,
        top: 250,
        right: 220,
        bottom: 272,
      ),
      OcrTextLine(
        text: '4,88 · 162 corridas',
        left: 55,
        top: 310,
        right: 225,
        bottom: 334,
      ),
      OcrTextLine(
        text: 'Perfil Essencial',
        left: 55,
        top: 342,
        right: 190,
        bottom: 365,
      ),
      OcrTextLine(
        text: '7min (2,5km)',
        left: 55,
        top: 405,
        right: 180,
        bottom: 429,
      ),
      OcrTextLine(
        text: 'Campos Distribuidora, Rua Sena Madureira - Pontilhao',
        left: 72,
        top: 435,
        right: 318,
        bottom: 476,
      ),
      OcrTextLine(
        text: '8min (3,3km)',
        left: 55,
        top: 490,
        right: 180,
        bottom: 514,
      ),
      OcrTextLine(
        text: 'Rua Ulisses Magri, 37, Ipanema',
        left: 72,
        top: 520,
        right: 300,
        bottom: 548,
      ),
      OcrTextLine(
        text: 'Aceitar por R\$12,60',
        left: 95,
        top: 565,
        right: 270,
        bottom: 595,
      ),
      OcrTextLine(
        text: 'R\$13,23',
        left: 55,
        top: 610,
        right: 115,
        bottom: 635,
      ),
      OcrTextLine(
        text: 'R\$13,61',
        left: 125,
        top: 610,
        right: 185,
        bottom: 635,
      ),
      OcrTextLine(
        text: 'R\$13,86',
        left: 195,
        top: 610,
        right: 255,
        bottom: 635,
      ),
    ]);

    expect(result.platformName, '99');
    expect(result.grossValueCents, 1260);
    expect(result.paymentMethod, 'Dinheiro');
    expect(result.passengerName, 'Perfil Essencial');
    expect(result.passengerRating, 4.88);
    expect(result.originAddress, contains('Campos Distribuidora'));
    expect(result.destinationAddress, contains('Rua Ulisses Magri'));
    expect(result.destinationAddress, isNot(contains('R\$13,86')));
  });

  test('autodetecta 99 a partir do texto bruto do OCR', () {
    const parser = NinetyNineScreenshotParser();
    const rawText = '''
Negocia · Dinheiro
R\$12,60
R\$2,17/km
Preço x1,7
4,88 · 162 corridas
Perfil Essencial
7min (2,5km)
Campos Distribuidora, Rua Sena Madureira - Pontilhao
8min (3,3km)
Rua Ulisses Magri, 37, Ipanema
Aceitar por R\$12,60
R\$13,23
''';

    final result = parser.parse(rawText);

    expect(parser.looksLike(rawText.split('\n')), isTrue);
    expect(result.platformName, '99');
    expect(result.grossValueCents, 1260);
    expect(result.paymentMethod, 'Dinheiro');
  });

  test('autodetecta 99 com primeira rota em metros', () {
    const parser = NinetyNineScreenshotParser();
    const rawText = '''
Dinheiro
Prioritario
R\$6,00
R\$2,02/km
R\$1,23 Tarifa base dinamica incl.
4,98 Â· 183 corridas
Perfil Premium
5min (590m)
Supermercados Bh, R. Lima Duarte, 59 - Centro
8min (2,4km)
Rua Maria Antonia de Castro, 136, Funcionarios
''';

    final result = parser.parse(rawText);

    expect(parser.looksLike(rawText.split('\n')), isTrue);
    expect(result.platformName, '99');
    expect(result.grossValueCents, 600);
    expect(result.paymentMethod, 'Dinheiro');
    expect(result.passengerName, 'Perfil Premium');
    expect(result.originAddress, contains('Supermercados Bh'));
    expect(result.destinationAddress, contains('Rua Maria Antonia'));
  });

  test('le 99 com parada sem usar parada como endereco', () {
    const parser = NinetyNineScreenshotParser();
    const rawText = '''
Pgto. no app
Prioritario
R\$12,10
R\$2,11/km
R\$2,87 Tarifa base dinamica incl.
4,96 Â· 461 corridas
Perfil Essencial
3min (138m)
Lanchonete, Pca. Pedro Teixeira
1 parada(s)
15min (5,6km)
Rua Maj. Suckow, 1101, Nova Suica
''';

    final result = parser.parse(rawText);

    expect(parser.looksLike(rawText.split('\n')), isTrue);
    expect(result.platformName, '99');
    expect(result.grossValueCents, 1210);
    expect(result.passengerName, 'Perfil Essencial');
    expect(result.originAddress, 'Lanchonete, Pca. Pedro Teixeira');
    expect(result.destinationAddress, 'Rua Maj. Suckow, 1101, Nova Suica');
  });

  test('junta destino da 99 quando OCR quebra endereco em varias linhas', () {
    const parser = NinetyNineScreenshotParser();
    const rawText = '''
Dinheiro
R\$7,10
R\$2,21/km
4,99 Â· 187 corridas
CPF verif.
3min (251m)
Autoescola Social Barbacena, Praca
Conde de Prados, 99 - Centro
1 parada(s)
10min (3km)
Oratorio Diario Madre Madalena
Morano - Rede Salesiana Brasil, Rua Vigario Brito
''';

    final result = parser.parse(rawText);

    expect(
      result.originAddress,
      'Autoescola Social Barbacena, Praca Conde de Prados, 99 - Centro',
    );
    expect(
      result.destinationAddress,
      'Oratorio Diario Madre Madalena Morano - Rede Salesiana Brasil, Rua Vigario Brito',
    );
  });
}
