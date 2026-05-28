# Tasks: Pagamento total ou parcial de fatura

**Input**: Design documents from `/specs/003-pagamento-total-parcial-fatura/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Esta feature deve incluir testes automatizados nas camadas tocadas, principalmente dominio e presentation.

**Organization**: As tarefas estao agrupadas por user story para permitir entrega e validacao independentes sempre que possivel.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Pode rodar em paralelo com outras tarefas sem dependencia direta de arquivo
- **[Story]**: US1, US2, US3
- Caminhos devem ser reais e apontar para arquivos existentes do projeto

---

## Phase 1: Setup (Shared Structure)

**Purpose**: Preparar os pontos de extensao do fluxo compartilhado sem quebrar as fronteiras de arquitetura

- [X] T001 Mapear os pontos de entrada reais do pagamento em `lib/app/presentation/modules/home/widgets/credit_cards_section.dart` e `lib/app/presentation/modules/credit_cards/widgets/credit_cards_content.dart` para orientar o fluxo compartilhado (a rota atual usa `lib/app/presentation/modules/credit_cards/credit_cards_view.dart`)
- [X] T002 [P] Criar a estrutura de widgets compartilhados para o fluxo de pagamento em `lib/app/presentation/modules/home/widgets/` ou `lib/app/presentation/modules/credit_cards/widgets/`, conforme o encaixe do fluxo unico
- [X] T003 [P] Criar a estrutura de dominio para validacao do pagamento parcial em `lib/app/domain/services/`
- [X] T004 [P] Preparar paths de teste espelhados em `test/app/domain/services/` e `test/app/presentation/modules/home/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Base que precisa existir antes de concluir qualquer user story

- [X] T005 Definir o servico de dominio para validar pagamento total/parcial em `lib/app/domain/services/invoice_payment_validator.dart`
- [X] T006 [P] Definir o contrato de retorno da validacao no dominio com suporte a valor resolvido e mensagem de erro em `lib/app/domain/services/invoice_payment_validator.dart`
- [X] T007 [P] Atualizar ou criar o widget compartilhado do fluxo de pagamento para selecionar conta, tipo de pagamento e valor parcial em `lib/app/presentation/modules/home/widgets/`
- [X] T008 Atualizar o `home_controller` para aceitar o valor final resolvido do fluxo em `lib/app/presentation/modules/home/home_controller.dart`
- [X] T009 Atualizar o binding da home se algum novo helper ou servico precisar ser registrado em `lib/app/presentation/modules/home/home_binding.dart`

**Checkpoint**: a base do fluxo compartilhado e da validacao precisa estar pronta antes de fechar cada historia

---

## Phase 3: User Story 1 - Escolher tipo de pagamento (Priority: P1)

**Goal**: Ao tocar em pagar na home ou na tela de cartoes, o usuario ve a escolha entre pagamento total e parcial depois de selecionar a conta

**Independent Test**: Abrir a home e a tela de cartoes, acionar pagar e confirmar que os dois pontos de entrada levam ao mesmo fluxo de selecao de conta + escolha total/parcial

### Tests for User Story 1

- [X] T010 [P] [US1] Criar teste de presentation para o fluxo compartilhado da home em `test/app/presentation/modules/home/home_controller_test.dart`
- [X] T011 [P] [US1] Criar teste de widget para o componente de escolha de conta e modo de pagamento em `test/app/presentation/modules/home/widgets/`

### Implementation for User Story 1

- [X] T012 [US1] Atualizar a acao de pagamento na home para abrir o fluxo compartilhado em `lib/app/presentation/modules/home/widgets/credit_cards_section.dart`
- [X] T013 [US1] Expor o mesmo fluxo de pagamento na tela de cartoes em `lib/app/presentation/modules/credit_cards/widgets/credit_cards_content.dart` (implementado no ponto renderizado atual: `lib/app/presentation/modules/credit_cards/credit_cards_view.dart`)
- [X] T014 [US1] Implementar o widget compartilhado de selecao de conta e escolha total/parcial em `lib/app/presentation/modules/home/widgets/`
- [X] T015 [US1] Garantir que o controller receba a conta escolhida e encaminhe a continuidade do fluxo em `lib/app/presentation/modules/home/home_controller.dart`

**Checkpoint**: o usuario consegue chegar no mesmo fluxo a partir dos dois pontos de entrada

---

## Phase 4: User Story 2 - Pagar valor parcial (Priority: P2)

**Goal**: Quando o usuario escolhe pagamento parcial, ele informa um valor valido e o sistema confirma apenas esse valor

**Independent Test**: Escolher pagamento parcial, informar um valor menor que o saldo em aberto e confirmar que o valor resolvido segue para o pagamento

### Tests for User Story 2

