# Implementation Plan: Bloqueio por assinatura vigente

**Branch**: `010-bloqueio-assinatura` | **Date**: 2026-05-28 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `C:\Users\Samuel Vitor\Documents\aplicativos\direcao_financeira\direcao_financeira_mobile\specs\010-bloqueio-assinatura\spec.md`

## Summary

Implementar um bloqueio de acoes protegidas no app mobile quando o usuario nao possui assinatura vigente, preservando navegacao, logout e acesso a ver plano/ver assinatura. A regra de acesso deve partir da assinatura vigente no dominio, reaproveitando `SubscriptionEntity.grantsAccess`, que ja considera `ACTIVE`, `TRIAL` e `CANCELED` com `endDate` futura. A presentation deve expor uma guarda compartilhada para interceptar comandos protegidos e exibir um banner premium reutilizavel, visualmente alinhado a referencia enviada. O painel admin permanece fora do escopo deste bloqueio.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x  
**Primary Dependencies**: Flutter, GetX, dartz, GetStorage, Supabase/Nest via repositorios existentes, componentes visuais atuais do app  
**Storage**: assinatura atual em cache de usuario e fonte remota de assinatura via `ISubscriptionRepository`; nenhum novo schema previsto  
**Testing**: `flutter_test`, testes de dominio, controller e widget conforme camadas tocadas  
**Target Platform**: Android principal, mantendo compatibilidade visual com mobile/tablet suportado pelo app  
**Project Type**: mobile-app  
**Performance Goals**: interceptar toque protegido imediatamente quando o estado ja estiver carregado; evitar multiplos banners sobrepostos; nao causar rebuild global desnecessario  
**Constraints**: manter regra de negocio fora de views/controllers; preservar GetX como estado de presentation; nao bloquear bottom navigation, logout e ver plano; nao alterar painel admin  
**Scale/Scope**: guarda de assinatura compartilhada no app mobile, banner premium reutilizavel e aplicacao incremental nos principais comandos protegidos das telas atuais

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Does the plan preserve `presentation`, `domain` and `data` boundaries? **Passa**. Regra de acesso fica em entidade/servico/use case de dominio; UI apenas consome decisao.
- Are `bindings`, `controllers`, `use cases`, `repositories` and `datasources` assigned to the correct layer? **Passa**. Binding registra dependencias; controller/guarda coordena clique; repositorios atuais seguem como fonte de assinatura.
- Will GetX remain the source of presentation state where stateful behavior exists? **Passa**. Estado de carregamento/bloqueio/banner sera exposto por controller/servico GetX.
- Are views/pages restricted to macro structure while visual composition is extracted into smaller widgets? **Passa**. Banner premium sera widget dedicado; views apenas envolvem acoes protegidas.
- Are business rules isolated from views, widgets, bindings and controllers? **Passa**. `grantsAccess` e decisao de elegibilidade ficam fora dos widgets.
- Does the feature include a testing strategy compatible with the touched layers? **Passa**. Plano inclui testes de dominio, guarda/controller e widget.
- Does the feature preserve responsiveness for the affected screens? **Passa**. Banner sera responsivo e testado em largura compacta.

## Project Structure

### Documentation (this feature)

```text
specs/010-bloqueio-assinatura/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
|-- contracts/
|   `-- premium-access-ui-contract.md
`-- tasks.md
```

### Source Code (repository root)

```text
lib/
`-- app/
    |-- domain/
    |   |-- entities/
    |   |   `-- subscription_entity.dart
    |   |-- services/
    |   |   `-- premium_access_policy.dart
    |   `-- usecases/
    |       `-- subscription_access_use_cases.dart
    |-- presentation/
    |   |-- modules/
    |   |   |-- initial/
    |   |   |-- home/
    |   |   |-- transactions/
    |   |   |-- journey/
    |   |   `-- settings/
    |   `-- widgets/
    |       |-- premium_access_guard.dart
    |       `-- premium_access_banner.dart
    `-- core/
        `-- bindings/
            `-- core_binding.dart

test/
|-- domain/
|   `-- services/
|       `-- premium_access_policy_test.dart
|-- presentation/
|   `-- widgets/
|       `-- premium_access_guard_test.dart
|-- settings/
|   |-- settings_controller_test.dart
|   `-- settings_view_test.dart
`-- presentation/
    `-- controllers/
        `-- controller_contract_test.dart
