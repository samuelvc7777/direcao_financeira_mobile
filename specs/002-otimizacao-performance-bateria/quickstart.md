# Quickstart: Otimizacao de performance e bateria

## Preconditions

- Trabalhar a partir de `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`.
- Conferir alteracoes pendentes antes de editar, porque o worktree ja possui muitas modificacoes.
- Priorizar mudancas pequenas e verificaveis.

## Suggested Implementation Order

1. Ajustar `_buildLocationSettings()` em `lib/app/core/location/location_tracking_service.dart`.
2. Adicionar teste unitario ou de contrato simples para garantir que a politica de localizacao nao volte para deslocamento zero.
3. Refatorar `lib/app/presentation/modules/journey/widgets/rides_list_section.dart` para `CustomScrollView` + `SliverList.builder` ou estrutura lazy equivalente.
4. Refatorar `lib/app/presentation/modules/journey/widgets/shift_history_section.dart` com a mesma estrategia.
5. Rodar testes de journey/presentation existentes.
6. Auditar `categories_view.dart`, `bank_accounts_content.dart` e `credit_cards_content.dart` para decidir se a lista interna precisa builder.
7. Validar OCR com imagens grandes antes de adicionar nova dependencia de compressao.
8. Revisar ciclo de vida de realtime/background apenas com evidencia objetiva.

## Verification Commands

```powershell
flutter test
flutter test test/app/presentation/modules/journey/import_ride_photo_controller_test.dart
flutter analyze
```

Se o ambiente local nao estiver com Flutter disponivel, registrar explicitamente que os testes nao foram executados.