- [X] T016 [P] [US2] Criar teste unitario para o servico de validacao de pagamento parcial em `test/app/domain/services/invoice_payment_validator_test.dart`
- [X] T017 [P] [US2] Criar teste de controller cobrindo o envio do valor parcial validado em `test/app/presentation/modules/home/home_controller_test.dart`

### Implementation for User Story 2

- [X] T018 [US2] Implementar a validacao de valor parcial maior que zero e menor que o saldo em aberto em `lib/app/domain/services/invoice_payment_validator.dart`
- [X] T019 [US2] Integrar o resultado da validacao ao controller da home antes de chamar o use case em `lib/app/presentation/modules/home/home_controller.dart`
- [X] T020 [US2] Ajustar o fluxo compartilhado para exibir campo de valor apenas quando o usuario escolher pagamento parcial em `lib/app/presentation/modules/home/widgets/`
- [X] T021 [US2] Reusar `CreateInvoicePaymentUseCase` com o `amountCents` resolvido pelo dominio em `lib/app/domain/usecases/transaction_use_cases.dart`

**Checkpoint**: o pagamento parcial valido pode ser confirmado e o invalido e bloqueado antes da confirmacao

---

## Phase 5: User Story 3 - Manter o fluxo de pagamento coerente (Priority: P3)

**Goal**: Depois da confirmacao, a interface mostra sucesso e a fatura permanece aberta com o saldo restante atualizado quando o pagamento for parcial

**Independent Test**: Concluir um pagamento total e um parcial, verificar feedback de sucesso e conferir atualizacao dos cards/estado visual

### Tests for User Story 3

- [X] T022 [P] [US3] Expandir a cobertura de presentation para sucesso, erro e refresh apos pagamento em `test/app/presentation/modules/home/home_controller_test.dart`
- [X] T023 [P] [US3] Garantir que o calculo visual da fatura continua coerente apos pagamento parcial em `test/app/domain/services/credit_card_invoice_calculator_test.dart` se algum ajuste for necessario

### Implementation for User Story 3

- [X] T024 [US3] Atualizar o feedback de sucesso/erro do controller para distinguir pagamento total e parcial em `lib/app/presentation/modules/home/home_controller.dart`
- [X] T025 [US3] Garantir refresh de dashboard e lista de cartoes apos confirmacao bem-sucedida em `lib/app/presentation/modules/home/home_controller.dart`
- [X] T026 [US3] Ajustar a representacao visual da fatura para deixar claro quando ela segue aberta com saldo remanescente em `lib/app/presentation/modules/home/widgets/credit_cards_section.dart`

**Checkpoint**: a experiencia mostra sucesso claro e o estado da fatura fica consistente depois da confirmacao

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Ajustes finais de integracao, responsividade e consistencia

- [X] T027 [P] Validar responsividade do fluxo compartilhado em telas pequenas e medias em `lib/app/presentation/modules/home/widgets/`
- [X] T028 [P] Revisar responsabilidades entre view, widget e controller para remover qualquer regra de negocio acidental em `lib/app/presentation/modules/home/` e `lib/app/presentation/modules/credit_cards/`
- [X] T029 Executar os testes automatizados das camadas afetadas e corrigir regressões em `test/app/domain/services/` e `test/app/presentation/modules/home/`
- [X] T030 Atualizar documentacao de uso se o novo fluxo alterar a navegação ou a forma de pagar fatura em `specs/003-pagamento-total-parcial-fatura/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: pode iniciar imediatamente
- **Foundational (Phase 2)**: depende do setup, bloqueia as user stories
- **User Stories (Phase 3+)**: dependem da base funcional e de validacao
- **Polish (Phase 6)**: depende de todas as historias alvo concluídas

### Within Each User Story

- Domínio antes do controller final
- Controller antes da exposição final do widget
- Widget compartilhado antes da duplicação de entrada em outra tela
- Testes devem acompanhar a camada tocada

### Parallel Opportunities

- T002, T003 e T004 podem ocorrer em paralelo
- T010 e T011 podem ocorrer em paralelo
- T016 e T017 podem ocorrer em paralelo
- T022 e T023 podem ocorrer em paralelo

## Implementation Strategy

### MVP First

1. Fechar setup e base do fluxo compartilhado
2. Entregar a escolha total/parcial funcionando pelos dois pontos de entrada
3. Adicionar a validacao de parcial no dominio
4. Garantir feedback e refresh apos confirmacao

### Incremental Delivery

1. Primeiro o fluxo unico de entrada
2. Depois a validacao do parcial
3. Por fim o refinamento visual e os testes complementares

## Notes

- Evitar duplicar o fluxo em home e tela de cartoes
- Nao mover regra de negocio para widget ou controller
- Reaproveitar `CreateInvoicePaymentUseCase` e o contrato de transacao atual
