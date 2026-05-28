# Tasks: Bloqueio por assinatura vigente

**Input**: Design documents from `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\specs\010-bloqueio-assinatura\`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Esta feature exige testes porque altera regra de acesso premium, interceptacao de cliques e regressao de navegacao/logout/ver plano.

**Organization**: Tasks agrupadas por historia para permitir implementacao e validacao incremental.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo com outras tarefas de arquivos diferentes
- **[Story]**: Historia de usuario correspondente
- Todas as tarefas incluem caminho de arquivo real ou previsto no repositorio

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar estrutura compartilhada sem mexer em comportamento ainda.

- [X] T001 Revisar os pontos de entrada protegidos atuais em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\home\home_controller.dart`, `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\transactions\transactions_view.dart`, `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\journey\journey_view.dart` e `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\settings\settings_controller.dart`
- [X] T002 Criar a estrutura de testes de dominio em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\domain\services\premium_access_policy_test.dart`
- [X] T003 [P] Criar a estrutura de testes de presentation em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`
- [X] T004 [P] Criar arquivo visual compartilhado para o banner em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_banner.dart`
- [X] T005 [P] Criar arquivo compartilhado da guarda em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Criar a decisao de acesso reutilizavel antes de aplicar nas telas.

- [X] T006 [P] Adicionar testes para assinatura ausente, vencida, status sem acesso e assinatura vigente em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\domain\services\premium_access_policy_test.dart`
- [X] T007 [P] Adicionar testes para `CANCELED` com `endDate` futura e `CANCELED` com `endDate` vencida em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\domain\services\premium_access_policy_test.dart`
- [X] T008 Implementar `PremiumAccessPolicy` e o modelo de decisao de acesso em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\domain\services\premium_access_policy.dart`
- [X] T009 Conectar `PremiumAccessPolicy` a `SubscriptionEntity.grantsAccess` sem duplicar regra de status/data em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\domain\services\premium_access_policy.dart`
- [X] T010 Registrar `PremiumAccessPolicy` como dependencia compartilhada em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\core\bindings\core_binding.dart`
- [X] T011 Adicionar teste de contrato para preservar `SubscriptionEntity.grantsAccess` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\domain\entities\subscription_entity_test.dart`

**Checkpoint**: A regra de acesso premium esta centralizada e testada antes de qualquer alteracao visual.

---

## Phase 3: User Story 1 - Bloquear acoes sem assinatura vigente (Priority: P1) MVP

**Goal**: Usuario sem assinatura ou com assinatura vencida nao executa a acao protegida e ve o banner premium.

**Independent Test**: Simular acesso bloqueado, tocar em uma acao protegida e confirmar que o callback original nao roda e o banner aparece.

### Tests for User Story 1

- [X] T012 [P] [US1] Adicionar teste da guarda bloqueando callback protegido quando nao ha assinatura em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`
- [X] T013 [P] [US1] Adicionar teste da guarda bloqueando callback protegido quando assinatura esta vencida em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`
- [X] T014 [P] [US1] Adicionar teste para o CTA do banner navegar para `AppRoutes.subscription` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`

### Implementation for User Story 1

- [X] T015 [US1] Implementar o fluxo de decisao da guarda em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`
- [X] T016 [US1] Implementar abertura do banner bloqueante sem executar callback original em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`
- [X] T017 [P] [US1] Criar composicao inicial do banner premium com titulo, explicacao, beneficios e CTA em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_banner.dart`
- [X] T018 [US1] Aplicar a guarda nas acoes de adicionar/editar transacoes em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\transactions\transactions_view.dart`
- [X] T019 [US1] Aplicar a guarda nos comandos financeiros protegidos da Home em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\home\home_view.dart`
- [X] T020 [US1] Aplicar a guarda nas acoes protegidas da jornada em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\journey\journey_view.dart`

**Checkpoint**: MVP pronto; usuario bloqueado nao executa acoes protegidas e recebe banner com caminho para assinatura.

