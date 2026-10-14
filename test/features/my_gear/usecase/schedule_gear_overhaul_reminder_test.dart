import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/notification/domain/entities/app_notification_item.dart';
import 'package:scuba_life/core/notification/domain/entities/notification_settings.dart';
import 'package:scuba_life/core/notification/domain/notification_id_generator.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_repository.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_settings_repository.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/usecase/schedule_gear_overhaul_reminder.dart';

void main() {
  late InMemoryNotificationRepository notificationRepository;
  late InMemoryNotificationSettingsRepository settingsRepository;
  late ScheduleGearOverhaulReminder scheduleUseCase;
  late CancelGearOverhaulReminder cancelUseCase;

  setUp(() {
    notificationRepository = InMemoryNotificationRepository();
    settingsRepository = InMemoryNotificationSettingsRepository();
    scheduleUseCase = ScheduleGearOverhaulReminder(
      notificationRepository: notificationRepository,
      settingsRepository: settingsRepository,
    );
    cancelUseCase = CancelGearOverhaulReminder(notificationRepository);
  });

  group('ScheduleGearOverhaulReminder UseCase', () {
    final baseDate = DateTime(2026, 1, 1);
    final now = DateTime(2026, 1, 1);

    test('次回OH日まで十分な余裕（60日以上）がある場合、次回OHの30日前AM9:00に通知がスケジュールされること', () async {
      final gear = GearItem(
        id: 'gear-reg-1',
        name: 'メインレギュレーター',
        category: GearCategory.regulator,
        purchaseDate: baseDate,
        overhaulIntervalMonths: 12, // 次回OH: 2027-01-01
        divesSinceOverhaul: 0,
        overhaulIntervalDives: 100,
      );

      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: now,
      ));

      final expectedId = NotificationIdGenerator.forGear('gear-reg-1');
      final scheduled = notificationRepository.scheduledNotifications[expectedId];

      expect(scheduled, isNotNull);
      expect(scheduled!.id, equals(expectedId));
      expect(scheduled.title, contains('次回OH目安まであと30日です'));
      expect(scheduled.scheduledDate, equals(DateTime(2026, 12, 2, 9, 0))); // 2027/1/1 の30日前
      expect(notificationRepository.shownNotifications, isEmpty);
    });

    test('OH期限まで残り30日以内の場合、即時警告通知が表示されること', () async {
      // 次回OH: 2026-06-01、現在日: 2026-05-15 (残り17日)
      final gear = GearItem(
        id: 'gear-bcd-1',
        name: 'アクアラング BCD',
        category: GearCategory.bcd,
        purchaseDate: DateTime(2025, 6, 1),
        overhaulIntervalMonths: 12,
        divesSinceOverhaul: 10,
        overhaulIntervalDives: 100,
      );

      final currentDate = DateTime(2026, 5, 15);
      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: currentDate,
      ));

      final expectedId = NotificationIdGenerator.forGear('gear-bcd-1');
      expect(notificationRepository.shownNotifications, hasLength(1));
      final shown = notificationRepository.shownNotifications.first;
      expect(shown.id, equals(expectedId));
      expect(shown.title, contains('次回OH目安が近づいています'));
      expect(shown.body, contains('あと17日'));
      expect(shown.body, contains('残り90本'));
    });

    test('ダイブ本数が残り10本以下（警告）の場合、即時警告通知が表示されること', () async {
      final gear = GearItem(
        id: 'gear-reg-warning-dives',
        name: 'エイペックス レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: baseDate,
        overhaulIntervalMonths: 12,
        divesSinceOverhaul: 95,
        overhaulIntervalDives: 100, // 残り5本
      );

      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: now,
      ));

      expect(notificationRepository.shownNotifications, hasLength(1));
      final shown = notificationRepository.shownNotifications.first;
      expect(shown.title, contains('次回OH目安が近づいています'));
      expect(shown.body, contains('残り5本'));
    });

    test('OH期限超過（overdue）の場合、期限超過通知が即時送信されること', () async {
      final gear = GearItem(
        id: 'gear-overdue-1',
        name: '古いレギュレーター',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2024, 1, 1),
        overhaulIntervalMonths: 12, // 2025-01-01 期限
        divesSinceOverhaul: 10,
      );

      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: now, // 2026-01-01 (1年超過)
      ));

      expect(notificationRepository.shownNotifications, hasLength(1));
      final shown = notificationRepository.shownNotifications.first;
      expect(shown.title, contains('OH推奨時期を過ぎています'));
    });

    test('定期OH不要な機材（マスク等）の場合、通知はスケジュールされず既存通知がキャンセルされること', () async {
      final gear = GearItem(
        id: 'gear-mask-1',
        name: 'マンティス5 マスク',
        category: GearCategory.maskSnorkelFin,
        purchaseDate: baseDate,
      );

      // 事前にダミー通知を入れておく
      final expectedId = NotificationIdGenerator.forGear('gear-mask-1');
      await notificationRepository.scheduleNotification(
        AppNotificationItem(
          id: expectedId,
          title: 'dummy',
          body: 'dummy',
          scheduledDate: DateTime(2027, 1, 1),
        ),
      );

      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: now,
      ));

      expect(notificationRepository.scheduledNotifications.containsKey(expectedId), isFalse);
      expect(notificationRepository.shownNotifications, isEmpty);
    });

    test('通知設定でOHリマインダーが無効化されている場合、スケジュールされずにキャンセルされること', () async {
      final gear = GearItem(
        id: 'gear-disabled-1',
        name: 'レギュレーター',
        category: GearCategory.regulator,
        purchaseDate: baseDate,
      );

      await settingsRepository.saveSettings(
        const NotificationSettings(gearOverhaulReminderEnabled: false),
      );

      await scheduleUseCase(ScheduleGearOverhaulReminderParams(
        gear: gear,
        currentDate: now,
      ));

      expect(notificationRepository.scheduledNotifications, isEmpty);
      expect(notificationRepository.shownNotifications, isEmpty);
    });
  });

  group('CancelGearOverhaulReminder UseCase', () {
    test('指定機材IDに対応する通知スケジュールがキャンセルされること', () async {
      final id = NotificationIdGenerator.forGear('gear-to-cancel');
      await notificationRepository.scheduleNotification(
        AppNotificationItem(
          id: id,
          title: 'dummy',
          body: 'dummy',
          scheduledDate: DateTime(2027, 1, 1),
        ),
      );

      expect(notificationRepository.scheduledNotifications.containsKey(id), isTrue);

      await cancelUseCase('gear-to-cancel');

      expect(notificationRepository.scheduledNotifications.containsKey(id), isFalse);
    });
  });
}
