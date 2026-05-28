# Implementation Plan: Consumir API Google do Admin no Mobile

**Branch**: `009-consumir-api-google-mobile` | **Date**: 2026-05-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/009-consumir-api-google-mobile/spec.md`

## Summary

Fazer o app mobile carregar a API Google ativa cadastrada no admin e usar esse valor nos pontos que hoje dependem de `AppEnvironment.googleMapsApiKey`: autocomplete de endereco, estimativa de rota, importacao de print e sincronizacao com o servico nativo de OCR/semafaro. A abordagem sera criar uma fonte resolvida de configuracao com prioridade para Supabase `Company.googleApiKey` e fallback para a chave local existente, registrada nos bindings centrais e consumida pelos bindings da Jornada.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x  
**Primary Dependencies**: Flutter, GetX, GetStorage, Supabase Flutter, Dio, google_mlkit_text_recognition  
**Storage**: Supabase para configuracao remota `Company.googleApiKey`; `AppEnvironment.googleMapsApiKey` como fallback local  
**Testing**: flutter_test, testes de datasource/resolved config e testes de controller/binding quando aplicavel  
**Target Platform**: Android mobile, incluindo canal nativo de acessibilidade/OCR  
**Project Type**: mobile-app  
**Performance Goals**: nao bloquear abertura do app/telas; leitura remota com fallback rapido; sincronizacao nativa sem atraso perceptivel  
**Constraints**: preservar Clean Architecture; manter GetX como injecao/estado; nao colocar regra de resolucao de chave em views; manter OCR ML Kit local sem nova dependencia  
**Scale/Scope**: `core/config`, `core/bindings`, `core/accessibility`, `data/datasources`, `domain/services` ou `domain/usecases`, e bindings de `presentation/modules/journey`

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `presentation`, `domain` e `data` permanecem separados: a busca remota fica em data, a regra de prioridade/fallback fica em dominio/core service, e bindings apenas compoem dependencias.
- Bindings continuam como ponto oficial de injecao; `ImportRidePhotoBinding`, `AddRideBinding` e `CoreBinding/ProviderBinding` devem consumir dependencias registradas.
- GetX permanece responsavel por localizar dependencias e orquestrar ciclo de vida.
- Nao ha nova view; responsividade nao e afetada diretamente.
- Regras de negocio de chave remota vs fallback local ficam fora de view/controller.
- Estrategia de testes cobre data/fallback e pontos de consumo.

Resultado pre-Phase 0: **PASS**.

Recheck pos-Phase 1: **PASS**. O design mantem a resolucao em servico/contrato reutilizavel e limita presentation a consumo via bindings.

## Project Structure

### Documentation (this feature)

```text
specs/009-consumir-api-google-mobile/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- resolved-google-api-key.md
`-- tasks.md
```

### Source Code (repository root)

```text
lib/
`-- app/
    |-- core/
    |   |-- accessibility/
    |   |   `-- accessibility_controller.dart
    |   |-- bindings/
    |   |   |-- app_binding.dart
    |   |   |-- core_binding.dart
    |   |   `-- provider_binding.dart
    |   `-- config/
    |       `-- app_environment.dart
    |-- data/
    |   |-- datasources/
    |   |   `-- google_api_config_datasource.dart
    |   `-- providers/
    |       `-- supabase/
    |           `-- shared/
    |               `-- supabase_table_names.dart
    |-- domain/
    |   |-- entities/
    |   |   `-- google_api_config_entity.dart
    |   |-- repositories/
    |   |   `-- i_google_api_config_repository.dart
    |   |-- services/
    |   |   `-- resolved_google_api_key_service.dart
    |   `-- usecases/
    |       `-- google_api_config_use_cases.dart
    `-- presentation/
        `-- modules/
            `-- journey/
                |-- add_ride_binding.dart
                `-- import_ride_photo_binding.dart
```

**Structure Decision**: criar contrato pequeno e reutilizavel para configuracao Google, seguindo o padrao de camadas. Os pontos de UI existentes continuam inalterados visualmente; apenas passam a receber a chave resolvida pelo binding.

## Layer Responsibilities

### Presentation

- `AddRideBinding` e `ImportRidePhotoBinding` devem buscar a chave por uma dependencia resolvida, sem saber se veio do admin ou fallback.
- Nenhuma view nova sera criada.

### Domain

- Entidade representa a configuracao remota.
- Use case/servico resolve prioridade: valor remoto valido > fallback local.
- Regras de trim, vazio e fallback ficam testaveis fora da UI.

### Data

- Datasource Supabase le `Company.googleApiKey` do registro singleton `id = 1`.
- Erros de rede/permissao/coluna ausente retornam ausencia de valor em vez de quebrar os fluxos existentes.

## Testing Strategy

### Domain Tests

- Validar que valor remoto valido vence o fallback.
- Validar que remoto vazio/nulo/espacos usa fallback.
- Validar que falha de datasource usa fallback.

### Data Tests

- Validar parsing de `googleApiKey` vindo de map Supabase.
- Validar comportamento quando `Company` nao retorna linha ou ocorre erro.

### Presentation/Core Tests

- Validar que `AccessibilityController.syncSettingsWithNative()` envia a chave resolvida.
- Validar que bindings de Jornada usam a chave resolvida nos servicos Google.

## Responsiveness Strategy

Nao ha mudanca visual. As telas existentes de Jornada/importacao mantem layout atual.

## Complexity Tracking

Sem violacoes que exijam justificativa.
