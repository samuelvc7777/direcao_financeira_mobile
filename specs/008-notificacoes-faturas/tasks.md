# Tasks: Notificacoes de Faturas

**Input**: Design documents from `specs/008-notificacoes-faturas/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/notification-behavior.md, quickstart.md

**Tests**: Incluidos. A feature altera regras de negocio, persistencia local, agendamento Android e pontos de integracao, entao precisa de cobertura automatizada por camada alem da validacao manual em aparelho.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo quando nao toca os mesmos arquivos nem depende de tarefa incompleta
- **[Story]**: US1, US2, US3 conforme as historias da spec
- Todas as tarefas incluem caminhos de arquivo reais ou caminhos novos previstos no plano

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar dependencias, manifest Android e estrutura compartilhada sem implementar regra de negocio ainda.

- [X] T001 Adicionar `timezone` como dependencia direta em `pubspec.yaml`
- [X] T002 Rodar `flutter pub get` para atualizar `pubspec.lock`
- [X] T003 Configurar receivers de agendamento do `flutter_local_notifications` em `android/app/src/main/AndroidManifest.xml`
- [X] T004 [P] Criar estrutura base de notificacoes em `lib/app/core/notifications/invoice_notification_scheduler.dart`
- [X] T005 [P] Criar contrato de plataforma Android em `lib/app/core/notifications/invoice_notification_platform.dart`
- [X] T006 [P] Criar estrutura de testes da feature em `test/app/domain/services/`, `test/app/data/datasources/` e `test/app/core/notifications/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Criar entidades, contratos, persistencia local e wiring minimo que bloqueiam todas as historias.

- [X] T007 Criar entidades de notificacao de fatura em `lib/app/domain/entities/invoice_notification_entity.dart`
- [X] T008 Criar contrato de repositorio de notificacoes de fatura em `lib/app/domain/repositories/i_invoice_notification_repository.dart`
- [X] T009 [P] Criar servico de relogio/data testavel em `lib/app/domain/services/app_clock.dart`
- [X] T010 [P] Criar modelos locais de notificacao em `lib/app/data/models/invoice_notification_model.dart`
- [X] T011 Criar datasource local de dedupe/agendamento em `lib/app/data/datasources/invoice_notification_local_datasource.dart`
- [X] T012 Criar implementacao do repositorio em `lib/app/data/repositories/invoice_notification_repository.dart`
- [X] T013 Criar implementacao do scheduler local Android em `lib/app/core/notifications/local_invoice_notification_scheduler.dart`
- [X] T014 Criar use cases compartilhados em `lib/app/domain/usecases/invoice_notification_use_cases.dart`
- [X] T015 Registrar datasource, repositorio, scheduler e use cases em `lib/app/core/bindings/provider_binding.dart`
- [X] T016 Inicializar/revalidar notificacoes apos restore de sessao em `lib/app/core/bindings/app_binding.dart`
- [X] T017 [P] Criar testes do datasource local em `test/app/data/datasources/invoice_notification_local_datasource_test.dart`
- [X] T018 [P] Criar testes do repositorio em `test/app/data/repositories/invoice_notification_repository_test.dart`
- [X] T019 [P] Criar testes do scheduler com mock/fake em `test/app/core/notifications/local_invoice_notification_scheduler_test.dart`

**Checkpoint**: Fundacao pronta. As historias podem implementar os tipos de aviso sem misturar regra de negocio com UI.

---

## Phase 3: User Story 1 - Avisar faturas vencidas diariamente (Priority: P1) MVP

**Goal**: Enviar aviso local diario as 10h para faturas vencidas com valor pendente e parar quando forem pagas/zeradas.

**Independent Test**: Com um cartao ativo e fatura vencida pendente, simular a avaliacao de 10h e confirmar candidato/agenda; apos pagamento integral, confirmar que nao ha novo candidato.

### Tests for User Story 1

- [X] T020 [P] [US1] Criar testes de elegibilidade de fatura vencida em `test/app/domain/services/invoice_notification_candidate_builder_test.dart`
- [X] T021 [P] [US1] Criar testes de dedupe diario de atraso em `test/app/domain/services/invoice_notification_dedupe_service_test.dart`
- [X] T022 [P] [US1] Criar testes do use case de reagendamento de atrasos em `test/app/domain/usecases/invoice_notification_use_cases_test.dart`

### Implementation for User Story 1

