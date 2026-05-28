import 'package:direcao_financeira_mobile/app/domain/services/auto_ride_screenshot_parser.dart';
import 'package:direcao_financeira_mobile/app/domain/services/movesj_history_screenshot_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mantem o parser de MoveSJ quando o print e de historico MoveSJ', () {
    const parser = AutoRideScreenshotParser();

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
    expect(result.grossValueCents, 1751);
    expect(result.passengerName, 'Carolina');
  });

  test('mantem o parser de MoveSJ quando a tela tem recusar e aceitar', () {
    const parser = AutoRideScreenshotParser();

    final result = parser.parse('''
Move
R\$ 13,40
1,7 km (R\$ 7,93/km)
5 min (R\$ 2,67/min)
Recusar
Aceitar
Endereco de Origem
R. Getulio Vargas, 989 - A Definir, Santa Cruz de Minas - MG, 36302-142, Brasil
Endereco de Destino
Independentes
''');

    expect(result.platformName, 'MoveSJ');
    expect(result.originAddress, contains('Getulio Vargas'));
    expect(result.destinationAddress, contains('Independentes'));
  });

  test('detecta Me Leva SJ e limpa embarque e destino do print', () {
    const parser = AutoRideScreenshotParser();

    final result = parser.parse('''
R\$ 12,00
Embarque
Av. Leite de Castro (660m) 1 min
Fábricas de Castro (lado impar) -
Destino - 12 min
R. Vilma Aparecida Araújo, 195 - Vila Jardim São José
Moto Taxi
Dinheiro
''');

    expect(result.platformName, 'MeLevaSJ');
    expect(result.originAddress, contains('Av. Leite de Castro'));
    expect(result.originAddress, contains('lado impar'));
    expect(result.destinationAddress, contains('R. Vilma Aparecida Araújo'));
    expect(result.destinationAddress, isNot(contains('12 min')));
    expect(result.grossValueCents, 1200);
    expect(result.paymentMethod, isIn(['Moto Taxi', 'Dinheiro']));
  });

  test(
    'remove ruido de nota e prefixos estranhos do endereco no Me Leva SJ',
    () {
      const parser = AutoRideScreenshotParser();

      final result = parser.parse('''
R\$ 12,00
Embarque
* 5,0 Av. Leite de Castro (lado impar) -
FÃ¡bricas de Castro
Destino - 12 min
in R. Vilma Aparecida AraÃºjo, 195 - Vila Jardim SÃ£o JosÃ©
Moto Taxi
Dinheiro
''');

      expect(result.platformName, 'MeLevaSJ');
      expect(result.passengerRating, 5.0);
      expect(result.originAddress, isNot(contains('5,0')));
      expect(result.originAddress, contains('Av. Leite de Castro'));
      expect(result.destinationAddress, isNot(contains('12 min')));
      expect(result.destinationAddress, isNot(contains('in ')));
      expect(result.destinationAddress, contains('R. Vilma Aparecida AraÃºjo'));
    },
  );

  test(
    'captura nota do passageiro do Me Leva SJ quando OCR separa a estrela',
    () {
      const parser = AutoRideScreenshotParser();

      final result = parser.parse('''
R\$ 12,00
5,0
Embarque - (660m) 1 min
Av. Leite de Castro (lado impar) -
Fabricas de Castro
Destino - 12 min
R. Vilma Aparecida Araujo, 195 - Vila Jardim Sao Jose
Moto Taxi
Dinheiro
''');

      expect(result.platformName, 'MeLevaSJ');
      expect(result.passengerRating, 5.0);
      expect(result.originAddress, contains('Av. Leite de Castro'));
      expect(result.originAddress, isNot(contains('5,0')));
      expect(result.grossValueCents, 1200);
    },
  );

  test('usa ultimo endereco como destino quando Me Leva SJ tem parada', () {
    const parser = AutoRideScreenshotParser();

    final result = parser.parse('''
R\$ 28,00
Embarque - (660m) 1 min
Av. Origem, 10 - Centro
Destino - 8 min
Rua Parada, 20 - Centro
12 min
Rua Destino Final, 300 - Bairro Final
Moto Taxi
Dinheiro
''');

    expect(result.platformName, 'MeLevaSJ');
    expect(result.originAddress, 'Av. Origem, 10 - Centro');
    expect(result.destinationAddress, 'Rua Destino Final, 300 - Bairro Final');
  });

  test('detecta Me Leva SJ quando OCR vem posicionado', () {
    const parser = AutoRideScreenshotParser();

    final result = parser.parsePositioned(const [
      OcrTextLine(
        text: 'R\$ 12,00',
        left: 640,
        top: 180,
        right: 760,
        bottom: 240,
      ),
      OcrTextLine(
        text: 'Embarque',
        left: 120,
        top: 620,
        right: 260,
        bottom: 670,
      ),
      OcrTextLine(
        text: 'Av. Leite de Castro (660m) 1 min',
        left: 120,
        top: 690,
        right: 640,
        bottom: 740,
      ),
      OcrTextLine(
        text: 'Fábricas de Castro (lado impar) -',
        left: 120,
        top: 750,
        right: 660,
        bottom: 800,
      ),
      OcrTextLine(
        text: 'Destino',
        left: 120,
        top: 840,
        right: 260,
        bottom: 890,
      ),
      OcrTextLine(
        text: '12 min R. Vilma Aparecida Araújo, 195 - Vila Jardim São José',
        left: 120,
        top: 910,
        right: 760,
        bottom: 960,
      ),
      OcrTextLine(
        text: 'Moto Taxi',
        left: 120,
        top: 1100,
        right: 300,
        bottom: 1150,
      ),
    ]);

    expect(result.platformName, 'MeLevaSJ');
    expect(result.originAddress, contains('Av. Leite de Castro'));
    expect(result.destinationAddress, contains('R. Vilma Aparecida Araújo'));
    expect(result.grossValueCents, 1200);
  });
}
