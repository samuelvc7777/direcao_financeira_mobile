# Tasks: Tela de metas

**Input**: Design documents from `/specs/006-tela-metas/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Esta feature altera backend, data/domain/presentation no mobile e comportamento visivel da Home/Settings. Testes automatizados sao parte da entrega.

**Organization**: Tasks agrupadas por historia para permitir implementacao incremental e verificacao independente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo quando nao tocar os mesmos arquivos nem depender de tarefa incompleta.
- **[Story]**: Historia vinculada somente nas fases de user story.
- Todas as tarefas apontam caminhos reais do repo.

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar estrutura e pontos de integracao sem implementar comportamento final.

- [ ] T001 Criar estrutura do modulo de presentation em `lib/app/presentation/modules/goals/` e `lib/app/presentation/modules/goals/widgets/`
- [ ] T002 [P] Criar estrutura espelhada de testes em `test/app/presentation/modules/goals/`
- [ ] T003 [P] Criar migration vazia para Goals em `../direcao_financeira_backend/prisma/migrations/[timestamp]_add_goals/migration.sql`
- [ ] T004 [P] Criar arquivos base mobile de Goal em `lib/app/domain/entities/goal_entity.dart`, `lib/app/domain/repositories/i_goal_repository.dart`, `lib/app/domain/usecases/goal_use_cases.dart`, `lib/app/data/datasources/goal_datasource.dart`, `lib/app/data/models/goal_model.dart`, `lib/app/data/repositories/goal_repository.dart`
- [ ] T005 [P] Criar arquivos base dos providers em `lib/app/data/providers/nest/finance/nest_goal_remote_datasource.dart` e `lib/app/data/providers/supabase/finance/supabase_goal_remote_datasource.dart`
- [ ] T006 [P] Criar arquivos base backend em `../direcao_financeira_backend/src/modules/finance/interface/dto/create-goal.dto.ts` e `../direcao_financeira_backend/src/modules/finance/interface/dto/update-goal.dto.ts`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Criar contrato de dados compartilhado que bloqueia todas as historias.

- [ ] T007 Atualizar Prisma com enum `GoalStatus`, relacao `User.goals` e model `Goal` em `../direcao_financeira_backend/prisma/schema.prisma`
- [ ] T008 Atualizar migration SQL de Goals com tabela, indices e foreign key em `../direcao_financeira_backend/prisma/migrations/[timestamp]_add_goals/migration.sql`
- [ ] T009 [P] Implementar DTOs e validacoes de Goal em `../direcao_financeira_backend/src/modules/finance/interface/dto/create-goal.dto.ts` e `../direcao_financeira_backend/src/modules/finance/interface/dto/update-goal.dto.ts`
- [ ] T010 Atualizar contrato `FinanceRepository` com tipos e metodos de Goal em `../direcao_financeira_backend/src/modules/finance/domain/repositories/finance.repository.ts`
- [ ] T011 Implementar persistencia Prisma de Goal em `../direcao_financeira_backend/src/modules/finance/infrastructure/repositories/prisma-finance.repository.ts`
- [ ] T012 Implementar regras backend de ownership/status/validacao em `../direcao_financeira_backend/src/modules/finance/interface/finance.service.ts`
- [ ] T013 Expor endpoints `/finance/goals` em `../direcao_financeira_backend/src/modules/finance/interface/finance.controller.ts`
- [ ] T014 [P] Implementar `GoalEntity` e `GoalStatus` com progresso derivado em `lib/app/domain/entities/goal_entity.dart`
- [ ] T015 [P] Implementar contrato `IGoalRepository` em `lib/app/domain/repositories/i_goal_repository.dart`
- [ ] T016 [P] Implementar use cases de Goal em `lib/app/domain/usecases/goal_use_cases.dart`
- [ ] T017 [P] Implementar `GoalModel` com parsing de status, datas e centavos em `lib/app/data/models/goal_model.dart`
- [ ] T018 [P] Implementar `IGoalDataSource` em `lib/app/data/datasources/goal_datasource.dart`
- [ ] T019 Implementar `GoalRepository` com `Either<Failure, ...>` em `lib/app/data/repositories/goal_repository.dart`
- [ ] T020 Atualizar tabela `Goal` em `lib/app/data/providers/supabase/shared/supabase_table_names.dart`
- [ ] T021 Implementar datasource Nest para `/finance/goals` em `lib/app/data/providers/nest/finance/nest_goal_remote_datasource.dart`
- [ ] T022 Implementar datasource Supabase escopado por usuario em `lib/app/data/providers/supabase/finance/supabase_goal_remote_datasource.dart`
- [ ] T023 Registrar `IGoalDataSource` e `IGoalRepository` nos providers Nest e Supabase em `lib/app/core/bindings/provider_binding.dart`
- [ ] T024 [P] Adicionar testes de dominio para progresso e validacoes em `test/app/domain/entities/goal_entity_test.dart`
- [ ] T025 [P] Adicionar testes de use cases em `test/app/domain/usecases/goal_use_cases_test.dart`
- [ ] T026 [P] Adicionar testes de repository/model em `test/app/data/repositories/goal_repository_test.dart`
- [ ] T027 [P] Adicionar testes do datasource Supabase em `test/app/data/providers/supabase/finance/supabase_goal_remote_datasource_test.dart`
- [ ] T028 [P] Adicionar testes backend de service/controller para Goal em `../direcao_financeira_backend/src/modules/finance/interface/finance.service.spec.ts` ou `../direcao_financeira_backend/test/finance.contract.e2e-spec.ts`

**Checkpoint**: Backend e mobile conhecem `Goal` de ponta a ponta, mas a UI ainda nao precisa estar pronta.

---

## Phase 3: User Story 1 - Abrir e acompanhar metas (Priority: P1) MVP

**Goal**: Abrir uma tela real pelo item "Configurar Metas" e listar metas com loading, vazio, erro e sucesso.

**Independent Test**: Abrir Settings, tocar em "Configurar Metas" e ver a tela real carregando Goals ou estado vazio/erro sem placeholder.

### Tests for User Story 1

- [ ] T029 [P] [US1] Adicionar testes do `GoalsController` para load success, empty e error em `test/app/presentation/modules/goals/goals_controller_test.dart`
- [ ] T030 [P] [US1] Atualizar teste de Settings para rota de metas em `test/settings/settings_controller_test.dart`

### Implementation for User Story 1

- [ ] T031 [US1] Criar `GoalsBinding` registrando use cases e controller em `lib/app/presentation/modules/goals/goals_binding.dart`
- [ ] T032 [US1] Criar `GoalsController` com loading, error, goals, active/completed/archived getters e `loadGoals()` em `lib/app/presentation/modules/goals/goals_controller.dart`
- [ ] T033 [US1] Criar `GoalsView` como estrutura macro com loading/empty/error/success em `lib/app/presentation/modules/goals/goals_view.dart`
- [ ] T034 [P] [US1] Criar widgets de estado em `lib/app/presentation/modules/goals/widgets/goals_empty_state.dart` e `lib/app/presentation/modules/goals/widgets/goals_error_state.dart`
- [ ] T035 [P] [US1] Criar widgets de lista/resumo em `lib/app/presentation/modules/goals/widgets/goals_content.dart`, `lib/app/presentation/modules/goals/widgets/goals_summary_header.dart` e `lib/app/presentation/modules/goals/widgets/goal_card.dart`
- [ ] T036 [US1] Registrar `AppRoutes.goals` e `GetPage` em `lib/app/routes/app_pages.dart`
- [ ] T037 [US1] Atualizar `SettingsController.openSettingItem` para abrir `AppRoutes.goals` quando o item for "Configurar Metas" em `lib/app/presentation/modules/settings/settings_controller.dart`

**Checkpoint**: US1 funcional e testavel: tela abre e acompanha metas existentes ou vazio sem placeholder.

---

## Phase 4: User Story 2 - Criar e editar uma meta (Priority: P2)

**Goal**: Permitir criar e editar Goals com nome, objetivo, valor atual, descricao opcional e data alvo opcional.

**Independent Test**: Criar uma meta valida, editar nome/valores e ver progresso recalculado na lista.

### Tests for User Story 2

- [ ] T038 [P] [US2] Adicionar testes do `GoalsController` para create/update e validacoes em `test/app/presentation/modules/goals/goals_controller_test.dart`
- [ ] T039 [P] [US2] Adicionar testes de datasource Nest para payload create/update em `test/app/data/providers/nest/finance/nest_goal_remote_datasource_test.dart`

### Implementation for User Story 2

- [ ] T040 [US2] Implementar `createGoal` e `updateGoal` no `GoalsController` em `lib/app/presentation/modules/goals/goals_controller.dart`
- [ ] T041 [US2] Criar formulario bottom sheet em `lib/app/presentation/modules/goals/widgets/goal_form_sheet.dart`
- [ ] T042 [US2] Conectar FAB e edicao de card ao `GoalFormSheet` em `lib/app/presentation/modules/goals/goals_view.dart` e `lib/app/presentation/modules/goals/widgets/goal_card.dart`
- [ ] T043 [US2] Aplicar mascaras/parse seguro de moeda no formulario em `lib/app/presentation/modules/goals/widgets/goal_form_sheet.dart`
- [ ] T044 [US2] Solicitar refresh do dashboard apos create/update em `lib/app/presentation/modules/goals/goals_controller.dart`

**Checkpoint**: US1 e US2 funcionam com tela real, formulario, persistencia e progresso recalculado.

---

## Phase 5: User Story 3 - Concluir, pausar ou remover metas (Priority: P3)

**Goal**: Permitir concluir e arquivar metas, diferenciando status na tela.

**Independent Test**: Marcar uma meta como concluida, arquivar uma meta e observar listas/totais coerentes.

### Tests for User Story 3

- [ ] T045 [P] [US3] Adicionar testes do `GoalsController` para complete/archive em `test/app/presentation/modules/goals/goals_controller_test.dart`
- [ ] T046 [P] [US3] Adicionar cobertura backend para complete/archive em `../direcao_financeira_backend/test/finance.contract.e2e-spec.ts`

### Implementation for User Story 3

- [ ] T047 [US3] Implementar `completeGoal` e `archiveGoal` no `GoalsController` em `lib/app/presentation/modules/goals/goals_controller.dart`
- [ ] T048 [US3] Adicionar acoes de concluir/arquivar no card ou menu em `lib/app/presentation/modules/goals/widgets/goal_card.dart`
- [ ] T049 [US3] Diferenciar secoes de metas ativas, concluidas e arquivadas em `lib/app/presentation/modules/goals/widgets/goals_content.dart`
- [ ] T050 [US3] Garantir feedback e confirmacao para arquivamento em `lib/app/presentation/modules/goals/goals_controller.dart`

**Checkpoint**: US3 funcional com ciclo de vida basico de Goal sem exclusao fisica indevida.

---

## Phase 6: User Story 4 - Refletir metas no resumo da Home (Priority: P4)

**Goal**: Remover mock de metas da Home e mostrar Goals reais ou vazio honesto.

**Independent Test**: Alterar metas na tela Goals, voltar para Home e ver resumo real; sem Goals, a Home nao mostra "Pagar contas" mockado.

### Tests for User Story 4

- [ ] T051 [P] [US4] Atualizar testes do `HomeController` para Goals reais e lista vazia em `test/app/presentation/modules/home/home_controller_test.dart`
- [ ] T052 [P] [US4] Atualizar testes de widget/controller da Home quando existirem em `test/presentation/controllers/controller_contract_test.dart`

### Implementation for User Story 4

- [ ] T053 [US4] Registrar `LoadGoalsUseCase` no `HomeBinding` em `lib/app/presentation/modules/home/home_binding.dart`
- [ ] T054 [US4] Substituir lista mock `metas` por Goals reais no `HomeController` em `lib/app/presentation/modules/home/home_controller.dart`
- [ ] T055 [US4] Atualizar `GoalsSection` para receber/exibir `GoalEntity` e estado vazio sem mock em `lib/app/presentation/modules/home/widgets/goals_section.dart`
- [ ] T056 [US4] Conectar botao "Gerenciar" da Home a `AppRoutes.goals` em `lib/app/presentation/modules/home/widgets/goals_section.dart` ou `lib/app/presentation/modules/home/home_controller.dart`
- [ ] T057 [US4] Garantir `DashboardRefreshNotifier` apos mutacoes de Goals em `lib/app/presentation/modules/goals/goals_controller.dart`

**Checkpoint**: Home reflete Goals reais e nao exibe dados demonstrativos.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Validar arquitetura, responsividade, testes e acabamento.

- [ ] T058 [P] Revisar responsividade e textos longos da tela Goals em `lib/app/presentation/modules/goals/goals_view.dart` e `lib/app/presentation/modules/goals/widgets/`
- [ ] T059 [P] Revisar separacao page/view/widgets para manter `GoalsView` como macroestrutura em `lib/app/presentation/modules/goals/`
- [ ] T060 [P] Revisar registros de DI para evitar duplicidade entre `ProviderBinding`, `GoalsBinding` e `HomeBinding` em `lib/app/core/bindings/provider_binding.dart`, `lib/app/presentation/modules/goals/goals_binding.dart` e `lib/app/presentation/modules/home/home_binding.dart`
- [ ] T061 Executar `flutter analyze` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [ ] T062 Executar `flutter test` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile`
- [ ] T063 Executar `npm run test` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_backend`
- [ ] T064 Executar `npm run build` em `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_backend`
- [ ] T065 Atualizar checklists da feature marcando itens resolvidos em `specs/006-tela-metas/checklists/architecture.md`, `specs/006-tela-metas/checklists/data-contract.md` e `specs/006-tela-metas/checklists/requirements.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencias.
- **Foundational (Phase 2)**: depende da estrutura da Phase 1 e bloqueia todas as historias.
- **US1 (Phase 3)**: depende da Phase 2; entrega MVP navegavel/listavel.
- **US2 (Phase 4)**: depende da US1 para reutilizar tela/controller.
- **US3 (Phase 5)**: depende da US1 e dos contratos foundational; pode iniciar apos metodos de status existirem no backend/data.
- **US4 (Phase 6)**: depende da US1 para carregar Goals e fica melhor apos US2/US3 para validar refresh real.
- **Polish (Phase 7)**: depende das historias planejadas.