- [X] T023 [US1] Implementar builder de candidatos vencidos em `lib/app/domain/services/invoice_notification_candidate_builder.dart`
- [X] T024 [US1] Implementar dedupe por cartao/ciclo/tipo/dia em `lib/app/domain/services/invoice_notification_dedupe_service.dart`
- [X] T025 [US1] Implementar textos de notificacao vencida em `lib/app/domain/services/invoice_notification_text_formatter.dart`
- [X] T026 [US1] Implementar fluxo de agendar avisos vencidos em `lib/app/domain/usecases/invoice_notification_use_cases.dart`
- [X] T027 [US1] Integrar reagendamento apos carga de cartoes em `lib/app/presentation/modules/credit_cards/credit_cards_controller.dart`
- [X] T028 [US1] Integrar cancelamento/reagendamento apos pagamento de fatura em `lib/app/presentation/modules/credit_cards/credit_cards_controller.dart`
- [X] T029 [US1] Implementar payload para abrir cartoes a partir da notificacao em `lib/app/core/notifications/local_invoice_notification_scheduler.dart`

**Checkpoint**: US1 deve funcionar como MVP independente para faturas vencidas.

---

## Phase 4: User Story 2 - Avisar fechamento da fatura (Priority: P2)

**Goal**: Enviar aviso as 10h no dia de fechamento cadastrado do cartao, sem notificar cartoes inativos.

**Independent Test**: Com um cartao ativo cujo fechamento e hoje, simular a avaliacao de 10h e confirmar candidato/agenda de fechamento; repetir com cartao inativo e confirmar ausencia de aviso.

### Tests for User Story 2

- [X] T030 [P] [US2] Criar testes de fechamento no dia cadastrado em `test/app/domain/services/invoice_notification_candidate_builder_test.dart`
- [X] T031 [P] [US2] Criar testes de normalizacao para ultimo dia valido do mes em `test/app/domain/services/invoice_notification_candidate_builder_test.dart`

### Implementation for User Story 2

- [X] T032 [US2] Estender builder de candidatos para fechamento em `lib/app/domain/services/invoice_notification_candidate_builder.dart`
- [X] T033 [US2] Estender formatter para notificacao de fechamento em `lib/app/domain/services/invoice_notification_text_formatter.dart`
- [X] T034 [US2] Estender use case de reagendamento para avisos de fechamento em `lib/app/domain/usecases/invoice_notification_use_cases.dart`
- [X] T035 [US2] Garantir que alteracoes de `closingDay` reagendem notificacoes em `lib/app/presentation/modules/credit_cards/credit_cards_controller.dart`

**Checkpoint**: US1 e US2 devem funcionar independentemente com os mesmos contratos compartilhados.

---

## Phase 5: User Story 3 - Avisar vencimento da fatura (Priority: P3)

**Goal**: Enviar aviso as 10h no dia de vencimento cadastrado quando houver valor pendente, sem duplicidade confusa quando fechamento e vencimento cairem no mesmo dia.

**Independent Test**: Com um cartao ativo cujo vencimento e hoje e valor pendente, simular a avaliacao de 10h e confirmar aviso; pagar antes das 10h e confirmar ausencia; configurar fechamento e vencimento na mesma data e confirmar consolidacao/prioridade.

### Tests for User Story 3

- [X] T036 [P] [US3] Criar testes de vencimento no dia com valor pendente em `test/app/domain/services/invoice_notification_candidate_builder_test.dart`
- [X] T037 [P] [US3] Criar testes de ausencia de vencimento apos pagamento integral em `test/app/domain/services/invoice_notification_candidate_builder_test.dart`
- [X] T038 [P] [US3] Criar testes de consolidacao quando fechamento e vencimento coincidem em `test/app/domain/services/invoice_notification_dedupe_service_test.dart`

### Implementation for User Story 3

- [X] T039 [US3] Estender builder de candidatos para vencimento em `lib/app/domain/services/invoice_notification_candidate_builder.dart`
- [X] T040 [US3] Estender formatter para notificacao de vencimento em `lib/app/domain/services/invoice_notification_text_formatter.dart`
- [X] T041 [US3] Implementar regra de consolidacao/prioridade de avisos no mesmo dia em `lib/app/domain/services/invoice_notification_dedupe_service.dart`
- [X] T042 [US3] Estender use case de reagendamento para avisos de vencimento em `lib/app/domain/usecases/invoice_notification_use_cases.dart`
- [X] T043 [US3] Garantir que alteracoes de `dueDay` reagendem notificacoes em `lib/app/presentation/modules/credit_cards/credit_cards_controller.dart`

