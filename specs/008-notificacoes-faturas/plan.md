# Implementation Plan: Notificacoes de Faturas

**Branch**: `008-notificacoes-faturas` | **Date**: 2026-05-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/008-notificacoes-faturas/spec.md`

## Summary

Implementar notificacoes locais Android para faturas de cartao: aviso de fechamento, aviso de vencimento e aviso diario de atraso as 10h enquanto houver valor pendente. A abordagem sera reaproveitar o estado de faturas ja exposto pelo modulo de cartoes, isolar regras de elegibilidade/deduplicacao no dominio, persistir o historico minimo localmente e usar `flutter_local_notifications` para agendar/emitir avisos locais sem Firebase ou push remoto.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x; Android nativo existente em Kotlin para servicos e manifest  
**Primary Dependencies**: Flutter, GetX, dartz, intl, get_storage, supabase_flutter, flutter_local_notifications 21.0.0, timezone 0.11.0 como dependencia direta planejada  
**Storage**: Supabase para cartoes/faturas existentes; armazenamento local leve para registros de avisos enviados e metadados de agendamento  
**Testing**: flutter_test para dominio, data e controllers; testes Kotlin apenas se houver alteracao nativa Android alem do manifest  
**Target Platform**: Android somente  
**Project Type**: mobile-app  
**Performance Goals**: avaliacao diaria de faturas em tempo curto, sem bloquear inicializacao do app; agendamento/reagendamento idempotente  
**Constraints**: sem Firebase/push remoto; notificacoes devem funcionar com app fechado quando o Android permitir; preservar Clean Architecture; regras de fatura e dedupe fora de views/controllers; respeitar `POST_NOTIFICATIONS`, boot/update e restricoes de bateria  
**Scale/Scope**: modulo compartilhado de notificacoes de fatura integrado ao fluxo de cartoes, inicializacao do app e Settings/feedback de permissao quando necessario

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `presentation`, `domain` e `data` permanecem separados: PASS.
- Bindings/controllers/use cases/repositories/datasources ficam nas camadas corretas: PASS.
- GetX permanece fonte de estado apenas onde houver feedback de UI ou Settings: PASS.
- Views continuam macro; qualquer bloco visual novo sera extraido para widget menor se necessario: PASS.
- Regras de negocio ficam no dominio: PASS.
- Estrategia de testes cobre dominio, data e presentation quando tocada: PASS.
- Responsividade preservada; a feature e majoritariamente background, com UI minima: PASS.

## Project Structure

### Documentation (this feature)

```text
specs/008-notificacoes-faturas/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- notification-behavior.md
|-- checklists/
|   `-- requirements.md
`-- tasks.md
```

### Source Code (repository root)

```text
direcao_financeira_mobile/lib/
`-- app/
    |-- core/
    |   |-- bindings/
    |   |-- notifications/
    |   `-- platform/
    |-- data/
    |   |-- datasources/
    |   |-- models/
    |   `-- repositories/
    |-- domain/
    |   |-- entities/
    |   |-- repositories/
    |   |-- services/
    |   `-- usecases/
    `-- presentation/
        |-- modules/
        |   |-- credit_cards/
        |   `-- settings/
        `-- shared/

direcao_financeira_mobile/test/
|-- app/
|   |-- domain/
|   |-- data/
|   `-- presentation/
`-- support/

direcao_financeira_mobile/android/app/src/main/
|-- AndroidManifest.xml
`-- kotlin/com/example/direcao_financeira_mobile/
```

**Structure Decision**: Criar um servico/aplicacao de notificacoes em `core/notifications` apenas para orquestracao de plugin/plataforma; manter elegibilidade, calendario de faturas e dedupe em `domain`; persistencia local concreta em `data`; usar bindings globais existentes para registrar o agendador.

## Layer Responsibilities

### Presentation

- Exibir feedback de permissao quando notificacoes Android estiverem bloqueadas.
- Se houver entrada em Settings, manter a tela como composicao macro e delegar secoes a widgets.
- Controllers apenas chamam use cases de status/reagendamento e refletem estado para a UI.

### Domain

- Definir `InvoiceNotificationCandidate`, `InvoiceNotificationType` e `InvoiceNotificationDispatchRecord`.
- Calcular elegibilidade para fechamento, vencimento e atraso usando estado de fatura/cartao.
- Gerar chaves de dedupe por usuario/cartao/ciclo/tipo/dia.
- Decidir quando uma fatura paga deixa de gerar avisos.

### Data

- Implementar datasource local para registros de notificacao enviados/agendados.
- Adaptar dados de cartao/fatura existentes para o contrato do dominio.
- Encapsular `flutter_local_notifications` e detalhes Android em uma implementacao concreta.

## Testing Strategy

### Domain Tests

- Elegibilidade para fatura vencida com valor pendente.
- Interrupcao de avisos quando a fatura e paga/zerada.
- Avisos de fechamento e vencimento as 10h conforme dias cadastrados.
- Mes sem dia cadastrado usa ultimo dia valido.
- Dedupe por cartao, ciclo, tipo e dia.
- Priorizacao/consolidacao quando fechamento e vencimento caem na mesma data.

### Data Tests

- Persistencia e leitura de registros de aviso local.
- Mapeamento de cartoes/faturas para candidatos de notificacao.
- Idempotencia de agendamento/reagendamento.
- Tratamento de permissao ausente sem quebrar fluxo principal.

### Presentation Tests

- Controller/estado de Settings ou feedback, se uma superficie visual for adicionada.
- Mensagens de permissao de notificacao quando bloqueada.

## Responsiveness Strategy

- A feature nao introduz tela principal nova.
- Qualquer ajuste em Settings deve seguir os componentes existentes e preservar layouts compactos.
- Textos de permissao devem quebrar linha sem overflow em telas pequenas.

## Phase 0: Research

Concluido em [research.md](./research.md). Decisoes principais:

- Usar notificacao local Android, nao Firebase.
- Usar `zonedSchedule` com `timezone` para horario local as 10h.
- Planejar `SCHEDULE_EXACT_ALARM` como decisao de implementacao se a validacao exigir precisao exata; caso contrario usar modo inexato mais compativel com Play Store.
- Reagendar na abertura do app, apos mudancas de cartao/fatura e apos boot/update.
- Persistir dedupe local para evitar repeticoes no mesmo dia.

## Phase 1: Design & Contracts

Concluido em:

- [data-model.md](./data-model.md)
- [contracts/notification-behavior.md](./contracts/notification-behavior.md)
- [quickstart.md](./quickstart.md)

## Constitution Check - Post-Design

- Camadas preservadas: PASS.
- Regras de negocio no dominio: PASS.
- Data encapsula plugin/local storage: PASS.
- Presentation minima e GetX apenas para estado visivel: PASS.
- Testes por camada definidos: PASS.
- Sem violacoes que exijam justificativa: PASS.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
