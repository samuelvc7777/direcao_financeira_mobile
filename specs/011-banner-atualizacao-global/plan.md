# Implementation Plan: Banner global de atualizacao

**Branch**: `011-banner-atualizacao-global` | **Date**: 2026-05-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/011-banner-atualizacao-global/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Criar controle global de versao para o app: ao abrir, verificar se existe nova versao disponivel e, quando existir, mostrar um overlay central acima de qualquer rota. A implementacao deve reaproveitar `AppUpdateService`/`PlayStoreUpdateService`, mover o estado de update para um controller global GetX, registrar dependencias em binding global, integrar o overlay defensivamente no `GetMaterialApp.builder` e remover o aviso duplicado da Home.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x
**Primary Dependencies**: Flutter, GetX, in_app_update, url_launcher, flutter_test
**Storage**: N/A para o MVP; cancelamento vale apenas em memoria na sessao atual
**Testing**: flutter_test com testes unitarios de controller e testes de widget para o overlay/card
**Target Platform**: Android no MVP para verificacao pela loja; demais plataformas retornam sem aviso
**Project Type**: mobile-app
**Performance Goals**: verificacao silenciosa sem bloquear startup; overlay sem rebuilds globais desnecessarios; card responsivo sem overflow em telas pequenas
**Constraints**: preservar Clean Architecture e GetX; nao duplicar logica de update; nao adicionar dependencia nova; root overlay deve tolerar controller ainda nao registrado; nao bloquear navegacao; Home nao pode manter aviso duplicado
**Scale/Scope**: mudanca transversal pequena em core/presentation, `main.dart`, Home e testes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Does the plan preserve `presentation`, `domain` and `data` boundaries? **Passa.** A fonte externa continua encapsulada em `AppUpdateService`; o novo controller sera presentation/global state e widgets serao puramente visuais.
- Are `bindings`, `controllers`, `use cases`, `repositories` and `datasources` assigned to the correct layer? **Passa.** A injecao sai do `HomeBinding` e vai para binding global; nao ha novo datasource/repositorio.
- Will GetX remain the source of presentation state where stateful behavior exists? **Passa.** O estado `isCheckingUpdate`, `isUpdateAvailable` e `isDismissedForSession` ficara em `AppUpdateController`.
- Are views/pages restricted to macro structure while visual composition is extracted into smaller widgets? **Passa.** `main.dart` apenas envolve o child; a composicao visual fica em `GlobalUpdateBannerOverlay`/card separado.
- Are business rules isolated from views, widgets, bindings and controllers? **Passa com ressalva controlada.** A regra de disponibilidade continua no servico existente; o controller apenas coordena estado de apresentacao e acoes do usuario.
- Does the feature include a testing strategy compatible with the touched layers? **Passa.** Havera testes do controller, do overlay/card e ajuste dos testes da Home.
- Does the feature preserve responsiveness for the affected screens? **Passa.** O contrato visual exige largura maxima, `SafeArea`, rolagem e validacao em tela pequena/baixa altura.

## Project Structure

### Documentation (this feature)

```text
specs/011-banner-atualizacao-global/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- global-update-overlay.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md
```

### Source Code (repository root)

```text
lib/
|-- main.dart
`-- app/
    |-- core/
    |   |-- bindings/
    |   |   |-- app_binding.dart
    |   |   `-- core_binding.dart
    |   `-- update/
    |       |-- app_update_controller.dart
    |       `-- play_store_update_service.dart
    `-- presentation/
        |-- modules/
        |   `-- home/
        |       |-- home_binding.dart
        |       |-- home_controller.dart
        |       |-- home_view.dart
        |       `-- widgets/
        |           `-- update_available_card.dart
        `-- widgets/
            `-- global_update_banner_overlay.dart

test/
|-- app/
|   |-- core/
|   |   `-- update/
|   |       `-- app_update_controller_test.dart
|   `-- presentation/
|       `-- modules/
|           `-- home/
|               `-- home_controller_test.dart
`-- presentation/
    `-- widgets/
        `-- global_update_banner_overlay_test.dart
```

**Structure Decision**: Criar o controller em `lib/app/core/update/` junto ao servico existente porque o estado e global do app, nao da Home. Criar o widget em `lib/app/presentation/widgets/` porque o overlay e visual e compartilhado por todas as rotas. Manter `main.dart` apenas como ponto de composicao macro do app.

## Layer Responsibilities

### Presentation

- `AppUpdateController` expoe estado observavel global e traduz eventos `Atualizar`/`Cancelar`.
- `GlobalUpdateBannerOverlay` recebe `show`, `child`, `onUpdate`, `onCancel`, `forceUpdate` futuro e `badgeText`, renderizando somente UI.
- `GetMaterialApp.builder` envolve o child da rota em um widget defensivo que so observa o controller quando ele estiver registrado.
- `HomeView` deixa de renderizar `UpdateAvailableCard`.
- `HomeController` deixa de verificar update e abrir loja.

### Domain

- Nao ha nova entidade de negocio persistida no MVP.
- A decisao de update obrigatorio fica fora do MVP e nao deve criar regra de negocio ativa agora.

### Data

- `PlayStoreUpdateService` permanece como adaptador para disponibilidade de update e abertura da loja.
- Nenhum novo schema, datasource remoto ou persistencia local.

## Testing Strategy

### Domain Tests

- Nao aplicavel no MVP porque nao ha nova regra de negocio de dominio.

### Data Tests

- Nao criar teste de Play Store real. O servico existente deve continuar mockavel via contrato `AppUpdateService`.

### Presentation Tests

- Testar `AppUpdateController` com fake de `AppUpdateService`: update disponivel, sem update, falha de verificacao, cancelar sessao, abrir loja com sucesso e falha.
- Testar `GlobalUpdateBannerOverlay`: nao renderiza quando `show=false`; renderiza textos e botoes quando `show=true`; `Atualizar` e `Agora nao` disparam callbacks; `forceUpdate=true` oculta a acao secundaria; layout nao gera overflow em viewport pequeno.
- Ajustar/remover testes da Home que validavam `isUpdateAvailable`/`openAppStore` no `HomeController`.
- Testar que Home nao renderiza mais `UpdateAvailableCard` ou remover o widget antigo se ficar sem uso.

## Responsiveness Strategy

- Overlay deve usar `Positioned.fill`, `SafeArea`, `Center` e `SingleChildScrollView` para telas de baixa altura.
- Card deve ter largura maxima de aproximadamente 430px e padding adaptavel para telas estreitas.
- Textos longos devem quebrar linha, sem escala por largura de viewport.
- Botoes devem manter altura minima tocavel e largura total no mobile.
- O visual aprovado deve ser compactado quando necessario: reduzir paddings/raios em telas menores, preservar hierarquia e evitar overflow horizontal.

## Phase 0: Research Summary

As decisoes estao registradas em [research.md](./research.md). Nao restaram `NEEDS CLARIFICATION`.

## Phase 1: Design Summary

- Estado documentado em [data-model.md](./data-model.md).
- Contrato visual/comportamental documentado em [contracts/global-update-overlay.md](./contracts/global-update-overlay.md).
- Validacao manual e automatizada documentada em [quickstart.md](./quickstart.md).

## Constitution Check - Post-Design

- Camadas preservadas: **sim**.
- GetX como fonte de estado de presentation: **sim**.
- Composicao visual extraida da macro view: **sim**.
- Regras de negocio fora da UI: **sim**, sem nova regra de dominio no MVP.
- Testes por camada afetada: **sim**, presentation/controller e widget.
- Responsividade contemplada: **sim**, por contrato e quickstart.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
