import 'dart:io';

import 'package:direcao_financeira_mobile/app/core/errors/failures.dart';
import 'package:direcao_financeira_mobile/app/core/network/api_error_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/dio_test_helpers.dart';

void main() {
  const mapper = ApiErrorMapper();

  group('ApiErrorMapper', () {
    test('retorna AuthFailure para 401 autenticado', () {
      final error = dioBadResponse(
        statusCode: 401,
        data: {'message': 'Sessao expirada'},
        path: '/finance/transactions',
      );

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao carregar transacoes.',
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.message, 'Sessao expirada');
    });

    test('retorna NetworkFailure para timeout', () {
      final error = dioTimeout(path: '/finance/bank-accounts');

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao carregar contas.',
      );

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        'O servidor demorou para responder. Tente novamente em instantes.',
      );
    });

    test('retorna NetworkFailure para falha de conectividade', () {
      final error = dioConnectionError(path: '/finance/credit-cards');

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao carregar cartoes.',
      );

      expect(failure, isA<NetworkFailure>());
      expect(
        failure.message,
        'Verifique sua conexao com a internet e tente novamente.',
      );
    });

    test('extrai message quando a API devolve lista', () {
      final error = dioBadResponse(
        statusCode: 422,
        data: {
          'message': ['Campo obrigatorio'],
        },
      );

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao criar recurso.',
      );

      expect(failure.message, 'Campo obrigatorio');
    });

    test('extrai message quando a API devolve string', () {
      final error = dioBadResponse(
        statusCode: 400,
        data: {'message': 'Descricao invalida'},
      );

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao atualizar recurso.',
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.message, 'Descricao invalida');
    });

    test('usa fallback quando a resposta nao traz message', () {
      final error = dioBadResponse(
        statusCode: 500,
        data: {'error': 'Internal Server Error'},
      );

      final failure = mapper.mapToFailure(
        error,
        fallback: 'Erro ao carregar transacoes.',
      );

      expect(failure.message, 'Erro ao carregar transacoes.');
    });

    test('resume payload longo para logging', () {
      final summary = mapper.summarizePayload({
        'message': List.generate(40, (index) => 'item-$index'),
      });

      expect(summary.length, lessThanOrEqualTo(180));
      expect(summary, contains('item-0'));
    });

    test('mapeia SocketException como NetworkFailure', () {
      final failure = mapper.mapToFailure(
        const SocketException('offline'),
        fallback: 'Erro generico.',
      );

      expect(failure, isA<NetworkFailure>());
    });
  });
}
