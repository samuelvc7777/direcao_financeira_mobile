# Tasks: Banner global de atualizacao

**Input**: Design documents from `/specs/011-banner-atualizacao-global/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/global-update-overlay.md, quickstart.md

**Tests**: A feature altera estado global e UI transversal; por isso inclui testes de controller, widget e regressao da Home.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Flutter app**: `lib/app/...` and `test/...`
- **Global update core**: `lib/app/core/update/`
- **Shared widgets**: `lib/app/presentation/widgets/`
- **Home module**: `lib/app/presentation/modules/home/`
- **Tests**: mirror the affected layer/module as closely as possible

---

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar os arquivos globais de update e os testes sem mexer nas mudancas sujas preexistentes fora da feature.

- [X] T001 Criar o arquivo do controller global em `lib/app/core/update/app_update_controller.dart`
- [X] T002 Criar o arquivo do overlay visual em `lib/app/presentation/widgets/global_update_banner_overlay.dart`
- [X] T003 [P] Criar o arquivo de testes do controller em `test/app/core/update/app_update_controller_test.dart`
- [X] T004 [P] Criar o arquivo de testes do overlay em `test/presentation/widgets/global_update_banner_overlay_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Migrar a responsabilidade de update da Home para uma fundacao global antes das historias ficarem completas.

- [X] T005 Implementar o esqueleto de `AppUpdateController` com dependência de `AppUpdateService` em `lib/app/core/update/app_update_controller.dart`
- [X] T006 Registrar `AppUpdateService` com `PlayStoreUpdateService` em binding global em `lib/app/core/bindings/core_binding.dart`
- [X] T007 Registrar `AppUpdateController` permanente no binding global em `lib/app/core/bindings/core_binding.dart`
- [X] T008 Remover o registro de `AppUpdateService` do `HomeBinding` em `lib/app/presentation/modules/home/home_binding.dart`
- [X] T009 Remover a injecao de `appUpdateService` no construtor do `HomeController` dentro de `lib/app/presentation/modules/home/home_binding.dart`

**Checkpoint**: A dependencia global de update existe fora da Home e as historias podem ser implementadas sem duplicar responsabilidades.

---

## Phase 3: User Story 1 - Avisar sobre nova versao ao abrir o app (Priority: P1) MVP

**Goal**: Ao abrir o app com update disponivel, o usuario ve o overlay global acima de qualquer rota; sem update ou com falha, nada bloqueia o app.

**Independent Test**: Usar fake de `AppUpdateService` para simular update disponivel, sem update e falha; renderizar o app/overlay e confirmar visibilidade global sem depender da Home.

### Tests for User Story 1

- [X] T010 [P] [US1] Testar `checkForUpdate()` com update disponivel, sem update e falha em `test/app/core/update/app_update_controller_test.dart`
- [X] T011 [P] [US1] Testar `shouldShowBanner`, `isCheckingUpdate` e `lastCheckError` em `test/app/core/update/app_update_controller_test.dart`
- [X] T012 [P] [US1] Testar que `GlobalUpdateBannerOverlay` nao renderiza aviso quando `show=false` em `test/presentation/widgets/global_update_banner_overlay_test.dart`
- [X] T013 [P] [US1] Testar que `GlobalUpdateBannerOverlay` renderiza overlay, blur visual, titulo, selo e mensagem quando `show=true` em `test/presentation/widgets/global_update_banner_overlay_test.dart`

### Implementation for User Story 1

- [X] T014 [US1] Implementar `checkForUpdate()`, `isCheckingUpdate`, `isUpdateAvailable`, `isDismissedForSession`, `lastCheckError` e `shouldShowBanner` em `lib/app/core/update/app_update_controller.dart`
- [X] T015 [US1] Disparar verificacao silenciosa no ciclo inicial do `AppUpdateController` em `lib/app/core/update/app_update_controller.dart`
- [X] T016 [US1] Implementar `GlobalUpdateBannerOverlay` com `Stack`, `BackdropFilter`, `SafeArea`, `Center` e `SingleChildScrollView` em `lib/app/presentation/widgets/global_update_banner_overlay.dart`
- [X] T017 [US1] Integrar o overlay no `GetMaterialApp.builder` de forma defensiva em `lib/main.dart`
- [X] T018 [US1] Garantir que o builder renderize apenas o `child` quando `AppUpdateController` ainda nao estiver registrado em `lib/main.dart`

