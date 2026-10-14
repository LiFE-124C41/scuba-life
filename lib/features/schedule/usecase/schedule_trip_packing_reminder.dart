import '../../../core/notification/domain/entities/app_notification_item.dart';
import '../../../core/notification/domain/entities/notification_settings.dart';
import '../../../core/notification/domain/notification_id_generator.dart';
import '../../../core/notification/domain/repositories/notification_repository.dart';
import '../../../core/notification/domain/repositories/notification_settings_repository.dart';
import '../../../core/usecase/usecase.dart';
import '../../my_gear/domain/entities/gear_item.dart';
import '../domain/entities/dive_schedule.dart';

/// トリップ前日準備リマインダーの登録パラメータ
class ScheduleTripPackingReminderParams {
  final DiveSchedule schedule;
  final List<GearItem>? registeredGear;
  final DateTime? currentDate;
  final NotificationSettings? settings;

  const ScheduleTripPackingReminderParams({
    required this.schedule,
    this.registeredGear,
    this.currentDate,
    this.settings,
  });
}

/// トリップ前日準備（パッキング・チェックリスト）リマインダーをスケジュール登録するユースケース
class ScheduleTripPackingReminder
    implements UseCase<void, ScheduleTripPackingReminderParams> {
  final NotificationRepository notificationRepository;
  final NotificationSettingsRepository settingsRepository;

  ScheduleTripPackingReminder({
    required this.notificationRepository,
    required this.settingsRepository,
  });

  @override
  Future<void> call(ScheduleTripPackingReminderParams params) async {
    final schedule = params.schedule;
    final notificationId =
        NotificationIdGenerator.forSchedule(schedule.id);

    final settings =
        params.settings ?? await settingsRepository.loadSettings();

    // 通知が無効化されている場合はキャンセルして終了
    if (!settings.notificationsEnabled || !settings.tripReminderEnabled) {
      await notificationRepository.cancelNotification(notificationId);
      return;
    }

    final now = params.currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      schedule.eventDate.year,
      schedule.eventDate.month,
      schedule.eventDate.day,
    );

    // ダイビング予定日当日をすでに過ぎている場合は通知をキャンセル
    if (eventDay.isBefore(today)) {
      await notificationRepository.cancelNotification(notificationId);
      return;
    }

    // 前日の指定時刻（デフォルト 18:00）
    final reminderDate = DateTime(
      schedule.eventDate.year,
      schedule.eventDate.month,
      schedule.eventDate.day - 1,
      settings.tripReminderHour,
      0,
    );

    // 持参対象機材件数とチェック完了件数の計算
    final int totalCount;
    final int checkedCount = schedule.checkedGearCount;

    if (schedule.targetGearIds != null) {
      totalCount = schedule.targetGearIds!.length;
    } else if (params.registeredGear != null) {
      totalCount = params.registeredGear!.length;
    } else {
      totalCount = checkedCount;
    }

    final String body;
    if (totalCount > 0) {
      body =
          '『${schedule.title}』の機材チェックリストは $checkedCount/$totalCount 完了しています。忘れ物はありませんか？';
    } else {
      body =
          '明日はいよいよ『${schedule.title}』です。ダイビングの持ち物や必要書類を最終確認しましょう！';
    }

    final item = AppNotificationItem(
      id: notificationId,
      title: '【明日はダイビング予定日です】${schedule.title}',
      body: body,
      scheduledDate: reminderDate,
      payload: 'schedule:${schedule.id}',
    );

    // すでに前日の通知時刻を過ぎており、かつ当日前の場合は即時通知
    if (reminderDate.isBefore(now)) {
      if (today.isBefore(eventDay)) {
        await notificationRepository.showNotification(item);
      }
    } else {
      // 未来の予定としてスケジュール登録
      await notificationRepository.scheduleNotification(item);
    }
  }
}

/// トリップ前日準備リマインダーをキャンセルするユースケース
class CancelTripPackingReminder implements UseCase<void, String> {
  final NotificationRepository notificationRepository;

  CancelTripPackingReminder(this.notificationRepository);

  @override
  Future<void> call(String scheduleId) async {
    final notificationId =
        NotificationIdGenerator.forSchedule(scheduleId);
    await notificationRepository.cancelNotification(notificationId);
  }
}
