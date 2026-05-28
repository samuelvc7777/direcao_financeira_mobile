# Implementation Plan: Tela de metas

**Branch**: `[006-tela-metas]` | **Date**: 2026-05-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-tela-metas/spec.md`

## Summary

Criar uma experiencia real de metas a partir do item "Configurar Metas" em Settings e da secao "Minhas Metas" na Home. A implementacao deve introduzir uma entidade propria `Goal`, separada de `CostsGainsSettings`, com CRUD, status, progresso calculado e resumo na Home. O app deve seguir o padrao atual Flutter + GetX + Clean Architecture, mantendo regras de negocio no domain, data sources em data, bindings no presentation e suporte aos providers Nest e Supabase ja existentes.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x no mobile; TypeScript 5.7.x / NestJS 11 / Prisma 7 no backend  
**Primary Dependencies**: Flutter, GetX, dartz, dio, intl, currency_text_input_formatter, supabase_flutter; NestJS, Prisma, class-validator no backend  
**Storage**: PostgreSQL via Prisma/Nest para API principal; acesso Supabase direto no mobile quando `BackendProviderKind.supabase` estiver ativo  
**Testing**: flutter_test para domain/data/presentation no mobile; Jest/e2e para backend Nest; testes de provider Supabase com helpers existentes quando aplicavel  
**Target Platform**: Mobile Android/iOS, com tela responsiva para larguras pequenas e tablets  
**Project Type**: mobile-app com backend financeiro existente  
**Performance Goals**: listagem fluida de metas, carregamento unico por abertura, atualizacao do resumo da Home sem mocks e sem rebuilds desnecessarios  
**Constraints**: manter GetX como fonte de estado de presentation; preservar Clean Architecture; nao colocar regra de negocio em view/controller; `Goal` nao pode reaproveitar `CostsGainsSettings` como fonte de dados  
**Scale/Scope**: nova feature vertical envolvendo schema/backend, mobile data/domain/presentation, Settings e Home

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Does the plan preserve `presentation`, `domain` and `data` boundaries? **PASS**: `GoalEntity`, repository e use cases ficam no domain; models/datasources/repository impl ficam em data; tela/controller/binding/widgets ficam em presentation.
- Are `bindings`, `controllers`, `use cases`, `repositories` and `datasources` assigned to the correct layer? **PASS**: `GoalsBinding` registra controller/use cases; `ProviderBinding` registra datasources/repository; controllers consomem use cases.
- Will GetX remain the source of presentation state where stateful behavior exists? **PASS**: `GoalsController` e `HomeController` usarao observables para loading/empty/error/success e lista/resumo.
- Are views/pages restricted to macro structure while visual composition is extracted into smaller widgets? **PASS**: `GoalsView` deve ser macro; hero, resumo, lista, card, empty/error e form sheet entram em `widgets/`.
- Are business rules isolated from views, widgets, bindings and controllers? **PASS**: validacao, progresso, status e ownership ficam na entidade/use cases/backend service.
- Does the feature include a testing strategy compatible with the touched layers? **PASS**: plano cobre domain, data, presentation e backend contract/e2e.
- Does the feature preserve responsiveness for the affected screens? **PASS**: tela planejada com layout adaptavel, widgets extraidos e textos truncados/fluindo em larguras pequenas.

## Project Structure

### Documentation (this feature)

```text
specs/006-tela-metas/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   |-- goals-api.md
|   `-- goals-ui.md
|-- checklists/
|   |-- architecture.md
|   |-- data-contract.md
|   `-- requirements.md
`-- tasks.md
```

### Source Code (repository root)