**Checkpoint**: User Story 1 deve exibir o overlay global com update disponivel e manter o app normal sem update, com falha ou antes do controller estar pronto.

---

## Phase 4: User Story 2 - Atualizar pela acao principal do banner (Priority: P2)

**Goal**: O usuario toca em `Atualizar agora` e o app tenta abrir a pagina oficial de atualizacao, mostrando feedback amigavel se falhar.

**Independent Test**: Usar fake de `AppUpdateService` para simular sucesso/falha ao abrir loja e verificar callbacks/feedback sem Play Store real.

### Tests for User Story 2

- [X] T019 [P] [US2] Testar `openStore()` com sucesso e falha do servico em `test/app/core/update/app_update_controller_test.dart`
- [X] T020 [P] [US2] Testar que tocar em `ATUALIZAR AGORA` chama o callback de update em `test/presentation/widgets/global_update_banner_overlay_test.dart`

### Implementation for User Story 2

- [X] T021 [US2] Implementar `openStore()` chamando `AppUpdateService.openStorePage()` e tratando falha em `lib/app/core/update/app_update_controller.dart`
- [X] T022 [US2] Exibir snackbar amigavel quando `openStorePage()` retornar falso ou lancar erro em `lib/app/core/update/app_update_controller.dart`
- [X] T023 [US2] Conectar o callback `onUpdate` do overlay ao `AppUpdateController.openStore()` em `lib/main.dart`

**Checkpoint**: User Stories 1 e 2 devem permitir ver o overlay e acionar a loja com tratamento de erro.

---

## Phase 5: User Story 3 - Cancelar o aviso na sessao atual (Priority: P3)

**Goal**: O usuario toca em `Agora nao`, o overlay some e nao reaparece na mesma sessao durante a navegacao.

**Independent Test**: Simular update disponivel, cancelar no controller/overlay e confirmar que `shouldShowBanner` fica falso ate nova instancia de controller.

### Tests for User Story 3

- [X] T024 [P] [US3] Testar `dismiss()` escondendo o banner na sessao atual em `test/app/core/update/app_update_controller_test.dart`
- [X] T025 [P] [US3] Testar que tocar em `Agora nao` chama o callback de cancelamento em `test/presentation/widgets/global_update_banner_overlay_test.dart`
- [X] T026 [P] [US3] Testar que `forceUpdate=true` oculta a acao secundaria sem ativar bloqueio obrigatorio no MVP em `test/presentation/widgets/global_update_banner_overlay_test.dart`

### Implementation for User Story 3

- [X] T027 [US3] Implementar `dismiss()` atualizando `isDismissedForSession` em `lib/app/core/update/app_update_controller.dart`
- [X] T028 [US3] Conectar o callback `onCancel` do overlay ao `AppUpdateController.dismiss()` em `lib/main.dart`
- [X] T029 [US3] Implementar `forceUpdate` visual apenas como parametro inativo no MVP em `lib/app/presentation/widgets/global_update_banner_overlay.dart`

**Checkpoint**: Todas as historias devem funcionar sem persistir cancelamento e sem ativar update obrigatorio.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Remover duplicidade da Home, ajustar testes existentes e validar arquitetura/responsividade.