---

## Phase 4: User Story 2 - Permitir uso durante periodo vigente apos cancelamento (Priority: P1)

**Goal**: Usuario cancelado, mas ainda dentro do periodo pago, continua usando acoes protegidas normalmente.

**Independent Test**: Simular assinatura `CANCELED` com `endDate` futura e confirmar que a guarda executa a acao original.

### Tests for User Story 2

- [X] T021 [P] [US2] Adicionar teste da guarda executando callback com assinatura `CANCELED` vigente em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`
- [X] T022 [P] [US2] Adicionar teste de regressao para `SubscriptionEntity.grantsAccess` liberar `CANCELED` vigente em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\domain\entities\subscription_entity_test.dart`

### Implementation for User Story 2

- [X] T023 [US2] Garantir que `PremiumAccessPolicy` trate `CANCELED` vigente como acesso permitido em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\domain\services\premium_access_policy.dart`
- [X] T024 [US2] Garantir que `PremiumAccessGuard` execute callback original sem exibir banner quando acesso estiver permitido em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`

**Checkpoint**: Cancelamento dentro do periodo nao bloqueia o usuario.

---

## Phase 5: User Story 3 - Manter navegacao e saida acessiveis (Priority: P2)

**Goal**: Usuario bloqueado continua podendo navegar, sair da conta e abrir a tela de assinatura.

**Independent Test**: Simular usuario bloqueado e confirmar que bottom navigation, logout e Ver plano continuam funcionando.

### Tests for User Story 3

- [X] T025 [P] [US3] Adicionar teste de bottom navigation liberada com usuario bloqueado em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\modules\initial\initial_view_test.dart`
- [X] T026 [P] [US3] Atualizar teste do CTA Ver plano para permanecer liberado com usuario sem assinatura em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\settings\settings_view_test.dart`
- [X] T027 [P] [US3] Atualizar teste de logout para permanecer livre da guarda em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\settings\settings_controller_test.dart`

### Implementation for User Story 3

- [X] T028 [US3] Preservar `InitialController.changeTab` sem bloqueio em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\initial\initial_controller.dart`
- [X] T029 [US3] Preservar `SettingsController.openSubscription` sem guarda premium em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\settings\settings_controller.dart`
- [X] T030 [US3] Preservar `SettingsController.logout` sem guarda premium em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\modules\settings\settings_controller.dart`

**Checkpoint**: O bloqueio nao prende o usuario e nao impede assinatura ou saida da conta.

---

## Phase 6: User Story 4 - Preservar operacoes administrativas (Priority: P2)

**Goal**: Garantir que o escopo da implementacao fique restrito ao app mobile e nao altere painel admin.

**Independent Test**: Conferir que nenhuma mudanca toca codigo do painel admin e que o bloqueio fica em arquivos do app mobile.

### Tests for User Story 4

- [X] T031 [P] [US4] Registrar uma checagem de escopo admin no quickstart em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\specs\010-bloqueio-assinatura\quickstart.md`

### Implementation for User Story 4

- [X] T032 [US4] Verificar que a implementacao nao adiciona dependencia de painel admin em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\domain\services\premium_access_policy.dart`
- [X] T033 [US4] Verificar que a implementacao nao altera rotas ou permissoes administrativas em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\routes\app_pages.dart`

**Checkpoint**: Painel admin permanece fora da feature e sem bloqueio visual do app mobile.

---

## Phase 7: User Story 5 - Comunicar o bloqueio com banner premium consistente (Priority: P2)

**Goal**: Banner premium fica visualmente consistente com a referencia, legivel e sem duplicacao.

**Independent Test**: Abrir banner em tela compacta e confirmar titulo, beneficios, CTA, contraste e ausencia de overflow.

### Tests for User Story 5

- [X] T034 [P] [US5] Adicionar teste de renderizacao do banner com selo, titulo, beneficios e CTA em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_banner_test.dart`
- [X] T035 [P] [US5] Adicionar teste responsivo do banner em largura compacta em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_banner_test.dart`
- [X] T036 [P] [US5] Adicionar teste para impedir banners duplicados em toque repetido em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\test\presentation\widgets\premium_access_guard_test.dart`

