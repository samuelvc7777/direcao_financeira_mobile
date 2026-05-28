import 'package:intl/intl.dart';

import '../entities/invoice_notification_entity.dart';

class InvoiceNotificationTextFormatter {
  InvoiceNotificationTextFormatter({NumberFormat? currencyFormat})
    : _currencyFormat =
          currencyFormat ??
          NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  final NumberFormat _currencyFormat;

  String titleFor(InvoiceNotificationCandidateDraft draft) {
    switch (draft.type) {
      case InvoiceNotificationType.overdue:
        return 'Fatura vencida';
      case InvoiceNotificationType.closing:
        return 'Fatura fechou hoje';
      case InvoiceNotificationType.dueToday:
        return 'Fatura vence hoje';
    }
  }

  String bodyFor(InvoiceNotificationCandidateDraft draft) {
    final amount = _currencyFormat.format(draft.amountCents / 100);
    switch (draft.type) {
      case InvoiceNotificationType.overdue:
        return '${draft.cardName}: $amount em aberto. Regularize para parar os avisos diarios.';
      case InvoiceNotificationType.closing:
        return '${draft.cardName}: sua fatura fechou. Confira os lancamentos antes do vencimento.';
      case InvoiceNotificationType.dueToday:
        return '${draft.cardName}: $amount vence hoje. Evite juros pagando a fatura.';
    }
  }
}

class InvoiceNotificationCandidateDraft {
  const InvoiceNotificationCandidateDraft({
    required this.cardName,
    required this.type,
    required this.amountCents,
  });

  final String cardName;
  final InvoiceNotificationType type;
  final int amountCents;
}
