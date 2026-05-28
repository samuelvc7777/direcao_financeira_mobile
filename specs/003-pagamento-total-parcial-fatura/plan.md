# Implementation Plan: Pagamento total ou parcial de fatura

**Branch**: `[003-pagamento-total-parcial-fatura]` | **Date**: 2026-05-27 | **Spec**: [`spec.md`](./spec.md)
**Input**: Feature specification from `/specs/003-pagamento-total-parcial-fatura/spec.md`

## Summary

Adicionar um fluxo unico de pagamento de fatura com tres passos claros: escolher a conta, escolher entre pagamento total ou parcial e, se parcial, informar o valor. O fluxo deve ser compartilhado entre os pontos de entrada existentes, reaproveitar `CreateInvoicePaymentUseCase` e o datasource atual, e manter a validacao do parcial fora da view/controller.

## Technical Context

**Language/Version**: Dart 3.11.1 / Flutter 3.x  
**Primary Dependencies**: Flutter, GetX, intl, dartz, Supabase via os repositorios/datasources atuais, widgets compartilhados do app  
**Storage**: Supabase transactions table via `TransactionDataSource` e `SupabaseTransactionRemoteDatasource`; nao ha novo schema previsto  
**Testing**: `flutter_test`, testes de controller, widget/presentation e novo teste de servico de dominio  
**Target Platform**: Mobile Android e iOS  
**Project Type**: mobile-app  
**Performance Goals**: manter o fluxo curto, evitar rebuilds desnecessarios e atualizar dashboard/cartoes uma unica vez apos sucesso  
**Constraints**: preservar Clean Architecture, manter GetX como estado de presentation, isolar regra de negocio fora de view/controller e reusar o fluxo de pagamento existente sem duplicar contrato de backend  
**Scale/Scope**: mudanca de feature/screen flow em presentation, domain e testes

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Does the plan preserve `presentation`, `domain` and `data` boundaries? Sim.
- Are `bindings`, `controllers`, `use cases`, `repositories` and `datasources` assigned to the correct layer? Sim.
- Will GetX remain the source of presentation state where stateful behavior exists? Sim.
- Are views/pages restricted to macro structure while visual composition is extracted into smaller widgets? Sim.
- Are business rules isolated from views, widgets, bindings and controllers? Sim.
- Does the feature include a testing strategy compatible with the touched layers? Sim.
- Does the feature preserve responsiveness for the affected screens? Sim.

## Project Structure

### Documentation (this feature)

```text
specs/003-pagamento-total-parcial-fatura/
|-- plan.md
|-- research.md
|-- data-model.md
|-- quickstart.md
`-- contracts/
    `-- invoice-payment-flow.md
```

### Source Code (repository root)

```text
lib/
`-- app/
    |-- domain/
    |   |-- entities/
    |   |-- repositories/
    |   |-- services/
    |   `-- usecases/
    |-- data/
    |   |-- datasources/
    |   |-- models/
    |   |-- providers/
    |   `-- repositories/
    `-- presentation/
        `-- modules/
            |-- home/
            |   |-- home_controller.dart
            |   `-- widgets/
            |       `-- credit_cards_section.dart
            `-- credit_cards/
                |-- credit_cards_view.dart
                `-- widgets/
                    `-- credit_cards_content.dart

test/
`-- app/
    |-- domain/
    |   `-- services/
    `-- presentation/
        `-- modules/
            `-- home/
```

**Structure Decision**: Manter a mudanca concentrada nos modulos existentes e extrair um fluxo compartilhado de pagamento para evitar divergencia entre a home e a tela de cartoes.

## Layer Responsibilities

### Presentation

- Views continuam responsaveis pela estrutura macro da tela.
- O fluxo de pagamento deve ser extraido para widgets auxiliares reutilizaveis.
- Controllers recebem a decisao final de pagamento e executam a chamada de dominio.
- Bindings continuam sendo o ponto de composicao das dependencias da feature.

### Domain

- A validacao do valor parcial deve ficar no dominio.
- O dominio deve resolver quando o valor informado e valido para pagamento parcial e quando o fluxo deve ser bloqueado.
- Use cases continuam responsaveis por registrar o pagamento com o valor final escolhido.

### Data

- O datasource e o repositorio atuais ja aceitam `amountCents`, entao nao ha necessidade de novo contrato de persistencia.
- A camada de dados apenas registra a saida da conta e a entrada no cartao com o valor recebido do dominio/presentation.

## Testing Strategy

### Domain Tests

- Validar a regra de pagamento parcial: valor maior que zero, menor que o saldo em aberto e rejeicao de valores invalidos.

### Data Tests

- Nao ha novo contrato de dados previsto; se o fluxo mudar, os testes existentes de repository/datasource devem continuar verdes.

### Presentation Tests

- Cobrir o estado e a transicao do controller para pagamento total e parcial.
- Cobrir o fluxo de UI para escolha de conta, escolha total/parcial e captura do valor parcial.
- Garantir que o estado de loading e o feedback de sucesso/erro continuem consistentes.

## Responsiveness Strategy

- O fluxo novo deve caber em bottom sheets e dialogs com scroll quando a tela for pequena.
- Os widgets extraidos nao devem assumir largura fixa para a area de entrada do valor parcial.
- A home e a tela de cartoes devem manter a composicao atual e so adicionar o CTA ou modal necessario para iniciar o fluxo.

## Complexity Tracking

Nenhuma violacao estrutural adicional foi necessaria nesta etapa.