### Story Dependency Graph

```text
Phase 1 -> Phase 2 -> US1 -> US2 -> US3 -> US4 -> Polish
                       |       |
                       |       `-> US4 pode validar create/update reais
                       `-> US3 pode iniciar apos contratos de status
```

### Parallel Opportunities

- T002, T003, T004, T005 e T006 podem rodar em paralelo.
- T014, T015, T016, T017 e T018 podem rodar em paralelo apos schema/contratos definidos.
- T024, T025, T026, T027 e T028 podem rodar em paralelo com implementacoes de suas camadas.
- T034 e T035 podem rodar em paralelo apos `GoalsView` ter contrato de estado definido.
- T038 e T039 podem rodar em paralelo.
- T045 e T046 podem rodar em paralelo.
- T051 e T052 podem rodar em paralelo.
- T058, T059 e T060 podem rodar em paralelo antes das validacoes finais.

---

## Implementation Strategy

### MVP First

1. Completar Phase 1 e Phase 2.
2. Entregar US1 para substituir o placeholder por tela real com listagem/empty/error.
3. Validar com testes de Goal domain/data/controller e rota Settings.

### Incremental Delivery

1. US2 adiciona create/update sem alterar a base arquitetural.
2. US3 adiciona ciclo de vida com status.
3. US4 remove mock da Home e conecta resumo real.
4. Polish roda analise, testes mobile e testes/build backend.

### Quality Gates

- Nenhum controller deve acessar datasource diretamente.
- Nenhum widget deve calcular regra financeira central de progresso alem de exibir valores prontos da entidade.
- `CostsGainsSettings` nao deve ser fonte da tela "Minhas Metas".
- A Home nao pode manter meta mockada quando nao houver Goals reais.