```

**Structure Decision**: Criar componentes compartilhados somente quando necessario para evitar duplicacao entre Home, Transacoes, Jornada e Ajustes. A primeira preferencia e reaproveitar `SubscriptionEntity.grantsAccess`; se faltar expressividade, adicionar um servico de dominio pequeno em vez de espalhar comparacoes de status/data pela UI.

## Layer Responsibilities

### Presentation

- Expor um `PremiumAccessGuard`/controller compartilhado para receber a intencao de clique protegido e decidir entre executar a acao original ou exibir o banner.
- Manter `InitialView` e bottom navigation livres do bloqueio.
- Manter `SettingsProfileCard.openSubscription` e `SettingsController.logout` livres do bloqueio.
- Extrair `PremiumAccessBanner` como composicao visual reutilizavel, responsiva e alinhada ao tema escuro/dourado da referencia.
- Aplicar a guarda em botoes/comandos protegidos nas telas principais, sem transformar cada view em dona da regra de assinatura.

### Domain

- Reaproveitar `SubscriptionEntity.grantsAccess` como criterio de direito vigente.
- Se necessario, criar `PremiumAccessPolicy` para centralizar a decisao `allowed`, `blocked`, `unknown/loading` e evitar duplicacao em controllers.
- Se necessario, criar use case para ler usuario armazenado, opcionalmente consultar assinatura atual e retornar uma decisao de acesso para a presentation.
- Garantir que cancelamento dentro do periodo vigente continue liberado.

### Data

- Reusar `IAuthRepository.getStoredUser`, `ISubscriptionRepository.getMySubscription` e `ISubscriptionRepository.syncStoredUser`.
- Nao criar tabela, endpoint ou campo novo.
- Apenas ajustar mapeamentos/testes se for encontrada divergencia real entre dados de assinatura remotos e `SubscriptionEntity`.

## Testing Strategy

### Domain Tests

- `SubscriptionEntity.grantsAccess`/`PremiumAccessPolicy` libera `ACTIVE`, `TRIAL` e `CANCELED` com `endDate` futura.
- Bloqueia assinatura ausente, status nao elegivel e `endDate` vencida.
- Cobre limite de data atual para evitar bloqueio indevido antes do fim do periodo.

### Data Tests

- Manter testes existentes de `SubscriptionRepository` e adicionar caso apenas se o plano exigir novo fluxo de sincronizacao.
- Validar que `syncStoredUser` continua atualizando assinatura ativa quando a fonte remota retorna dados atuais.

### Presentation Tests

- Guarda executa callback protegido quando acesso e liberado.
- Guarda nao executa callback protegido e exibe banner quando acesso e bloqueado.
- Toques repetidos nao empilham banners.
- Bottom navigation continua trocando abas com usuario bloqueado.
- Botao "Ver plano" continua navegando para `AppRoutes.subscription`.
- Logout continua funcionando.
- Settings e telas principais aplicam guarda a acoes protegidas sem bloquear navegacao.

## Responsiveness Strategy

- Banner premium deve usar largura maxima, padding responsivo e rolagem/ajuste seguro em telas pequenas.
- Textos do banner devem quebrar linha sem overflow e CTA deve manter area de toque confortavel.
- O banner deve ser testado em largura compacta e com escala de texto aumentada.
- Views continuam responsaveis pela estrutura macro; o banner e secoes internas ficam em widgets menores.

## Phase 0 - Research

Resolvido em [research.md](./research.md).

## Phase 1 - Design & Contracts

Artefatos gerados:

- [data-model.md](./data-model.md)
- [quickstart.md](./quickstart.md)
- [premium-access-ui-contract.md](./contracts/premium-access-ui-contract.md)

## Constitution Check - Post-Design

- Camadas continuam separadas: regra de acesso no dominio, guarda/banner na presentation e dados por repositorios existentes.
- Nao ha novo schema nem contrato administrativo.
- A feature preserva GetX para estado de presentation e usa widgets extraidos para composicao visual.
- Testes planejados cobrem dominio, presentation e regressao dos caminhos liberados.

## Complexity Tracking

Nenhuma violacao constitucional prevista.
