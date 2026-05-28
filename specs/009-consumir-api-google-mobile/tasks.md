# Tasks: Consumir API Google do Admin no Mobile

**Input**: Design documents from `/specs/009-consumir-api-google-mobile/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Incluir testes automatizados porque a feature toca regras de fallback, datasource Supabase, bindings e sincronizacao nativa.

**Organization**: Tasks agrupadas por historia para permitir implementacao incremental e validacao independente.

## Format: `[ID] [P?] [Story] Description`

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar arquivos novos e revisar pontos atuais de uso da chave Google.

- [x] T001 Revisar usos atuais de `googleMapsApiKey` em `lib/app/core/config/app_environment.dart`, `lib/app/presentation/modules/journey/add_ride_binding.dart`, `lib/app/presentation/modules/journey/import_ride_photo_binding.dart` e `lib/app/core/accessibility/accessibility_controller.dart`
- [x] T002 [P] Adicionar constante `company` em `lib/app/data/providers/supabase/shared/supabase_table_names.dart`
- [x] T003 [P] Criar estrutura de testes para configuracao Google em `test/app/domain/services/resolved_google_api_key_service_test.dart` e `test/app/data/datasources/google_api_config_datasource_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Criar contrato de dominio, datasource, repositorio e servico de resolucao antes de ligar consumidores.

- [x] T004 [P] Criar entidade `GoogleApiConfigEntity` em `lib/app/domain/entities/google_api_config_entity.dart`
- [x] T005 [P] Criar entidade/value object `ResolvedGoogleApiKey` em `lib/app/domain/entities/resolved_google_api_key_entity.dart`
- [x] T006 Criar contrato `IGoogleApiConfigRepository` em `lib/app/domain/repositories/i_google_api_config_repository.dart`
- [x] T007 [P] Criar datasource `IGoogleApiConfigDataSource` e implementacao Supabase em `lib/app/data/datasources/google_api_config_datasource.dart`
- [x] T008 Criar repository `GoogleApiConfigRepository` em `lib/app/data/repositories/google_api_config_repository.dart`
- [x] T009 Criar servico/use case de resolucao `ResolvedGoogleApiKeyService` em `lib/app/domain/services/resolved_google_api_key_service.dart`
- [x] T010 Registrar datasource, repository e servico nos providers/bindings centrais em `lib/app/core/bindings/provider_binding.dart`

**Checkpoint**: A fonte resolvida existe e pode ser consumida sem alterar ainda os fluxos de Jornada.

---

## Phase 3: User Story 1 - Usar API Google centralizada nos fluxos de corrida (Priority: P1) MVP

**Goal**: Fazer adicionar corrida e importar print usarem a chave remota quando disponivel.

**Independent Test**: Com `Company.googleApiKey` preenchida, os servicos de endereco/rota nos bindings usam a chave remota em vez da chave fixa do ambiente.

### Tests for User Story 1

- [x] T011 [P] [US1] Testar prioridade remoto > fallback em `test/app/domain/services/resolved_google_api_key_service_test.dart`
- [x] T012 [P] [US1] Testar parsing de `Company.googleApiKey` remoto em `test/app/data/datasources/google_api_config_datasource_test.dart`

### Implementation for User Story 1

- [x] T013 [US1] Atualizar `lib/app/presentation/modules/journey/add_ride_binding.dart` para obter chave via `ResolvedGoogleApiKeyService`
- [x] T014 [US1] Atualizar `lib/app/presentation/modules/journey/import_ride_photo_binding.dart` para obter chave via `ResolvedGoogleApiKeyService`
- [x] T015 [US1] Garantir que `AddressAutocompleteService` e `RideRouteEstimator` recebam a chave resolvida nos dois bindings de Jornada
- [x] T016 [US1] Revisar `lib/app/core/config/app_environment.dart` para manter `googleMapsApiKey` apenas como fallback documentado no codigo

**Checkpoint**: US1 pronto quando os fluxos de Jornada nao dependem mais diretamente da chave local como primeira opcao.

---

## Phase 4: User Story 2 - Manter funcionamento com fallback local (Priority: P2)

**Goal**: Garantir que falha remota, valor vazio ou ausencia da coluna/linha nao quebre o app.

**Independent Test**: Simular erro/retorno vazio do datasource e confirmar que a chave local e usada sem excecao visivel.

### Tests for User Story 2

- [x] T017 [P] [US2] Testar fallback quando remoto retorna nulo, vazio ou espacos em `test/app/domain/services/resolved_google_api_key_service_test.dart`
- [x] T018 [P] [US2] Testar fallback quando datasource lanca erro em `test/app/domain/services/resolved_google_api_key_service_test.dart`
- [x] T019 [P] [US2] Testar datasource retornando ausencia quando Supabase nao retorna linha em `test/app/data/datasources/google_api_config_datasource_test.dart`

### Implementation for User Story 2