**Checkpoint**: US1, US2 e US3 devem cobrir vencidas, fechamento e vencimento sem duplicidade.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Fechar permissao, feedback, validacao Android e qualidade final.

- [X] T044 [P] Implementar consulta de permissao de notificacao em `lib/app/core/notifications/notification_permission_service.dart`
- [X] T045 Integrar feedback de permissao bloqueada em `lib/app/presentation/modules/settings/settings_controller.dart`
- [X] T046 [P] Adicionar ou ajustar widget de status de notificacoes em `lib/app/presentation/modules/settings/settings_view.dart`
- [X] T047 Revisar navegacao ao tocar notificacao em `lib/app/routes/app_pages.dart`
- [X] T048 Revisar ids/canais de notificacao e payloads em `lib/app/core/notifications/local_invoice_notification_scheduler.dart`
- [X] T049 Limpar registros antigos de dedupe em `lib/app/data/datasources/invoice_notification_local_datasource.dart`
- [ ] T050 Rodar `flutter analyze` em `C:/Users/Samuel Vitor/Documents/aplicativos/direcao_financeira/direcao_financeira_mobile` e corrigir problemas encontrados
- [X] T051 Rodar `flutter test test/app/domain test/app/data test/app/core` em `C:/Users/Samuel Vitor/Documents/aplicativos/direcao_financeira/direcao_financeira_mobile` e corrigir falhas
- [X] T052 Rodar `flutter build apk --debug` em `C:/Users/Samuel Vitor/Documents/aplicativos/direcao_financeira/direcao_financeira_mobile` para validar configuracao Android
- [ ] T053 Validar manualmente em Android real: permissao, app fechado, boot/update, fechamento, vencimento e atraso conforme `specs/008-notificacoes-faturas/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependencia.
- **Foundational (Phase 2)**: depende do Setup e bloqueia todas as historias.
- **US1 (Phase 3)**: depende da fundacao; e o MVP.
- **US2 (Phase 4)**: depende da fundacao e pode reutilizar servicos criados no US1.
- **US3 (Phase 5)**: depende da fundacao e das regras compartilhadas de dedupe; deve ser fechado apos US1/US2 para consolidacao.
- **Polish (Phase 6)**: depende das historias implementadas.

### User Story Dependencies

- **US1**: independente apos fundacao; entrega valor principal.
- **US2**: pode ser implementada apos fundacao, mas aproveita builder/formatter do US1.
- **US3**: deve considerar US1 e US2 para evitar duplicidade quando eventos coincidem.

### Parallel Opportunities

- T004, T005 e T006 podem rodar em paralelo.
- T009 e T010 podem rodar em paralelo.
- T017, T018 e T019 podem rodar em paralelo.
- T020, T021 e T022 podem rodar em paralelo.
- T030 e T031 podem rodar em paralelo.
- T036, T037 e T038 podem rodar em paralelo.
- T044 e T046 podem iniciar em paralelo depois das historias, desde que nao editem o mesmo arquivo.

---

## Parallel Execution Examples

### US1

```text
T020 + T021 + T022 em paralelo
T023 -> T024 -> T025 -> T026 -> T027/T028/T029
```

### US2

```text
T030 + T031 em paralelo
T032 -> T033 -> T034 -> T035
```

### US3

```text
T036 + T037 + T038 em paralelo
T039 -> T040 -> T041 -> T042 -> T043
```

---

## Implementation Strategy

### MVP First

1. Completar Setup e Fundacao.
2. Implementar US1 de ponta a ponta: faturas vencidas, dedupe, agendamento, pagamento cancela novos avisos.
3. Validar US1 com testes de dominio/data/core e teste manual simples.

### Incremental Delivery

1. Adicionar US2 para fechamento sem mexer no contrato publico ja usado pelo US1.
2. Adicionar US3 para vencimento e consolidacao.
3. Fechar permissao/feedback e validacao Android.

### Suggested MVP Scope

US1 e o MVP recomendado: avisar faturas vencidas diariamente as 10h ate pagamento integral.

---

## Task Summary

- Total: 53 tarefas
- Setup: 6 tarefas
- Fundacao: 13 tarefas
- US1: 10 tarefas
- US2: 6 tarefas
- US3: 8 tarefas
- Polish/validacao: 10 tarefas

## Notes

- Nao usar Firebase nesta feature.
- Nao implementar suporte iOS nesta feature.
- Preferir agendamento local robusto; alarme exato so entra se a validacao do produto exigir precisao estrita as 10h.
- Manter regras de fatura em `domain`, persistencia em `data` e plugin/plataforma em `core/notifications`.
