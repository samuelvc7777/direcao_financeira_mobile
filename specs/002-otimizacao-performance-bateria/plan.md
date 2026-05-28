# Implementation Plan: Otimizacao de performance e bateria

**Branch**: `002-otimizacao-performance-bateria` | **Date**: 2026-05-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-otimizacao-performance-bateria/spec.md`

## Summary

Reduzir consumo de bateria, memoria e picos de processamento em pontos confirmados do app mobile: politica agressiva de GPS no turno, renderizacao nao-lazy de listas operacionais, OCR direto em imagens grandes e auditoria de recursos persistentes. A abordagem tecnica sera priorizar ajuste isolado em `core/location`, refatorar listas do modulo `journey` mantendo views como estrutura macro e widgets menores como composicao visual, documentar a decisao de OCR antes de adicionar dependencia, e auditar socket/background sem assumir vazamento nao comprovado.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x  
**Primary Dependencies**: Flutter, GetX, geolocator, flutter_background_service, socket_io_client, google_mlkit_text_recognition, image_picker, intl  
**Storage**: N/A para a primeira etapa; mudancas previstas sao runtime, presentation e ciclo de vida  
**Testing**: flutter_test, testes de controller/widget quando aplicavel, verificacao manual em Android para bateria/GPS/OCR  
**Target Platform**: Android prioritario para GPS/background; iOS/fallback deve continuar funcionando em `LocationSettings`  
**Project Type**: mobile-app  
**Performance Goals**: reduzir wakeups de GPS parado, manter scroll fluido em historicos, evitar picos desnecessarios no OCR e fechar recursos persistentes quando sem uso  
**Constraints**: preservar Clean Architecture, GetX como estado de presentation, views focadas em estrutura macro, regras fora da UI, sem afirmar vazamentos sem evidencia  
**Scale/Scope**: `core/location`, `presentation/modules/journey`, auditoria pontual em listas financeiras, OCR em `ImportRidePhotoController`, realtime/background lifecycle

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `presentation`, `domain` e `data` permanecem separados; ajustes de GPS ficam em `core/location`, listas em widgets de `presentation`, e OCR no controller apenas orquestra fluxo existente.
- Nao ha nova regra de negocio prevista; qualquer politica reutilizavel de OCR/GPS deve ser extraida para servico apropriado se crescer.
- GetX continua como fonte de estado nas telas afetadas.
- Views/pages continuam com estrutura macro; `RidesListSection` e `ShiftHistorySection` devem preservar composicao por widgets menores como cards, headers e footers.
- Nenhuma regra financeira ou operacional nova sera colocada na UI.
- A estrategia inclui testes/checagens para camadas tocadas: configuracao de localizacao, widgets/listas e controller de OCR se alterado.
- Responsividade deve ser preservada, especialmente padding, cards, estados vazios e footers em telas pequenas.

**Gate Status**: PASS. Nao ha violacao planejada da constituicao.

## Project Structure

### Documentation (this feature)

```text
specs/002-otimizacao-performance-bateria/
|-- spec.md
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
`-- contracts/
    `-- runtime-performance-contract.md
```

### Source Code (repository root)

```text
lib/
`-- app/
    |-- core/
    |   `-- location/
    |       `-- location_tracking_service.dart
    |-- data/
    |   `-- providers/
    |       `-- nest/realtime/socket_io_realtime_client.dart
    `-- presentation/
        `-- modules/
            |-- journey/
            |   |-- import_ride_photo_controller.dart
            |   `-- widgets/
            |       |-- rides_list_section.dart
            |       `-- shift_history_section.dart
            |-- categories/
            |   `-- categories_view.dart
            |-- bank_accounts/widgets/
            |   `-- bank_accounts_content.dart
            `-- credit_cards/widgets/
                `-- credit_cards_content.dart

test/
`-- app/
    `-- presentation/
        `-- modules/
            `-- journey/
```

**Structure Decision**: Manter mudancas nos arquivos existentes quando o ganho for local. Criar helpers novos apenas se evitar duplicacao real, por exemplo uma politica de localizacao testavel ou um widget/sliver compartilhado dentro de `journey/widgets`.

## Layer Responsibilities

### Presentation

- `RidesListSection` e `ShiftHistorySection` devem migrar colecoes crescentes para renderizacao lazy preservando cards e footers.
- `ImportRidePhotoController` pode orquestrar pre-processamento de imagem, mas logica reutilizavel de compressao deve sair para servico se nao for trivial.
- Telas de categorias, contas e cartoes entram como auditoria de segunda onda.

### Domain

- Sem mudanca de dominio prevista na primeira etapa.
- Se alguma regra operacional de turno for formalizada alem de configuracao tecnica, ela deve ser modelada fora da UI/controller.

### Data

- Sem mudanca de persistencia prevista.
- Cliente realtime deve ser apenas auditado; o estado atual ja possui `disconnect` e `dispose`.

### Core/Infrastructure

- `location_tracking_service.dart` concentra a politica imediata de GPS.
- Background service deve preservar seus encerramentos existentes com `stopSelf`.

## Pesquisa e Decisoes

- A pesquisa consolidada esta em [research.md](./research.md).
- Decisao principal: atacar primeiro GPS e listas paginadas de journey, porque sao gargalos confirmados e de maior impacto.
- OCR entra como etapa validada por evidencia; adicionar dependencia de compressao sem teste pode reduzir acuracia.
- Socket/background entram como auditoria, nao como refatoracao cega.

## Estrategia de Implementacao

1. Extrair ou ajustar a politica de `LocationSettings` para usar `distanceFilter` maior que zero e remover/aumentar o intervalo Android agressivo.
2. Cobrir a politica com teste simples se a funcao puder ser isolada sem expor API desnecessaria.
3. Refatorar `RidesListSection` para scroll lazy com slivers, mantendo cabecalho, filtros, empty/error e footer.
4. Refatorar `ShiftHistorySection` com o mesmo padrao.
5. Auditar listas de categorias, contas e cartoes e migrar apenas as secoes de entidade que realmente crescem.
6. Medir/validar OCR com imagem grande; se necessario, introduzir servico de pre-processamento com fallback.
7. Registrar auditoria de realtime/background e alterar somente se houver recurso aberto sem encerramento.

## Testing Strategy

### Domain Tests

- Nao ha teste de dominio obrigatorio na primeira etapa, pois nao ha regra de negocio nova.

### Core/Infrastructure Tests

- Validar que a configuracao de localizacao de turno nao usa deslocamento zero.
- Validar que Android nao combina intervalo curto com filtro zero.

### Presentation Tests

- Testar ou revisar renderizacao de `RidesListSection` e `ShiftHistorySection` em estados vazio, carregado e carregando mais.
- Garantir que os callbacks de filtro, data, detalhes e delete continuam acionaveis.

### Manual Tests

- Iniciar turno em Android e verificar ausencia de regressao de permissao/location stream.
- Abrir historico de turnos/corridas com varios itens e rolar ate o fim.
- Executar OCR com imagem normal e imagem grande.
- Encerrar sessao/turno e observar se realtime/background encerram.

## Responsiveness Strategy

- Preservar `Responsive.hp/vp/sp` ja usado nos widgets de journey.
- Manter padding e largura maxima existentes.
- Em slivers, cabecalhos e paineis devem continuar empilhados em telas pequenas.
- Footers de paginacao devem permanecer abaixo dos itens sem sobrepor conteudo.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| Nenhuma | Nao ha violacoes planejadas da constituicao | N/A |
