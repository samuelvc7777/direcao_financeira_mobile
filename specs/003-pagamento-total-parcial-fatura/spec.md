# Feature Specification: Pagamento total ou parcial de fatura

**Feature Branch**: `[003-pagamento-total-parcial-fatura]`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "vamos adicionar opção de pagamento parcial da fatura na hora de pagar, seja na tela de cartes ou na tela inicial, ao clicar em pagar sera exibido opção de pagamento total ou parcial"

## Clarifications

### Session 2026-05-27

- Q: Em que ordem o usuário escolhe conta, total/parcial e valor parcial? → A: Primeiro escolhe a conta, depois escolhe entre pagamento total ou parcial; se for parcial, informa quanto pagou.
- Q: O que acontece com o saldo quando o pagamento é parcial? → A: O valor restante continua na mesma fatura atual, sem migrar para a próxima fatura.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Escolher tipo de pagamento (Priority: P1)

Como usuário, quero tocar em pagar a fatura a partir da tela inicial ou da tela de cartões e ver uma escolha entre pagamento total e parcial, para decidir rapidamente como quitar a fatura sem navegar por caminhos diferentes.

**Why this priority**: essa é a entrada principal da mudança e concentra o valor imediato da feature.

**Independent Test**: abrir a tela inicial ou a tela de cartões, tocar em pagar e verificar se a mesma escolha entre total e parcial aparece nos dois pontos de entrada.

**Acceptance Scenarios**:

1. **Given** uma fatura em aberto visível na tela inicial, **When** o usuário toca em pagar, **Then** o sistema exibe a escolha entre pagamento total e parcial.
2. **Given** uma fatura em aberto visível na tela de cartões, **When** o usuário toca em pagar, **Then** o sistema exibe a mesma escolha entre pagamento total e parcial.

---

### User Story 2 - Pagar valor parcial (Priority: P2)

Como usuário, quero escolher pagamento parcial e informar quanto desejo pagar, para quitar apenas uma parte da fatura quando não quiser ou não puder pagar o valor inteiro.

**Why this priority**: o pagamento parcial é a diferença funcional central desta solicitação.

**Independent Test**: escolher a opção parcial, informar um valor válido e confirmar que o pagamento segue com esse valor.

**Acceptance Scenarios**:

1. **Given** uma fatura em aberto com valor restante maior que zero, **When** o usuário escolhe pagamento parcial e informa um valor válido menor que o saldo em aberto, **Then** o sistema permite confirmar o pagamento.
2. **Given** uma fatura em aberto, **When** o usuário informa um valor inválido para pagamento parcial, **Then** o sistema impede a confirmação e orienta o usuário a corrigir o valor.

---

### User Story 3 - Manter o fluxo de pagamento coerente (Priority: P3)

Como usuário, quero receber feedback claro depois de confirmar o pagamento total ou parcial, para saber se a ação foi concluída e qual ficou sendo o saldo restante.

**Why this priority**: o feedback final reduz erro e evita incerteza após a confirmação.

**Independent Test**: confirmar um pagamento total ou parcial e verificar se a interface mostra sucesso e o estado da fatura reflete o novo saldo.

**Acceptance Scenarios**:

1. **Given** uma confirmação bem-sucedida, **When** o pagamento termina, **Then** o sistema mostra feedback claro de sucesso.
2. **Given** um pagamento parcial concluído, **When** a tela é atualizada, **Then** a fatura continua aberta com o valor restante atualizado.

---

### Edge Cases

- O que acontece quando o usuário toca em pagar sem existir fatura em aberto.
- O que acontece quando o usuário escolhe pagamento parcial e informa zero, negativo, vazio ou um valor maior que o saldo em aberto.
- O que acontece quando o valor parcial informado coincide com o valor total da fatura.
- O que acontece quando a fatura está em estado de carregamento, erro ou atualização pendente.
- O que acontece quando o usuário cancela a escolha antes de confirmar.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: O sistema MUST permitir iniciar o pagamento da fatura tanto pela tela inicial quanto pela tela de cartões.
- **FR-002**: Ao tocar em pagar, o sistema MUST permitir ao usuário escolher a conta de origem antes de definir o tipo de pagamento.
- **FR-003**: Depois da escolha da conta, o sistema MUST exibir uma escolha explícita entre pagamento total e pagamento parcial.
- **FR-004**: A mesma escolha de pagamento MUST estar disponível independentemente do ponto de entrada usado pelo usuário.
- **FR-005**: Ao selecionar pagamento total, o sistema MUST preparar o fluxo para quitar o valor integral em aberto da fatura.
- **FR-006**: Ao selecionar pagamento parcial, o sistema MUST solicitar um valor a pagar antes de permitir a confirmação.
- **FR-007**: O sistema MUST validar que o valor parcial seja maior que zero e menor que o saldo em aberto.
- **FR-008**: O sistema MUST impedir a confirmação quando o valor parcial for inválido.
- **FR-009**: Após uma confirmação bem-sucedida, o sistema MUST atualizar o estado visual da fatura para refletir o pagamento realizado.
- **FR-010**: Quando o usuário pagar apenas parte da fatura, o sistema MUST manter a fatura aberta com o saldo restante atualizado na mesma fatura atual.
- **FR-011**: Quando não houver fatura em aberto, o sistema MUST não oferecer a escolha de pagamento total ou parcial e MUST informar o usuário de forma clara.

### Key Entities *(include if feature involves data)*

- **Fatura do cartão**: registro do valor em aberto que pode ser quitado total ou parcialmente.
- **Saldo em aberto**: valor restante que ainda precisa ser pago na fatura.
- **Opção de pagamento**: escolha do usuário entre quitar tudo ou pagar apenas uma parte.
- **Pagamento de fatura**: ação confirmada pelo usuário para registrar o valor pago.

### Business Rules *(include when relevant)*

- **BR-001**: Pagamento total sempre corresponde ao saldo integral em aberto da fatura.
- **BR-002**: Pagamento parcial só pode ser confirmado com valor maior que zero e menor que o saldo em aberto.
- **BR-003**: O fluxo de pagamento deve manter a escolha da conta antes da escolha entre total e parcial.
- **BR-004**: O mesmo comportamento de escolha entre total e parcial deve aparecer tanto na tela inicial quanto na tela de cartões.
- **BR-005**: Se o usuário cancelar antes da confirmação, nenhuma alteração deve ser aplicada à fatura.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: O usuário consegue acessar a mesma escolha entre pagamento total e parcial a partir dos dois pontos de entrada previstos.
- **SC-002**: Um pagamento parcial válido pode ser concluído e deixa a fatura com saldo restante atualizado.
- **SC-003**: Um pagamento total válido pode ser concluído sem alterar o fluxo de entrada já existente além da nova escolha inicial.
- **SC-004**: Valores inválidos para pagamento parcial são bloqueados com feedback claro antes da confirmação.
- **SC-005**: Após a confirmação, o usuário consegue identificar de forma clara se a fatura foi quitada integralmente ou apenas reduzida.

## Assumptions

- A feature vai reutilizar o fluxo de pagamento já existente e apenas acrescentar a escolha entre total e parcial no início da ação.
- A ordem do fluxo será: escolher conta, escolher total ou parcial e, se necessário, informar o valor parcial.
- O valor parcial será informado em formato monetário já compatível com o app.
- A confirmação e a gravação do pagamento continuarão seguindo as regras atuais de negócio da fatura.
- A mesma experiência visual será aplicada aos dois pontos de entrada citados pelo usuário.
- O saldo não quitado em pagamento parcial permanece na fatura atual.
