# Tasks: Importacao de entradas por corridas

**Input**: Design documents from `/specs/001-importar-entradas-corridas/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: O fluxo tem caminho real de cobertura automatizada em domain, data e presentation, entao as tarefas incluem testes por camada.

**Organization**: Tasks grouped by user story to keep the slice independente e testavel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar os pontos de extensao no modulo existente sem quebrar a arquitetura.

- [x] T001 Mapear os pontos de entrada e dependencias atuais da feature em `lib/app/presentation/modules/transactions/transactions_binding.dart`, `lib/app/presentation/modules/transactions/transactions_controller.dart` e `lib/app/presentation/modules/transactions/views/transaction_form_view.dart`
- [x] T002 [P] Criar o esqueleto de arquivos novos para a importacao em `lib/app/presentation/modules/transactions/widgets/` com nomes coerentes ao consolidado, dialog e estado vazio
- [x] T003 [P] Criar os contratos iniciais de dominio para a importacao em `lib/app/domain/repositories/i_transaction_repository.dart` e `lib/app/domain/usecases/transaction_use_cases.dart`
- [x] T004 [P] Preparar a cobertura base de testes nas pastas `test/domain/`, `test/data/repositories/` e `test/presentation/controllers/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Construir a base de dominio e contratos que todas as historias vao reutilizar.

- [x] T005 Definir as entidades de importacao e a sessao de conciliacao em `lib/app/domain/entities/` com foco em corrida importavel, grupo por forma de pagamento e distribuicao por conta
- [x] T006 [P] Criar ou atualizar os use cases de consolidacao, elegibilidade e confirmacao em `lib/app/domain/usecases/transaction_use_cases.dart`
- [x] T007 [P] Expandir o contrato de corridas elegiveis em `lib/app/domain/repositories/i_ride_repository.dart` para suportar o fluxo de importacao
- [x] T008 [P] Expandir o contrato de transacoes em `lib/app/domain/repositories/i_transaction_repository.dart` para registrar o resultado da importacao como multiplas entradas coerentes
- [x] T009 Atualizar a implementacao de repositorio de transacoes em `lib/app/data/repositories/transaction_repository.dart` para suportar o novo contrato sem vazar regra para presentation
- [x] T010 Atualizar a implementacao de repositorio de corridas em `lib/app/data/repositories/ride_repository_impl.dart` para aplicar filtro de elegibilidade e bloquear corridas ja importadas

**Checkpoint**: a base de dominio e os contratos principais estao prontos para receber cada historia de forma independente.

---

## Phase 3: User Story 1 - Importar corridas para montar a entrada (Priority: P1) MVP

**Goal**: Permitir que o usuario abra a nova entrada, consulte `Corridas feitas hoje` e veja um consolidado inicial por forma de pagamento com detalhes expansivos.

**Independent Test**: Abrir a tela de nova transacao em modo entrada, acionar `Corridas feitas hoje` e verificar consolidado, detalhes e exclusao de corridas ja usadas.

### Tests for User Story 1

- [x] T011 [P] [US1] Criar testes de elegibilidade e consolidacao de corridas em `test/domain/entities/ride_import_batch_entity_test.dart`
- [x] T012 [P] [US1] Criar teste de contrato do repositorio de corridas para exclusao de duplicidade em `test/data/repositories/finance_repository_contract_test.dart`
- [x] T013 [P] [US1] Criar teste de controller para carregar o consolidado inicial em `test/presentation/controllers/controller_contract_test.dart`

### Implementation for User Story 1

- [x] T014 [US1] Implementar a montagem da sessao de importacao no dominio em `lib/app/domain/usecases/transaction_use_cases.dart`
- [x] T015 [US1] Adaptar a busca de corridas elegiveis no data layer em `lib/app/data/repositories/ride_repository_impl.dart`
- [x] T016 [US1] Adicionar estado observavel de importacao no controller em `lib/app/presentation/modules/transactions/transactions_controller.dart`
- [x] T017 [US1] Atualizar o formulario de nova transacao para expor a acao `Corridas feitas hoje` em `lib/app/presentation/modules/transactions/views/transaction_form_view.dart`
- [x] T018 [P] [US1] Criar o widget de consolidado por forma de pagamento em `lib/app/presentation/modules/transactions/widgets/transaction_import_summary.dart`
- [x] T019 [P] [US1] Criar o widget de lista expandivel de corridas em `lib/app/presentation/modules/transactions/widgets/transaction_import_rides_section.dart`
- [x] T020 [US1] Integrar o fluxo de importacao ao binding em `lib/app/presentation/modules/transactions/transactions_binding.dart`

**Checkpoint**: a historia 1 fica funcional ao carregar, consolidar e visualizar corridas elegiveis sem depender das outras historias.

---

## Phase 4: User Story 2 - Definir conta por grupo antes de salvar (Priority: P2)

**Goal**: Permitir escolher a conta de destino para cada grupo consolidado e bloquear a confirmacao enquanto houver grupo pendente.

**Independent Test**: Importar corridas, escolher a conta de destino em cada grupo consolidado e confirmar apenas quando todos os grupos estiverem preenchidos.

### Tests for User Story 2

