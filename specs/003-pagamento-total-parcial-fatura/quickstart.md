# Quickstart: Pagamento total ou parcial de fatura

## Objetivo

Validar o fluxo novo de pagamento de fatura com escolha entre total e parcial, mantendo o comportamento atual de atualizacao da dashboard.

## Verificacao automatizada

1. Rodar os testes de dominio ligados a validacao do pagamento parcial.

```bash
flutter test test/app/domain/services/
```

2. Rodar os testes de presentation do controller de home.

```bash
flutter test test/app/presentation/modules/home/home_controller_test.dart
```

3. Se houver novo teste de widget para o fluxo da tela, rodar o arquivo especifico criado para a feature.

```bash
flutter test test/app/presentation/modules/home/
```

## Verificacao manual

1. Abrir a home.
2. Tocar em pagar na fatura exibida.
3. Selecionar uma conta.
4. Confirmar que a interface oferece `total` e `partial`.
5. Escolher `partial`, informar um valor valido e confirmar.
6. Verificar que a fatura continua em aberto com saldo restante atualizado.
7. Repetir o fluxo pela tela de cartoes ou pelo CTA equivalente que for adicionado la.

## Observacao de implementacao

- O ponto real renderizado pela rota de cartoes no estado atual do app e
  `lib/app/presentation/modules/credit_cards/credit_cards_view.dart`.
- O arquivo `lib/app/presentation/modules/credit_cards/widgets/credit_cards_content.dart`
  existe no repositorio, mas nao esta referenciado pela tela atual.

## Critérios de aceite praticos

- A escolha de conta continua sendo o primeiro passo.
- O fluxo total nao pede valor extra.
- O fluxo parcial bloqueia valores invalidos antes da confirmacao.
- O sucesso atualiza os dados visiveis sem precisar recarregar a tela manualmente.
