import '../entities/credit_card_entity.dart';
import '../entities/invoice_notification_entity.dart';
import '../repositories/i_credit_card_repository.dart';
import '../repositories/i_invoice_notification_repository.dart';
import '../services/app_clock.dart';
import '../services/invoice_notification_candidate_builder.dart';
import '../services/invoice_notification_dedupe_service.dart';
import '../../core/notifications/invoice_notification_scheduler.dart';
import '../../core/preferences/app_preferences.dart';

const invoiceNotificationsEnabledPreferenceKey = 'invoiceNotificationsEnabled';

class RescheduleInvoiceNotificationsUseCase {
  RescheduleInvoiceNotificationsUseCase({
    required IInvoiceNotificationRepository repository,
    required InvoiceNotificationScheduler scheduler,
    required InvoiceNotificationCandidateBuilder candidateBuilder,
    required InvoiceNotificationDedupeService dedupeService,
    required AppClock clock,
    required AppPreferences preferences,
  }) : _repository = repository,
       _scheduler = scheduler,
       _candidateBuilder = candidateBuilder,
       _dedupeService = dedupeService,
       _clock = clock,
       _preferences = preferences;

  final IInvoiceNotificationRepository _repository;
  final InvoiceNotificationScheduler _scheduler;
  final InvoiceNotificationCandidateBuilder _candidateBuilder;
  final InvoiceNotificationDedupeService _dedupeService;
  final AppClock _clock;
  final AppPreferences _preferences;

  Future<void> call(List<CreditCardEntity> cards) async {
    if (_preferences.readBool(invoiceNotificationsEnabledPreferenceKey) ==
        false) {
      return;
    }

    final now = _clock.now();
    final candidates = _candidateBuilder.buildCandidates(
      cards: cards,
      now: now,
    );
    final records = await _repository.getRecords();
    final cardIds = cards.map((card) => card.id).toSet();
    final candidateKeys = candidates
        .map((candidate) => candidate.dedupeKey)
        .toSet();
    final staleRecords = records.where((record) {
      return cardIds.contains(record.cardId) &&
          record.status == InvoiceNotificationDispatchStatus.scheduled &&
          !candidateKeys.contains(record.dedupeKey);
    }).toList();
    if (staleRecords.isNotEmpty) {
      await _scheduler.cancelMany(
        staleRecords.map((record) => record.notificationId),
      );
      await _repository.removeRecordsByKeys(
        staleRecords.map((record) => record.dedupeKey),
      );
    }

    final staleKeys = staleRecords.map((record) => record.dedupeKey).toSet();
    final freshRecords = records
        .where((record) => !staleKeys.contains(record.dedupeKey))
        .toList();
    final pending = _dedupeService.filterPending(
      candidates: candidates,
      records: freshRecords,
    );

    for (final candidate in pending) {
      await _scheduler.schedule(candidate);
    }

    await _repository.saveRecords(
      pending.map((candidate) {
        return InvoiceNotificationDispatchRecord(
          dedupeKey: candidate.dedupeKey,
          notificationId: candidate.notificationId,
          cardId: candidate.cardId,
          type: candidate.type,
          eventDate: candidate.eventDate,
          scheduledAt: candidate.scheduledAt,
          status: InvoiceNotificationDispatchStatus.scheduled,
          updatedAt: now,
        );
      }),
    );

    await _repository.cleanupBefore(now.subtract(const Duration(days: 45)));
  }
}

class CancelInvoiceNotificationsUseCase {
  CancelInvoiceNotificationsUseCase({
    required IInvoiceNotificationRepository repository,
    required InvoiceNotificationScheduler scheduler,
  }) : _repository = repository,
       _scheduler = scheduler;

  final IInvoiceNotificationRepository _repository;
  final InvoiceNotificationScheduler _scheduler;

  Future<void> call() async {
    final records = await _repository.getRecords();
    final scheduledRecords = records.where((record) {
      return record.status == InvoiceNotificationDispatchStatus.scheduled;
    }).toList();
    if (scheduledRecords.isEmpty) {
      return;
    }

    await _scheduler.cancelMany(
      scheduledRecords.map((record) => record.notificationId),
    );
    await _repository.removeRecordsByKeys(
      scheduledRecords.map((record) => record.dedupeKey),
    );
  }
}

class RefreshInvoiceNotificationsUseCase {
  RefreshInvoiceNotificationsUseCase({
    required ICreditCardRepository creditCardRepository,
    required RescheduleInvoiceNotificationsUseCase rescheduleUseCase,
  }) : _creditCardRepository = creditCardRepository,
       _rescheduleUseCase = rescheduleUseCase;

  final ICreditCardRepository _creditCardRepository;
  final RescheduleInvoiceNotificationsUseCase _rescheduleUseCase;

  Future<void> call() async {
    final result = await _creditCardRepository.getCreditCards();
    await result.fold((_) async {}, (cards) => _rescheduleUseCase(cards));
  }
}

class SetInvoiceNotificationsEnabledUseCase {
  SetInvoiceNotificationsEnabledUseCase({
    required AppPreferences preferences,
    required CancelInvoiceNotificationsUseCase cancelUseCase,
    required RefreshInvoiceNotificationsUseCase refreshUseCase,
  }) : _preferences = preferences,
       _cancelUseCase = cancelUseCase,
       _refreshUseCase = refreshUseCase;

  final AppPreferences _preferences;
  final CancelInvoiceNotificationsUseCase _cancelUseCase;
  final RefreshInvoiceNotificationsUseCase _refreshUseCase;

  Future<void> call(bool enabled) async {
    await _preferences.writeBool(
      invoiceNotificationsEnabledPreferenceKey,
      enabled,
    );

    if (enabled) {
      await _refreshUseCase();
      return;
    }

    await _cancelUseCase();
  }
}
