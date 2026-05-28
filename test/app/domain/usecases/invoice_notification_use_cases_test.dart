import 'package:direcao_financeira_mobile/app/core/notifications/invoice_notification_scheduler.dart';
import 'package:direcao_financeira_mobile/app/core/preferences/app_preferences.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/credit_card_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/entities/invoice_notification_entity.dart';
import 'package:direcao_financeira_mobile/app/domain/repositories/i_invoice_notification_repository.dart';
import 'package:direcao_financeira_mobile/app/domain/services/app_clock.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_notification_candidate_builder.dart';
import 'package:direcao_financeira_mobile/app/domain/services/invoice_notification_dedupe_service.dart';
import 'package:direcao_financeira_mobile/app/domain/usecases/invoice_notification_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agenda aviso vencido e registra dedupe', () async {
    final repository = _FakeInvoiceNotificationRepository();
    final scheduler = _FakeInvoiceNotificationScheduler();
    final preferences = _FakeAppPreferences();
    final useCase = RescheduleInvoiceNotificationsUseCase(
      repository: repository,
      scheduler: scheduler,
      candidateBuilder: InvoiceNotificationCandidateBuilder(),
      dedupeService: InvoiceNotificationDedupeService(),
      clock: _FixedClock(DateTime(2026, 5, 26, 9)),
      preferences: preferences,
    );

    await useCase([
      _card(
        payableInvoiceCents: 10000,
        nextDueDate: DateTime(2026, 5, 25),
        isInvoiceOverdue: true,
      ),
    ]);

    expect(scheduler.scheduled, hasLength(1));
    expect(repository.records, hasLength(1));
    expect(repository.records.single.type, InvoiceNotificationType.overdue);
  });

  test('cancela aviso futuro quando a fatura foi paga', () async {
    final repository = _FakeInvoiceNotificationRepository();
    final scheduler = _FakeInvoiceNotificationScheduler();
    final clock = _FixedClock(DateTime(2026, 5, 26, 9));
    final preferences = _FakeAppPreferences();
    final useCase = RescheduleInvoiceNotificationsUseCase(
      repository: repository,
      scheduler: scheduler,
      candidateBuilder: InvoiceNotificationCandidateBuilder(),
      dedupeService: InvoiceNotificationDedupeService(),
      clock: clock,
      preferences: preferences,
    );
    final overdueCandidate = InvoiceNotificationCandidateBuilder()
        .buildCandidates(
          cards: [
            _card(
              payableInvoiceCents: 10000,
              nextDueDate: DateTime(2026, 5, 25),
              isInvoiceOverdue: true,
            ),
          ],
          now: clock.now(),
        )
        .single;
    repository.records.add(
      InvoiceNotificationDispatchRecord(
        dedupeKey: overdueCandidate.dedupeKey,
        notificationId: overdueCandidate.notificationId,
        cardId: overdueCandidate.cardId,
        type: overdueCandidate.type,
        eventDate: overdueCandidate.eventDate,
        scheduledAt: overdueCandidate.scheduledAt,
        status: InvoiceNotificationDispatchStatus.scheduled,
        updatedAt: clock.now(),
      ),
    );

    await useCase([
      _card(
        payableInvoiceCents: 0,
        nextDueDate: DateTime(2026, 5, 25),
        isInvoiceOverdue: false,
      ),
    ]);

    expect(scheduler.cancelled, [overdueCandidate.notificationId]);
    expect(repository.records, isEmpty);
  });

  test('nao agenda quando notificacoes de fatura estao desativadas', () async {
    final repository = _FakeInvoiceNotificationRepository();
    final scheduler = _FakeInvoiceNotificationScheduler();
    final preferences = _FakeAppPreferences()
      ..bools[invoiceNotificationsEnabledPreferenceKey] = false;
    final useCase = RescheduleInvoiceNotificationsUseCase(
      repository: repository,
      scheduler: scheduler,
      candidateBuilder: InvoiceNotificationCandidateBuilder(),
      dedupeService: InvoiceNotificationDedupeService(),
      clock: _FixedClock(DateTime(2026, 5, 26, 9)),
      preferences: preferences,
    );

    await useCase([
      _card(
        payableInvoiceCents: 10000,
        nextDueDate: DateTime(2026, 5, 25),
        isInvoiceOverdue: true,
      ),
    ]);

    expect(scheduler.scheduled, isEmpty);
    expect(repository.records, isEmpty);
  });
}

class _FixedClock implements AppClock {
  const _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _FakeInvoiceNotificationRepository
    implements IInvoiceNotificationRepository {
  final records = <InvoiceNotificationDispatchRecord>[];

  @override
  Future<void> cleanupBefore(DateTime cutoffDate) async {}

  @override
  Future<List<InvoiceNotificationDispatchRecord>> getRecords() async => records;

  @override
  Future<void> removeRecordsByKeys(Iterable<String> dedupeKeys) async {
    records.removeWhere((record) => dedupeKeys.contains(record.dedupeKey));
  }

  @override
  Future<void> saveRecord(InvoiceNotificationDispatchRecord record) async {
    records.add(record);
  }

  @override
  Future<void> saveRecords(
    Iterable<InvoiceNotificationDispatchRecord> records,
  ) async {
    this.records.addAll(records);
  }
}

class _FakeInvoiceNotificationScheduler
    implements InvoiceNotificationScheduler {
  final scheduled = <InvoiceNotificationCandidate>[];
  final cancelled = <int>[];

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }

  @override
  Future<void> cancelMany(Iterable<int> notificationIds) async {
    cancelled.addAll(notificationIds);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> schedule(InvoiceNotificationCandidate candidate) async {
    scheduled.add(candidate);
  }
}

class _FakeAppPreferences implements AppPreferences {
  final bools = <String, bool>{};

  @override
  bool? readBool(String key) => bools[key];

  @override
  double? readDouble(String key) => null;

  @override
  int? readInt(String key) => null;

  @override
  String? readString(String key) => null;

  @override
  Future<void> writeBool(String key, bool value) async {
    bools[key] = value;
  }

  @override
  Future<void> writeDouble(String key, double value) async {}

  @override
  Future<void> writeInt(String key, int value) async {}

  @override
  Future<void> writeString(String key, String value) async {}
}

CreditCardEntity _card({
  required int payableInvoiceCents,
  required DateTime nextDueDate,
  required bool isInvoiceOverdue,
}) {
  return CreditCardEntity(
    id: 1,
    name: 'Nubank',
    brand: 'Visa',
    lastFourDigits: '1234',
    color: '#8B5CF6',
    limitCents: 100000,
    availableLimitCents: 90000,
    closingDay: 20,
    dueDay: 25,
    isActive: true,
    payableInvoiceCents: payableInvoiceCents,
    nextDueDate: nextDueDate,
    isInvoiceOverdue: isInvoiceOverdue,
  );
}
