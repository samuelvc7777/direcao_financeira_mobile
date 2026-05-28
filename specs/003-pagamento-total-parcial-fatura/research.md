# Research: Pagamento total ou parcial de fatura

## Decision 1: Reaproveitar o contrato atual de pagamento

- Decision: usar `CreateInvoicePaymentUseCase` e o datasource atual, que ja recebem `amountCents`.
- Rationale: o backend e a camada de dados ja aceitam um valor arbitrario; o novo comportamento e principalmente de UI e validacao.
- Alternatives considered: criar um novo use case ou novo endpoint para pagamento parcial. Rejeitado porque aumentaria o escopo sem necessidade tecnica.

## Decision 2: Tratar a regra de parcial no dominio

- Decision: mover a validacao de valor parcial para um servico de dominio dedicado.
- Rationale: a regra "valor maior que zero e menor que o saldo em aberto" e negocio, nao uma regra de tela.
- Alternatives considered: validar direto no controller ou no bottom sheet. Rejeitado por conflitar com a constituicao do projeto.

## Decision 3: Compartilhar o fluxo entre os pontos de entrada

- Decision: criar um fluxo compartilhado de UI para selecao de conta, escolha total/parcial e captura de valor.
- Rationale: o contrato precisa ser o mesmo na home e na tela de cartoes; duplicar telas aumentaria o risco de divergencia.
- Alternatives considered: manter dois fluxos separados. Rejeitado porque dificultaria manutencao e regressao consistente.

## Decision 4: Manter a estrutura visual da home e da tela de cartoes

- Decision: preservar a composicao atual e encaixar o novo fluxo como widget auxiliar ou bottom sheet.
- Rationale: a feature nao exige reestruturar a pagina inteira; basta adicionar o novo passo e o CTA necessario.
- Alternatives considered: refatorar as telas inteiras. Rejeitado por ser mais invasivo do que o problema pede.

## Observations from the codebase

- A home ja tem o botao de pagar fatura em `lib/app/presentation/modules/home/widgets/credit_cards_section.dart`.
- O datasource de transacao em `lib/app/data/providers/supabase/finance/supabase_transaction_remote_datasource.dart` insere a saida da conta e a entrada do cartao com o mesmo `amountCents`.
- A tela de cartoes separada em `lib/app/presentation/modules/credit_cards/widgets/credit_cards_content.dart` mostra o resumo dos cartoes, mas nao expoe hoje um CTA de pagamento equivalente ao da home.
