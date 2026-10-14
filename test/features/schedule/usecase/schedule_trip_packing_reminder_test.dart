import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/notification/domain/entities/app_notification_item.dart';
import 'package:scuba_life/core/notification/domain/entities/notification_settings.dart';
import 'package:scuba_life/core/notification/domain/notification_id_generator.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_repository.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_settings_repository.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/usecase/schedule_trip_packing_reminder.dart';

void main() {
  late InMemoryNotificationRepository notificationRepository;
  late InMemoryNotificationSettingsRepository settingsRepository;
  late ScheduleTripPackingReminder scheduleUseCase;
  late CancelTripPackingReminder cancelUseCase;

  setUp(() {
    notificationRepository = InMemoryNotificationRepository();
    settingsRepository = InMemoryNotificationSettingsRepository();
    scheduleUseCase = ScheduleTripPackingReminder(
      notificationRepository: notificationRepository,
      settingsRepository: settingsRepository,
    );
    cancelUseCase = CancelTripPackingReminder(notificationRepository);
  });

  group('ScheduleTripPackingReminder UseCase', () {
    final now = DateTime(2026, 7, 10, 10, 0); // 7月10日 午前10:00
    final eventDate = DateTime(2026, 7, 20); // 7月20日 予定日

    test('ダイビング予定の前日18:00に通知がスケジュールされ、チェックリスト完了状況が反映されること', () async {
      final schedule = DiveSchedule(
        id: 'schedule-shirahama-1',
        title: '白浜ツアー',
        eventDate: eventDate,
        destination: '白浜',
        diveShop: 'マリンクラブ',
        targetGearIds: ['g1', 'g2', 'g3', 'g4'],
        checkedGearIds: ['g1', 'g2'], // 2/4 完了
      );

      await scheduleUseCase(ScheduleTripPackingReminderParams(
        schedule: schedule,
        currentDate: now,
      ));

      final expectedId = NotificationIdGenerator.forSchedule('schedule-shirahama-1');
      final scheduled = notificationRepository.scheduledNotifications[expectedId];

      expect(scheduled, isNotNull);
      expect(scheduled!.id, equals(expectedId));
      expect(scheduled.title, contains('白浜ツアー'));
      expect(scheduled.body, contains('2/4 完了'));
      expect(scheduled.scheduledDate, equals(DateTime(2026, 7, 19, 18, 0))); // 前日18:00
      expect(notificationRepository.shownNotifications, isEmpty);
    });

    test('targetGearIdsが未指定（null）の場合、registeredGearの全件数に対するチェック数が反映されること', () async {
      final schedule = DiveSchedule(
        id: 'schedule-all-gear',
        title: '伊豆大島遠征',
        eventDate: eventDate,
        destination: '秋の浜',
        diveShop: '大島ダイビング',
        checkedGearIds: ['g1'],
      );

      final dummyGears = [
        GearItem(id: 'g1', name: 'Mask', category: GearCategory.maskSnorkelFin, purchaseDate: DateTime(2026, 1, 1)),
        GearItem(id: 'g2', name: 'Fin', category: GearCategory.maskSnorkelFin, purchaseDate: DateTime(2026, 1, 1)),
        GearItem(id: 'g3', name: 'BCD', category: GearCategory.bcd, purchaseDate: DateTime(2026, 1, 1)),
      ];

      await scheduleUseCase(ScheduleTripPackingReminderParams(
        schedule: schedule,
        registeredGear: dummyGears,
        currentDate: now,
      ));

      final expectedId = NotificationIdGenerator.forSchedule('schedule-all-gear');
      final scheduled = notificationRepository.scheduledNotifications[expectedId];

      expect(scheduled, isNotNull);
      expect(scheduled!.body, contains('1/3 完了'));
    });

    test('現在日時が前日18:00を過ぎておりダイビング当日以前の場合、即時リマインダー通知が表示されること', () async {
      final schedule = DiveSchedule(
        id: 'schedule-tomorrow',
        title: '三浦半島ボート',
        eventDate: DateTime(2026, 7, 12),
        destination: '宮川湾',
        diveShop: '三浦Diving',
        targetGearIds: ['g1', 'g2'],
        checkedGearIds: ['g1'],
      );

      // 前日 7月11日の20:00 (18:00を過ぎている)
      final nightBefore = DateTime(2026, 7, 11, 20, 0);

      await scheduleUseCase(ScheduleTripPackingReminderParams(
        schedule: schedule,
        currentDate: nightBefore,
      ));

      expect(notificationRepository.shownNotifications, hasLength(1));
      final shown = notificationRepository.shownNotifications.first;
      expect(shown.title, contains('三浦半島ボート'));
      expect(shown.body, contains('1/2 完了'));
    });

    test('予定日当日をすでに過ぎている過去の予定の場合、スケジュールされずキャンセルされること', () async {
      final schedule = DiveSchedule(
        id: 'schedule-past',
        title: '昨日のダイビング',
        eventDate: DateTime(2026, 7, 5),
        destination: '熱海',
        diveShop: '熱海マリン',
      );

      final expectedId = NotificationIdGenerator.forSchedule('schedule-past');
      await notificationRepository.scheduleNotification(
        AppNotificationItem(
          id: expectedId,
          title: 'dummy',
          body: 'dummy',
          scheduledDate: DateTime(2026, 7, 4, 18, 0),
        ),
      );

      await scheduleUseCase(ScheduleTripPackingReminderParams(
        schedule: schedule,
        currentDate: now, // 7月10日
      ));

      expect(notificationRepository.scheduledNotifications.containsKey(expectedId), isFalse);
      expect(notificationRepository.shownNotifications, isEmpty);
    });

    test('通知設定でトリップリマインダーが無効の場合、スケジュールされずキャンセルされること', () async {
      final schedule = DiveSchedule(
        id: 'schedule-disabled',
        title: '沖縄ツアー',
        eventDate: eventDate,
        destination: '慶良間',
        diveShop: '那覇ダイブ',
      );

      await settingsRepository.saveSettings(
        const NotificationSettings(tripReminderEnabled: false),
      );

      await scheduleUseCase(ScheduleTripPackingReminderParams(
        schedule: schedule,
        currentDate: now,
      ));

      expect(notificationRepository.scheduledNotifications, isEmpty);
      expect(notificationRepository.shownNotifications, isEmpty);
    });
  });

  group('CancelTripPackingReminder UseCase', () {
    test('指定予定IDに対応する通知スケジュールがキャンセルされること', () async {
      final id = NotificationIdGenerator.forSchedule('schedule-cancel-test');
      await notificationRepository.scheduleNotification(
        AppNotificationItem(
          id: id,
          title: 'dummy',
          body: 'dummy',
          scheduledDate: DateTime(2026, 8, 1, 18, 0),
        ),
      );

      expect(notificationRepository.scheduledNotifications.containsKey(id), isTrue);

      await cancelUseCase('schedule-cancel-test');

      expect(notificationRepository.scheduledNotifications.containsKey(id), isFalse);
    });
  });
}
