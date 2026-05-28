# Data Model: Pagamento total ou parcial de fatura

## InvoicePaymentMode

- `total`
- `partial`

### Purpose

Representa a escolha do usuario antes da confirmacao do pagamento.

### Rules

- `total` sempre paga o saldo em aberto inteiro.
- `partial` exige valor positivo e menor que o saldo em aberto.

## InvoicePaymentChoice

### Fields

- `bankAccountId: int`
- `creditCardId: int`
- `mode: InvoicePaymentMode`
- `amountCents: int?`
- `payableInvoiceCents: int`

### Purpose

Agrupa a decisao que sai da UI e entra na camada de dominio para validacao e posterior envio ao use case.

### Rules

- Quando `mode` for `total`, `amountCents` pode ser omitido na UI e deve ser resolvido para `payableInvoiceCents`.
- Quando `mode` for `partial`, `amountCents` deve vir preenchido e validado.

## InvoicePaymentValidationResult

### Fields

- `isValid: bool`
- `errorMessage: String?`
- `resolvedAmountCents: int?`

### Purpose

Representa o resultado da validacao de negocio antes da chamada ao use case.

### Rules

- Se o valor informado for invalido, `isValid` deve ser `false` e `errorMessage` deve explicar o motivo.
- Se o valor for valido, `resolvedAmountCents` deve conter o valor final a ser pago.

## State transitions

1. Usuario escolhe a conta.
2. Usuario escolhe `total` ou `partial`.
3. Se `partial`, usuario informa o valor.
4. O dominio valida a escolha.
5. O controller chama `CreateInvoicePaymentUseCase` com o valor resolvido.
6. A dashboard e a tela de cartoes sao atualizadas apos sucesso.

## Relationships

- `InvoicePaymentChoice` referencia uma `BankAccountEntity` e uma `CreditCardEntity`.
- `InvoicePaymentValidationResult` e consumido pelo controller e pelo fluxo de UI.
