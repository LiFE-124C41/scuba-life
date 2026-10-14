import '../../../core/notification/domain/entities/app_notification_item.dart';
import '../../../core/notification/domain/entities/notification_settings.dart';
import '../../../core/notification/domain/notification_id_generator.dart';
import '../../../core/notification/domain/repositories/notification_repository.dart';
import '../../../core/notification/domain/repositories/notification_settings_repository.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/entities/gear_item.dart';

/// 機材OHリマインダーの登録パラメータ
class ScheduleGearOverhaulReminderParams {
  final GearItem gear;
  final DateTime? currentDate;
  final NotificationSettings? settings;

  const ScheduleGearOverhaulReminderParams({
    required this.gear,
    this.currentDate,
    this.settings,
  });
}

/// 機材のオーバーホール推奨時期リマインダーをスケジュール登録するユースケース
class ScheduleGearOverhaulReminder
    implements UseCase<void, ScheduleGearOverhaulReminderParams> {
  final NotificationRepository notificationRepository;
  final NotificationSettingsRepository settingsRepository;

  ScheduleGearOverhaulReminder({
    required this.notificationRepository,
    required this.settingsRepository,
  });

  @override
  Future<void> call(ScheduleGearOverhaulReminderParams params) async {
    final gear = params.gear;
    final notificationId = NotificationIdGenerator.forGear(gear.id);

    // OH対象外の機材の場合は通知をキャンセルして終了
    if (!gear.requiresOverhaul) {
      await notificationRepository.cancelNotification(notificationId);
      return;
    }

    final settings =
        params.settings ?? await settingsRepository.loadSettings();

    // 通知が無効化されている場合はキャンセルして終了
    if (!settings.notificationsEnabled ||
        !settings.gearOverhaulReminderEnabled) {
      await notificationRepository.cancelNotification(notificationId);
      return;
    }

    final now = params.currentDate ?? DateTime.now();
    final nextOH = gear.nextOverhaulDate;
    final daysBefore = settings.overhaulDaysBefore;

    // 通知予定日: 次回OH日の daysBefore 日前の午前9:00
    final targetDate = DateTime(
      nextOH.year,
      nextOH.month,
      nextOH.day - daysBefore,
      9,
      0,
    );

    final status = gear.calculateStatus(now);
    final daysRemaining = gear.calculateDaysUntilOverhaul(now);
    final divesRemaining = gear.calculateDivesUntilOverhaul();

    // すでに警告状態（30日以内またはダイブ本数逼迫）または期限超過の場合
    if (status == OverhaulStatus.overdue) {
      final item = AppNotificationItem(
        id: notificationId,
        title: '【機材メンテナンス】${gear.name}のOH推奨時期を過ぎています',
        body: '『${gear.name}』の点検目安日を経過しています。安全なダイビングのためにオーバーホールをご検討ください。',
        scheduledDate: now,
        payload: 'gear:${gear.id}',
      );
      await notificationRepository.showNotification(item);
    } else if (status == OverhaulStatus.warning) {
      final divesText =
          divesRemaining != null ? '（推奨ダイブ本数まで残り$divesRemaining本）' : '';
      final item = AppNotificationItem(
        id: notificationId,
        title: '【機材メンテナンス】${gear.name}の次回OH目安が近づいています',
        body:
            '『${gear.name}』の次回OH目安まであと$daysRemaining日$divesTextです。安全なダイビングのために点検をご検討ください。',
        scheduledDate: now,
        payload: 'gear:${gear.id}',
      );
      await notificationRepository.showNotification(item);
    } else {
      // 良好（good）の場合: daysBefore日前の午前9:00にスケジュール
      if (targetDate.isAfter(now)) {
        final item = AppNotificationItem(
          id: notificationId,
          title: '【機材メンテナンス】${gear.name}の次回OH目安まであと$daysBefore日です',
          body:
              '『${gear.name}』の定期オーバーホール目安が近づいています。安全なダイビングのために点検をご検討ください。',
          scheduledDate: targetDate,
          payload: 'gear:${gear.id}',
        );
        await notificationRepository.scheduleNotification(item);
      }
    }
  }
}

/// 機材のOHリマインダー通知をキャンセルするユースケース
class CancelGearOverhaulReminder implements UseCase<void, String> {
  final NotificationRepository notificationRepository;

  CancelGearOverhaulReminder(this.notificationRepository);

  @override
  Future<void> call(String gearId) async {
    final notificationId = NotificationIdGenerator.forGear(gearId);
    await notificationRepository.cancelNotification(notificationId);
  }
}