- [x] T021 [P] [US2] Criar testes de validacao da selecao por grupo e consistencia do fluxo em `test/domain/entities/ride_import_batch_entity_test.dart`
- [x] T022 [P] [US2] Criar testes de controller para bloqueio de confirmacao quando houver grupo pendente em `test/presentation/controllers/controller_contract_test.dart`

### Implementation for User Story 2

- [x] T023 [US2] Implementar a validacao da escolha de conta por grupo no dominio em `lib/app/domain/usecases/transaction_use_cases.dart`
- [x] T024 [US2] Expandir o estado do controller para manipular totais importados e grupos com conta selecionada em `lib/app/presentation/modules/transactions/transactions_controller.dart`
- [x] T025 [US2] Criar a UI de selecao de conta por grupo dentro do dialog em `lib/app/presentation/modules/transactions/widgets/transaction_import_summary.dart` e `lib/app/presentation/modules/transactions/widgets/transaction_today_rides_dialog.dart`
- [x] T026 [US2] Conectar a selecao de contas ativas do formulario com o dialog da importacao em `lib/app/presentation/modules/transactions/views/transaction_form_view.dart`
- [x] T027 [US2] Atualizar o binding para registrar qualquer novo use case de validacao necessario em `lib/app/presentation/modules/transactions/transactions_binding.dart`

**Checkpoint**: a historia 2 fica independente ao validar a definicao por contas e impedir confirmacao inconsistente.

---

## Phase 5: User Story 3 - Registrar entradas com rastreabilidade da importacao (Priority: P3)

**Goal**: Registrar o resultado da importacao como entradas persistidas, mantendo rastreabilidade do que foi considerado e feedback claro de sucesso ou erro.

**Independent Test**: Concluir uma importacao valida e verificar criacao das entradas, bloqueio de duplicidade futura e mensagem de sucesso.

### Tests for User Story 3

- [x] T028 [P] [US3] Criar testes de persistencia do registro importado em `test/data/repositories/finance_repository_contract_test.dart`
- [x] T029 [P] [US3] Criar testes de controller para sucesso e erro do registro final em `test/presentation/controllers/controller_contract_test.dart`

### Implementation for User Story 3

- [x] T030 [US3] Implementar o comando de confirmacao da importacao no dominio em `lib/app/domain/usecases/transaction_use_cases.dart`
- [x] T031 [US3] Persistir o registro final como entradas coerentes no repositorio em `lib/app/data/repositories/transaction_repository.dart`
- [x] T032 [US3] Finalizar o fluxo de salvamento e feedback no controller em `lib/app/presentation/modules/transactions/transactions_controller.dart`
- [x] T033 [US3] Exibir mensagem de sucesso e retorno automatico para transacoes no formulario em `lib/app/presentation/modules/transactions/views/transaction_form_view.dart`
- [x] T034 [P] [US3] Criar o dialog de revisao final da importacao em `lib/app/presentation/modules/transactions/widgets/transaction_today_rides_dialog.dart`

**Checkpoint**: a historia 3 fecha o ciclo completo de importacao, persistencia e rastreabilidade.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Ajustes finais para experiencia, manutencao e seguranca de regressao.

- [x] T035 [P] Revisar responsividade da tela de nova transacao e dos widgets de importacao em `lib/app/presentation/modules/transactions/views/transaction_form_view.dart` e `lib/app/presentation/modules/transactions/widgets/`
- [x] T036 [P] Harmonizar mensagens de loading, vazio, erro e sucesso em `lib/app/presentation/modules/transactions/transactions_controller.dart`
- [x] T037 Executar e ajustar a cobertura de testes nos arquivos afetados em `test/domain/`, `test/data/repositories/` e `test/presentation/controllers/`
- [x] T038 Validar que o fluxo nao expoe corridas duplicadas nem quebra o formulario manual em `lib/app/presentation/modules/transactions/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: pode iniciar imediatamente.
- **Foundational (Phase 2)**: depende da Setup e bloqueia todas as historias.
- **User Stories (Phase 3+)**: dependem da base de dominio e contratos.
- **Polish (Phase 6)**: depende da conclusao das historias escolhidas.

### Within Each User Story

- Dominio antes de controller.
- Controller antes de refinamentos finais da view.
- Widgets extraidos depois de estabilizar a estrutura macro.
- Testes devem acompanhar as camadas tocadas na mesma historia.

### Parallel Opportunities

- T002, T003 e T004 podem rodar em paralelo porque atuam em areas separadas.
- T011, T012 e T013 podem rodar em paralelo apos a base de dominio.
- T018 e T019 podem rodar em paralelo apos o estado do consolidado estar definido.
- T021 e T022 podem rodar em paralelo apos a validacao da selecao por grupo estar especificada.
- T028 e T029 podem rodar em paralelo enquanto a persistencia final e ajustada.

## Implementation Strategy

### MVP First

1. Completar Setup.
2. Completar Foundational.
3. Entregar a User Story 1 como primeiro slice util, com consolidado e detalhamento.

### Incremental Delivery

1. Fechar a importacao visual e de elegibilidade primeiro.
2. Em seguida, fechar a selecao de conta por grupo.
3. Por fim, persistir o resultado como entradas rastreaveis e revisar a experiencia completa.

## Task Count Summary

- Total de tarefas: 38
- Setup: 4
- Foundational: 6
- US1: 7
- US2: 6
- US3: 5
- Polish: 4
