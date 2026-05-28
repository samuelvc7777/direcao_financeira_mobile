import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../domain/services/credit_card_invoice_calculator.dart';
import '../../../datasources/credit_card_datasource.dart';
import '../../../models/credit_card_model.dart';
import '../shared/supabase_table_names.dart';
import '../shared/supabase_user_scope.dart';

class SupabaseCreditCardRemoteDataSource implements ICreditCardDataSource {
  SupabaseCreditCardRemoteDataSource({required this.client})
    : userScope = SupabaseUserScope(client: client),
      invoiceCalculator = const CreditCardInvoiceCalculator();

  final SupabaseClient client;
  final SupabaseUserScope userScope;
  final CreditCardInvoiceCalculator invoiceCalculator;

  @override
  Future<List<CreditCardModel>> getCreditCards() async {
    final userId = await userScope.getCurrentUserId();
    final rawCards = await client
        .from(SupabaseTableNames.creditCards)
        .select()
        .eq('userId', userId)
        .order('createdAt');
    final cards = (rawCards as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    if (cards.isEmpty) {
      return const [];
    }

    final cardIds = cards.map((card) => card['id'] as int).toList();
    final rawInvoices = await client
        .from(SupabaseTableNames.creditCardInvoices)
        .select('creditCardId,closingDate,dueDate,totalCents,paidCents')
        .inFilter('creditCardId', cardIds);
    final rawLegacyTransactions = await client
        .from(SupabaseTableNames.transactions)
        .select(
          'creditCardId,invoiceId,type,amountCents,transactionDate,installmentNumber,installmentCount',
        )
        .eq('userId', userId)
        .inFilter('creditCardId', cardIds)
        .isFilter('invoiceId', null);

    final invoicesByCard = <int, List<CreditCardPersistedInvoice>>{};
    for (final item in rawInvoices as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final cardId = row['creditCardId'] as int?;
      final closingDate = DateTime.tryParse(row['closingDate']?.toString() ?? '');
      final dueDate = DateTime.tryParse(row['dueDate']?.toString() ?? '');
      if (cardId == null || closingDate == null || dueDate == null) {
        continue;
      }

      invoicesByCard.putIfAbsent(cardId, () => []).add(
        CreditCardPersistedInvoice(
          totalCents: row['totalCents'] as int? ?? 0,
          paidCents: row['paidCents'] as int? ?? 0,
          closingDate: closingDate,
          dueDate: dueDate,
        ),
      );
    }

    final legacyByCard = <int, List<CreditCardInvoiceEntry>>{};
    for (final item in rawLegacyTransactions as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final cardId = row['creditCardId'] as int?;
      if (cardId == null) {
        continue;
      }

      final type = row['type']?.toString().toUpperCase() ?? 'EXPENSE';
      legacyByCard.putIfAbsent(cardId, () => []).add(
        CreditCardInvoiceEntry(
          type: type == 'INCOME'
              ? CreditCardInvoiceEntryType.income
              : CreditCardInvoiceEntryType.expense,
          amountCents: row['amountCents'] as int? ?? 0,
          transactionDate: DateTime.tryParse(
                row['transactionDate']?.toString() ?? '',
              ) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          installmentNumber: row['installmentNumber'] as int?,
          installmentCount: row['installmentCount'] as int?,
        ),
      );
    }

    final now = DateTime.now();
    return cards.map((row) {
      final cardId = row['id'] as int;
      final limit = row['limitCents'] as int? ?? 0;
      final persistedSummary = invoiceCalculator.summarizePersistedInvoices(
        invoices: invoicesByCard[cardId] ?? const [],
        now: now,
      );
      final legacySummary = invoiceCalculator.calculate(
        entries: legacyByCard[cardId] ?? const [],
        closingDay: row['closingDay'] as int? ?? 1,
        dueDay: row['dueDay'] as int? ?? 1,
        now: now,
      );
      final summary = _mergeInvoiceSummaries(
        persisted: persistedSummary,
        legacy: legacySummary,
      );
      final available = (limit - summary.outstandingBalanceCents)
          .clamp(0, limit)
          .toInt();

      return CreditCardModel.fromJson({
        ...row,
        'availableLimitCents': available,
        'openInvoiceCents': summary.openInvoiceCents,
        'closedInvoiceCents': summary.closedInvoiceCents,
        'payableInvoiceCents': summary.payableInvoiceCents,
        'openInvoiceClosingDate': summary.openInvoiceClosingDate
            ?.toIso8601String(),
        'nextDueDate': summary.nextDueDate?.toIso8601String(),
        'isInvoiceDueToday': summary.isInvoiceDueToday,
        'isInvoiceOverdue': summary.isInvoiceOverdue,
      });
    }).toList();
  }

  @override
  Future<CreditCardModel> createCreditCard({
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
  }) async {
    final userId = await userScope.getCurrentUserId();
    final now = DateTime.now().toUtc().toIso8601String();
    final inserted = await client
        .from(SupabaseTableNames.creditCards)
        .insert({
          'userId': userId,
          'name': name,
          'brand': brand,
          'color': color,
          'limitCents': limitCents,
          'availableLimitCents': limitCents,
          'closingDay': closingDay,
          'dueDay': dueDay,
          'lastFourDigits': lastFourDigits,
          'isActive': true,
          'updatedAt': now,
        })
        .select()
        .single();

    return CreditCardModel.fromJson(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<CreditCardModel> updateCreditCard({
    required int id,
    required String name,
    required String brand,
    required String color,
    required int limitCents,
    required int closingDay,
    required int dueDay,
    required String lastFourDigits,
    bool? isActive,
  }) async {
    final current = await client
        .from(SupabaseTableNames.creditCards)
        .select()
        .eq('id', id)
        .single();
    final currentRow = Map<String, dynamic>.from(current);

    final currentSummary = await _loadCardSummary(
      cardId: id,
      closingDay: currentRow['closingDay'] as int? ?? 1,
      dueDay: currentRow['dueDay'] as int? ?? 1,
    );

    final payload = <String, dynamic>{
      'name': name,
      'brand': brand,
      'color': color,
      'limitCents': limitCents,
      'availableLimitCents':
          (limitCents - currentSummary.outstandingBalanceCents)
              .clamp(0, limitCents)
              .toInt(),
      'closingDay': closingDay,
      'dueDay': dueDay,
      'lastFourDigits': lastFourDigits,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    if (isActive != null) {
      payload['isActive'] = isActive;
    }

    final updated = await client
        .from(SupabaseTableNames.creditCards)
        .update(payload)
        .eq('id', id)
        .select()
        .single();

    return CreditCardModel.fromJson(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> deactivateCreditCard(int id) async {
    await client
        .from(SupabaseTableNames.creditCards)
        .update({
          'isActive': false,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  @override
  Future<void> reactivateCreditCard(int id) async {
    await client
        .from(SupabaseTableNames.creditCards)
        .update({
          'isActive': true,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<CreditCardInvoiceSummary> _loadCardSummary({
    required int cardId,
    required int closingDay,
    required int dueDay,
  }) async {
    final rawInvoices = await client
        .from(SupabaseTableNames.creditCardInvoices)
        .select('closingDate,dueDate,totalCents,paidCents')
        .eq('creditCardId', cardId);
    final rawLegacyTransactions = await client
        .from(SupabaseTableNames.transactions)
        .select(
          'type,amountCents,transactionDate,installmentNumber,installmentCount',
        )
        .eq('creditCardId', cardId)
        .isFilter('invoiceId', null);

    final persistedSummary = invoiceCalculator.summarizePersistedInvoices(
      invoices: (rawInvoices as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(
            (row) => CreditCardPersistedInvoice(
              totalCents: row['totalCents'] as int? ?? 0,
              paidCents: row['paidCents'] as int? ?? 0,
              closingDate:
                  DateTime.tryParse(row['closingDate']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              dueDate:
                  DateTime.tryParse(row['dueDate']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
            ),
          )
          .toList(),
      now: DateTime.now(),
    );

    final legacySummary = invoiceCalculator.calculate(
      entries: (rawLegacyTransactions as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .map(
            (row) => CreditCardInvoiceEntry(
              type: (row['type']?.toString().toUpperCase() ?? 'EXPENSE') ==
                      'INCOME'
                  ? CreditCardInvoiceEntryType.income
                  : CreditCardInvoiceEntryType.expense,
              amountCents: row['amountCents'] as int? ?? 0,
              transactionDate:
                  DateTime.tryParse(row['transactionDate']?.toString() ?? '') ??
                  DateTime.fromMillisecondsSinceEpoch(0),
              installmentNumber: row['installmentNumber'] as int?,
              installmentCount: row['installmentCount'] as int?,
            ),
          )
          .toList(),
      closingDay: closingDay,
      dueDay: dueDay,
      now: DateTime.now(),
    );

    return _mergeInvoiceSummaries(
      persisted: persistedSummary,
      legacy: legacySummary,
    );
  }

  static CreditCardInvoiceSummary _mergeInvoiceSummaries({
    required CreditCardInvoiceSummary persisted,
    required CreditCardInvoiceSummary legacy,
  }) {
    DateTime? firstDate(DateTime? left, DateTime? right) {
      if (left == null) {
        return right;
      }
      if (right == null) {
        return left;
      }
      return left.isBefore(right) ? left : right;
    }

    return CreditCardInvoiceSummary(
      openInvoiceCents: persisted.openInvoiceCents + legacy.openInvoiceCents,
      closedInvoiceCents:
          persisted.closedInvoiceCents + legacy.closedInvoiceCents,
      payableInvoiceCents:
          persisted.payableInvoiceCents + legacy.payableInvoiceCents,
      outstandingBalanceCents:
          persisted.outstandingBalanceCents + legacy.outstandingBalanceCents,
      openInvoiceClosingDate: firstDate(
        persisted.openInvoiceClosingDate,
        legacy.openInvoiceClosingDate,
      ),
      nextDueDate: firstDate(persisted.nextDueDate, legacy.nextDueDate),
      isInvoiceDueToday:
          persisted.isInvoiceDueToday || legacy.isInvoiceDueToday,
      isInvoiceOverdue: persisted.isInvoiceOverdue || legacy.isInvoiceOverdue,
    );
  }
}