- [x] T020 [US2] Implementar tratamento de erro silencioso/seguro na leitura Supabase em `lib/app/data/datasources/google_api_config_datasource.dart`
- [x] T021 [US2] Implementar normalizacao `trim` e validacao de vazio em `lib/app/domain/services/resolved_google_api_key_service.dart`
- [x] T022 [US2] Garantir que bindings de Jornada continuem criando os servicos mesmo quando a chave resolvida for fallback ou string vazia em `lib/app/presentation/modules/journey/add_ride_binding.dart` e `lib/app/presentation/modules/journey/import_ride_photo_binding.dart`

**Checkpoint**: US2 pronto quando a ausencia remota nao altera negativamente o comportamento atual do app.

---

## Phase 5: User Story 3 - Sincronizar chave com o servico nativo de OCR (Priority: P3)

**Goal**: Enviar ao nativo a mesma chave resolvida usada pelos servicos Dart.

**Independent Test**: Ao sincronizar settings nativas, o payload `google_maps_api_key` contem remoto valido ou fallback local.

### Tests for User Story 3

- [x] T023 [P] [US3] Adaptar teste de `AccessibilityController.syncSettingsWithNative()` em `test/core/accessibility/accessibility_controller_test.dart` para verificar `google_maps_api_key` resolvida
- [x] T024 [P] [US3] Testar cenario de fallback local na sincronizacao nativa em `test/core/accessibility/accessibility_controller_test.dart`

### Implementation for User Story 3

- [x] T025 [US3] Atualizar `lib/app/core/accessibility/accessibility_controller.dart` para usar `ResolvedGoogleApiKeyService` em `syncSettingsWithNative()`
- [x] T026 [US3] Ajustar registro/injecao necessaria em `lib/app/core/bindings/core_binding.dart` ou `lib/app/core/bindings/provider_binding.dart` para o controller acessar o servico sem dependencia circular
- [x] T027 [US3] Confirmar que o contrato enviado ao nativo preserva o campo `google_maps_api_key` esperado por `android/app/src/main/kotlin/com/example/direcao_financeira_mobile/SettingsManager.kt`

**Checkpoint**: US3 pronto quando Dart e nativo usam a mesma fonte resolvida.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Validacao final, documentacao e garantia de nao regressao.

- [x] T028 [P] Atualizar `specs/009-consumir-api-google-mobile/quickstart.md` com qualquer detalhe real descoberto durante a implementacao
- [x] T029 Rodar `flutter test test/app/domain/services/resolved_google_api_key_service_test.dart test/app/data/datasources/google_api_config_datasource_test.dart test/core/accessibility/accessibility_controller_test.dart`
- [x] T030 Rodar `flutter analyze`
- [x] T031 Revisar todos os usos restantes de `googleMapsApiKey` com `rg -n "googleMapsApiKey|google_maps_api_key" lib android test`
- [x] T032 Registrar pendencia de validacao manual em device/emulador para OCR/semafaro se testes automatizados nao cobrirem o canal nativo real em `specs/009-consumir-api-google-mobile/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1**: sem dependencias.
- **Phase 2**: depende da Phase 1 e bloqueia todas as historias.
- **US1**: depende da fonte resolvida criada na Phase 2.
- **US2**: depende da fonte resolvida e endurece fallback/erro.
- **US3**: depende da fonte resolvida e pode iniciar apos Phase 2, mas deve considerar ajustes feitos em US2.
- **Polish**: depende das historias implementadas.

### User Story Dependencies

- **US1 (P1)**: entrega valor principal e pode ser MVP.
- **US2 (P2)**: reforca resiliencia sem mudar o contrato publico.
- **US3 (P3)**: integra o mesmo contrato com o canal nativo.

### Parallel Opportunities

- T002 e T003 podem rodar em paralelo.
- T004, T005 e T007 podem rodar em paralelo apos T001.
- T011 e T012 podem rodar em paralelo.
- T017, T018 e T019 podem rodar em paralelo.
- T023 e T024 podem rodar em paralelo se usarem fixtures separadas.
- T028 pode rodar em paralelo com revisao final depois da implementacao.

---

## Parallel Example: User Story 1

```bash
Task: "T011 [US1] Testar prioridade remoto > fallback em test/app/domain/services/resolved_google_api_key_service_test.dart"
Task: "T012 [US1] Testar parsing de Company.googleApiKey remoto em test/app/data/datasources/google_api_config_datasource_test.dart"
```

---

## Implementation Strategy

### MVP First

1. Completar Phase 1 e Phase 2.
2. Implementar US1.
3. Validar que AddRide e ImportRide usam chave remota com fallback local disponivel.

### Incremental Delivery

1. Entregar fonte resolvida e consumo nos bindings de Jornada.
2. Endurecer fallback e erro remoto.
3. Sincronizar nativo com a mesma fonte.
4. Rodar testes, analyze e validacao manual indicada.

### Parallel Team Strategy

1. Pessoa A: entidades/servico de dominio e testes.
2. Pessoa B: datasource/repository Supabase e testes.
3. Pessoa C: bindings de Jornada e sincronizacao nativa apos Phase 2.

---

## Notes

- Manter regra remoto > fallback fora de views/controllers.
- Nao remover `AppEnvironment.googleMapsApiKey`; ele continua como fallback.
- Nao alterar OCR ML Kit local nesta feature.
- Evitar chamadas remotas bloqueantes em tela; preferir fonte resolvida com fallback rapido.