### Implementation for User Story 5

- [X] T037 [US5] Refinar estilo escuro/dourado, selo premium e CTA destacado em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_banner.dart`
- [X] T038 [US5] Implementar layout responsivo e sem overflow no banner em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_banner.dart`
- [X] T039 [US5] Implementar controle anti-duplicacao de banner em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`

**Checkpoint**: Banner premium comunica o bloqueio de forma clara, responsiva e sem empilhamento.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Validar cobertura, arquitetura e fluxos principais antes de implementar/encerrar.

- [X] T040 [P] Rodar e corrigir `flutter test test\domain\services\premium_access_policy_test.dart` no workspace `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [X] T041 [P] Rodar e corrigir `flutter test test\domain\entities\subscription_entity_test.dart` no workspace `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [X] T042 [P] Rodar e corrigir `flutter test test\presentation\widgets\premium_access_guard_test.dart test\presentation\widgets\premium_access_banner_test.dart` no workspace `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [X] T043 [P] Rodar e corrigir `flutter test test\settings\settings_controller_test.dart test\settings\settings_view_test.dart` no workspace `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [X] T044 Rodar e corrigir `flutter analyze` no workspace `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [X] T045 Revisar responsabilidades de view/widget/controller/domain nos arquivos `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_guard.dart`, `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\presentation\widgets\premium_access_banner.dart` e `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\lib\app\domain\services\premium_access_policy.dart`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencia.
- **Foundational (Phase 2)**: depende do Setup e bloqueia as historias.
- **US1 e US2 (Phase 3 e 4)**: dependem da base; juntas formam o MVP correto de bloqueio e liberacao por periodo vigente.
- **US3, US4 e US5 (Phase 5 a 7)**: dependem da base e podem ser trabalhadas apos US1 sem alterar a regra central.
- **Polish (Phase 8)**: depende das historias implementadas.

### Story Dependencies

- **US1**: primeira entrega funcional de bloqueio.
- **US2**: depende da mesma guarda da US1 e valida a excecao de cancelamento vigente.
- **US3**: depende da guarda existir para garantir que excecoes nao sejam envolvidas por ela.
- **US4**: independente de codigo admin; valida escopo.
- **US5**: depende do banner/guarda da US1 e aprofunda visual/responsividade.

### Parallel Opportunities

- T002, T003, T004 e T005 podem rodar em paralelo.
- T006 e T007 podem rodar em paralelo por cobrirem cenarios diferentes do mesmo contrato.
- T012, T013 e T014 podem rodar em paralelo antes de T015.
- T025, T026 e T027 podem rodar em paralelo.
- T034, T035 e T036 podem rodar em paralelo.
- T040, T041, T042 e T043 podem rodar em paralelo apos implementacao.

---

## Implementation Strategy

### MVP First

1. Completar Phase 1 e Phase 2.
2. Implementar US1 para bloquear usuario sem assinatura/vencido.
3. Implementar US2 antes de considerar o MVP fechado, para garantir que cancelamento vigente nao seja bloqueado.
4. Validar testes de dominio e guarda.

### Incremental Delivery

1. Centralizar regra no dominio.
2. Aplicar guarda em um conjunto inicial de acoes protegidas.
3. Confirmar excecoes de navegacao, logout e ver plano.
4. Refinar banner e responsividade.
5. Rodar testes focados e `flutter analyze`.

---

## Notes

- Nao duplicar comparacoes de status/data em views ou controllers.
- Nao bloquear bottom navigation, logout nem ver plano/ver assinatura.
- Nao alterar painel admin.
- Se alguma acao protegida estiver em outro arquivo durante a implementacao, adicionar tarefa local antes de mexer para manter rastreabilidade.
