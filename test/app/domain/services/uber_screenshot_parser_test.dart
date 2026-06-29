import 'package:direcao_financeira_mobile/app/domain/services/movesj_history_screenshot_parser.dart';
import 'package:direcao_financeira_mobile/app/domain/services/uber_screenshot_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('le print posicionado do UberX por regioes do card', () {
    const parser = UberScreenshotParser();

    final result = parser.parsePositioned(const [
      OcrTextLine(text: '14:33', left: 42, top: 30, right: 125, bottom: 70),
      OcrTextLine(text: '240 m', left: 170, top: 22, right: 295, bottom: 70),
      OcrTextLine(text: 'BR-265', left: 380, top: 240, right: 500, bottom: 290),
      OcrTextLine(
        text: 'UberX',
        left: 170,
        top: 1020,
        right: 310,
        bottom: 1078,
      ),
      OcrTextLine(
        text: 'R\$ 12,30',
        left: 84,
        top: 1135,
        right: 560,
        bottom: 1240,
      ),
      OcrTextLine(
        text: '4,93 (42)',
        left: 165,
        top: 1280,
        right: 360,
        bottom: 1335,
      ),
      OcrTextLine(
        text: '10 min (4.0 km)',
        left: 165,
        top: 1420,
        right: 460,
        bottom: 1480,
      ),
      OcrTextLine(
        text: 'Rua Marco Aurélio Stefani,',
        left: 165,
        top: 1490,
        right: 620,
        bottom: 1545,
      ),
      OcrTextLine(
        text: 'Barbacena, Barbacena',
        left: 165,
        top: 1550,
        right: 590,
        bottom: 1605,
      ),
      OcrTextLine(
        text: '11 minutos (4.4 km)',
        left: 165,
        top: 1608,
        right: 510,
        bottom: 1665,
      ),
      OcrTextLine(
        text: 'condomínio adib kyrillos, 39,',
        left: 165,
        top: 1690,
        right: 680,
        bottom: 1745,
      ),
      OcrTextLine(
        text: 'Pontilhão, Barbacena',
        left: 165,
        top: 1750,
        right: 600,
        bottom: 1805,
      ),
      OcrTextLine(
        text: 'Aceitar',
        left: 390,
        top: 1860,
        right: 560,
        bottom: 1920,
      ),
    ]);

    expect(result.platformName, 'Uber');
    expect(result.grossValueCents, 1230);
    expect(result.passengerRating, 4.93);
    expect(result.originAddress, contains('Marco Aurélio'));
    expect(result.destinationAddress, contains('adib kyrillos'));
  });

  test('detecta Uber pelo texto bruto do OCR', () {
    const parser = UberScreenshotParser();
    const rawText = '''
UberX
R\$ 12,30
4,93 (42)
10 min (4.0 km)
Rua Marco Aurélio Stefani, Barbacena, Barbacena
11 minutos (4.4 km)
condomínio adib kyrillos, 39, Pontilhão, Barbacena
Aceitar
''';

    final result = parser.parse(rawText);

    expect(parser.looksLike(rawText.split('\n')), isTrue);
    expect(result.platformName, 'Uber');
    expect(result.grossValueCents, 1230);
    expect(result.destinationAddress, contains('kyrillos'));
  });
}