```text
direcao_financeira_backend/
|-- prisma/
|   |-- schema.prisma
|   `-- migrations/[timestamp]_add_goals/
`-- src/modules/finance/
    |-- domain/repositories/finance.repository.ts
    |-- infrastructure/repositories/prisma-finance.repository.ts
    `-- interface/
        |-- dto/create-goal.dto.ts
        |-- dto/update-goal.dto.ts
        |-- finance.controller.ts
        `-- finance.service.ts

direcao_financeira_mobile/
`-- lib/app/
    |-- core/bindings/provider_binding.dart
    |-- data/
    |   |-- datasources/goal_datasource.dart
    |   |-- models/goal_model.dart
    |   |-- providers/nest/finance/nest_goal_remote_datasource.dart
    |   |-- providers/supabase/finance/supabase_goal_remote_datasource.dart
    |   |-- providers/supabase/shared/supabase_table_names.dart
    |   `-- repositories/goal_repository.dart
    |-- domain/
    |   |-- entities/goal_entity.dart
    |   |-- repositories/i_goal_repository.dart
    |   `-- usecases/goal_use_cases.dart
    |-- presentation/modules/
    |   |-- goals/
    |   |   |-- goals_binding.dart
    |   |   |-- goals_controller.dart
    |   |   |-- goals_view.dart
    |   |   `-- widgets/
    |   |-- home/
    |   `-- settings/
    `-- routes/app_pages.dart

direcao_financeira_mobile/test/
|-- app/domain/entities/goal_entity_test.dart
|-- app/domain/usecases/goal_use_cases_test.dart
|-- app/data/providers/supabase/finance/supabase_goal_remote_datasource_test.dart
|-- app/data/repositories/goal_repository_test.dart
|-- app/presentation/modules/goals/goals_controller_test.dart
|-- app/presentation/modules/home/home_controller_test.dart
`-- settings/settings_controller_test.dart
```

**Structure Decision**: Usar o mesmo padrao dos modulos `bank_accounts`, `credit_cards`, `categories` e `costs_gains_settings`. Nao criar camada paralela. A nova entidade `Goal` deve ser registrada nos mesmos pontos globais que os demais repositorios financeiros.

## Layer Responsibilities

### Presentation

- `SettingsController` abre `AppRoutes.goals` quando o item "Configurar Metas" for selecionado.
- `GoalsView` compoe a tela, delegando blocos visuais para widgets privados em `goals/widgets/`.
- `GoalsController` carrega metas, expoe ativas/concluidas/arquivadas, dispara create/update/complete/archive/delete via use cases e solicita refresh do dashboard.
- `HomeController` passa a carregar resumo/lista de Goals reais para `GoalsSection`, removendo o mock `metas`.
- `GoalsSection` exibe estado real: metas existentes ou empty sem dado demonstrativo.

### Domain

- `GoalEntity` representa objetivo da pessoa usuaria e calcula progresso de forma segura.
- `GoalStatus` representa `active`, `completed`, `archived`.
- `IGoalRepository` define contrato para listar, criar, atualizar, concluir e arquivar/remover.
- Use cases (`LoadGoalsUseCase`, `CreateGoalUseCase`, `UpdateGoalUseCase`, `CompleteGoalUseCase`, `ArchiveGoalUseCase`) orquestram intencoes sem conhecer UI/data source.

### Data

- `GoalModel` adapta JSON/Map para `GoalEntity`, preservando valores em centavos.
- `IGoalDataSource` define contrato de persistencia usado pelo repository.
- `NestGoalRemoteDataSource` consome `/finance/goals`.
- `SupabaseGoalRemoteDataSource` acessa a tabela `Goal` com filtro por `userId` via `SupabaseUserScope`.
- `GoalRepository` mapeia erros com `ApiErrorMapper` e registra falhas com `ApiRequestLogger`.

### Backend

- Prisma ganha enum/status e modelo `Goal` com `userId`, `name`, `targetAmountCents`, `currentAmountCents`, `status`, timestamps e indices.
- `User` ganha relacao `goals`.
- `FinanceRepository` ganha operacoes de Goal.
- `PrismaFinanceRepository` implementa queries com escopo por usuario.
- `FinanceService` valida ownership, status e regras de negocio antes de mutacoes.
- `FinanceController` expoe endpoints protegidos por JWT em `/finance/goals`.

## Testing Strategy

### Domain Tests

- `GoalEntity` calcula progresso 0, parcial, 100 e acima de 100 sem quebrar.
- Validacoes impedem nome vazio e objetivo menor/igual a zero.
- Use cases repassam parametros corretos ao `IGoalRepository`.

### Data Tests

- `GoalModel` converte status/string, valores em centavos e timestamps.
- `SupabaseGoalRemoteDataSource` filtra por usuario, ordena metas e monta payloads corretos.
- `NestGoalRemoteDataSource` interpreta respostas `{ goal }`, `{ data }` e lista simples se o padrao do endpoint seguir os demais datasources.
- `GoalRepository` converte exceptions em `Failure`.

### Presentation Tests

- `GoalsController` cobre loading, empty, success, error, create/update/complete/archive.
- `SettingsController` abre rota `AppRoutes.goals` para "Configurar Metas".
- `HomeController` carrega Goals reais e nao exibe mock quando a lista vem vazia.
- Widget/controller da Home valida resumo com metas reais e empty sem demonstracao.

### Backend Tests

- `FinanceService` valida ownership, objetivo positivo, nome obrigatorio e status.
- `FinanceController`/e2e cobre criar, listar, atualizar, concluir e arquivar Goal com JWT.
- Prisma repository garante que um usuario nao acessa Goal de outro usuario.

## Responsiveness Strategy

- `GoalsView` usa `CustomScrollView`/layout fluido com largura maxima em telas grandes.
- Cards de metas usam `Wrap`/grid adaptativo quando houver espaco e coluna unica em larguras pequenas.
- Valores monetarios usam `NumberFormat.simpleCurrency(locale: 'pt_BR')` e `FittedBox`/ellipsis quando necessario.
- Acoes destrutivas ficam em menu/bottom sheet para nao apertar a largura dos cards.
- Form sheet usa `isScrollControlled` e padding com `viewInsets` para teclado.

## Phase 0: Research

Resolvido em [research.md](./research.md).

## Phase 1: Design & Contracts

- Modelo de dados: [data-model.md](./data-model.md)
- Contrato de API: [contracts/goals-api.md](./contracts/goals-api.md)
- Contrato de UI: [contracts/goals-ui.md](./contracts/goals-ui.md)
- Quickstart: [quickstart.md](./quickstart.md)

## Post-Design Constitution Check

- **Clean Architecture**: PASS. O design separa `GoalEntity`/use cases/repository contract de datasources e widgets.
- **GetX + Binding**: PASS. O estado de tela fica no `GoalsController`, e a composicao de dependencias fica em `GoalsBinding`/`ProviderBinding`.
- **Regras no Domain/Backend**: PASS. Calculo de progresso e validacoes ficam em entity/use cases/backend service, nao nos widgets.
- **Views Modulares**: PASS. Tela planejada com view macro e widgets para secoes/cards/form/estados.
- **Testes por Camada**: PASS. Cada camada alterada tem verificacao planejada.
- **Responsividade**: PASS. Estrategia explicita para mobile pequeno e tablet.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Nenhuma | N/A | N/A |