- [X] T030 Remover `isUpdateAvailable`, `isCheckingUpdate`, `_checkForAppUpdate()` e `openAppStore()` de `lib/app/presentation/modules/home/home_controller.dart`
- [X] T031 Remover a dependencia `AppUpdateService` do construtor e imports do `HomeController` em `lib/app/presentation/modules/home/home_controller.dart`
- [X] T032 Remover o import e a renderizacao de `UpdateAvailableCard` em `lib/app/presentation/modules/home/home_view.dart`
- [X] T033 Deletar o widget antigo sem uso em `lib/app/presentation/modules/home/widgets/update_available_card.dart`
- [X] T034 Atualizar/remover os testes da Home ligados a `_FakeAppUpdateService`, `isUpdateAvailable` e `openAppStore` em `test/app/presentation/modules/home/home_controller_test.dart`
- [X] T035 Atualizar o contrato de controller que ainda injeta `_FakeAppUpdateService` em `test/presentation/controllers/controller_contract_test.dart`
- [X] T036 [P] Validar responsividade do overlay em viewport estreito e baixa altura em `test/presentation/widgets/global_update_banner_overlay_test.dart`
- [X] T037 Executar `flutter test test/app/core/update/app_update_controller_test.dart` e corrigir falhas nos arquivos da feature
- [X] T038 Executar `flutter test test/presentation/widgets/global_update_banner_overlay_test.dart` e corrigir falhas nos arquivos da feature
- [X] T039 Executar `flutter test test/app/presentation/modules/home/home_controller_test.dart` e corrigir regressões da migração da Home
- [X] T040 Executar `flutter test test/presentation/controllers/controller_contract_test.dart` e corrigir regressões de assinatura do controller
- [X] T041 Executar `flutter analyze` e corrigir avisos/erros nos arquivos alterados pela feature

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencias.
- **Foundational (Phase 2)**: depende do Setup e bloqueia todas as historias.
- **US1 (Phase 3)**: depende da fundacao global e entrega o MVP principal.
- **US2 (Phase 4)**: depende de US1 porque a acao principal vive no overlay ja visivel.
- **US3 (Phase 5)**: depende de US1 porque o cancelamento atua sobre o mesmo estado global.
- **Polish (Phase 6)**: depende das historias implementadas para remover duplicidade com seguranca.

### Within Each User Story

- Testes podem ser escritos antes da implementacao do mesmo comportamento.
- Controller global deve existir antes da integracao no `main.dart`.
- Widget visual deve existir antes do builder conectar callbacks reais.
- Remocao da Home deve ocorrer depois do overlay global estar funcional.

### Parallel Opportunities

- T003 e T004 podem rodar em paralelo apos T001/T002.
- T010 a T013 podem rodar em paralelo porque cobrem arquivos de teste diferentes ou cenarios independentes.
- T019 e T020 podem rodar em paralelo.
- T024 a T026 podem rodar em paralelo.
- T036 pode rodar em paralelo com ajustes de testes da Home desde que `global_update_banner_overlay.dart` ja exista.

---

## Parallel Execution Examples

### US1

```text
Executar em paralelo:
- T010 [US1] controller update disponivel/sem update/falha
- T012 [US1] overlay oculto quando show=false
- T013 [US1] overlay visivel quando show=true
```

### US2

```text
Executar em paralelo:
- T019 [US2] controller openStore sucesso/falha
- T020 [US2] widget chama callback de atualizar
```

### US3

```text
Executar em paralelo:
- T024 [US3] controller dismiss
- T025 [US3] widget chama callback de cancelamento
- T026 [US3] estado visual forceUpdate
```

---

## Implementation Strategy

### MVP First

1. Completar Setup e Foundational.
2. Entregar US1 com controller global, overlay responsivo e builder defensivo.
3. Validar que o app abre sem update, com update e com falha de verificacao.
4. Depois implementar US2 e US3.
5. Remover duplicidade da Home e rodar os testes focados.

### Incremental Delivery

1. Preservar `AppUpdateService` existente.
2. Migrar estado para `AppUpdateController`.
3. Renderizar overlay global sem depender da Home.
4. Conectar acoes `Atualizar agora` e `Agora nao`.
5. Limpar Home e contratos de teste antigos.

---

## Notes

- Nao criar schema remoto nem persistencia local para cancelamento no MVP.
- Nao ativar update obrigatorio; `forceUpdate` e apenas suporte visual futuro.
- Nao adicionar dependencia nova; `in_app_update` e `url_launcher` ja existem.
- O root overlay precisa tolerar controller nao registrado para nao quebrar a inicializacao.
- Preservar mudancas sujas preexistentes em arquivos de premium e `pubspec.yaml`.
