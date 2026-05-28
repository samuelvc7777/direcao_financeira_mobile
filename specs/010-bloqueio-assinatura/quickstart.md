# Quickstart: Bloqueio por assinatura vigente

## Pre-condicoes

- Branch ativa: `010-bloqueio-assinatura`.
- Feature spec em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\specs\010-bloqueio-assinatura\spec.md`.
- Plano em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\specs\010-bloqueio-assinatura\plan.md`.

## Fluxo manual de validacao

1. Entrar no app com usuario sem assinatura.
2. Tocar em uma acao protegida, como criar transacao ou configurar recurso premium.
3. Confirmar que a acao original nao executa e o banner premium aparece.
4. Tocar no CTA do banner e confirmar navegacao para a tela de assinatura.
5. Voltar ao app com usuario com assinatura `CANCELED` e `endDate` futura.
6. Tocar na mesma acao protegida e confirmar que ela executa normalmente.
7. Voltar ao app com assinatura vencida.
8. Confirmar que a acao protegida volta a exibir o banner premium.
9. Confirmar que bottom navigation, sair da conta e ver plano continuam funcionando em todos os estados.

## Comandos de verificacao recomendados

```powershell
flutter test test/domain/services/premium_access_policy_test.dart
flutter test test/presentation/widgets/premium_access_guard_test.dart
flutter test test/settings/settings_controller_test.dart
flutter test test/settings/settings_view_test.dart
flutter analyze
```

## Checagem de escopo admin

Antes de encerrar a implementacao, confirmar no diff que nenhum arquivo do painel admin foi alterado e que o bloqueio ficou restrito ao app mobile. Nesta feature, o esperado e nao tocar rotas ou permissoes administrativas.

## Pontos de atencao

- Nao duplicar regra de status/data em widgets.
- Nao bloquear navegacao principal.
- Nao bloquear o botao de sair.
- Nao bloquear o caminho para assinatura.
- Nao alterar o painel admin.
- Evitar depender apenas de informacao armazenada anteriormente quando houver risco de assinatura vencida.
