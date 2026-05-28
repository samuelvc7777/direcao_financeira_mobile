enum InvoicePaymentMode { total, partial }

class InvoicePaymentChoice {
  const InvoicePaymentChoice({
    required this.bankAccountId,
    required this.creditCardId,
    required this.mode,
    required this.payableInvoiceCents,
    this.amountCents,
  });

  final int bankAccountId;
  final int creditCardId;
  final InvoicePaymentMode mode;
  final int payableInvoiceCents;
  final int? amountCents;
}

class InvoicePaymentValidationResult {
  const InvoicePaymentValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.resolvedAmountCents,
  });

  factory InvoicePaymentValidationResult.valid(int resolvedAmountCents) {
    return InvoicePaymentValidationResult._(
      isValid: true,
      resolvedAmountCents: resolvedAmountCents,
    );
  }

  factory InvoicePaymentValidationResult.invalid(String message) {
    return InvoicePaymentValidationResult._(
      isValid: false,
      errorMessage: message,
    );
  }

  final bool isValid;
  final String? errorMessage;
  final int? resolvedAmountCents;
}

class InvoicePaymentValidator {
  const InvoicePaymentValidator();

  InvoicePaymentValidationResult validate(InvoicePaymentChoice choice) {
    if (choice.payableInvoiceCents <= 0) {
      return InvoicePaymentValidationResult.invalid(
        'Nao ha fatura vencendo para este cartao.',
      );
    }

    switch (choice.mode) {
      case InvoicePaymentMode.total:
        return InvoicePaymentValidationResult.valid(choice.payableInvoiceCents);
      case InvoicePaymentMode.partial:
        final amountCents = choice.amountCents;
        if (amountCents == null || amountCents <= 0) {
          return InvoicePaymentValidationResult.invalid(
            'Informe um valor parcial maior que zero.',
          );
        }
        if (amountCents >= choice.payableInvoiceCents) {
          return InvoicePaymentValidationResult.invalid(
            'O pagamento parcial deve ser menor que o saldo em aberto.',
          );
        }

        return InvoicePaymentValidationResult.valid(amountCents);
    }
  }
}
