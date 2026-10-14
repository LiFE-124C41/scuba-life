import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/app_notification_item.dart';
import '../domain/entities/notification_settings.dart';
import '../domain/notification_id_generator.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/notification_settings_repository.dart';
import '../infrastructure/flutter_local_notification_repository.dart';
import '../infrastructure/in_memory_notification_settings_repository.dart';
import '../../../features/my_gear/usecase/schedule_gear_overhaul_reminder.dart';
import '../../../features/schedule/usecase/schedule_trip_packing_reminder.dart';

/// 通知リポジトリプロバイダー
final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  final repo = FlutterLocalNotificationRepository();
  return repo;
});

/// 通知設定リポジトリプロバイダー
final notificationSettingsRepositoryProvider =
    Provider<NotificationSettingsRepository>((ref) {
  return InMemoryNotificationSettingsRepository();
});

/// 機材OHリマインダースケジュール UseCase
final scheduleGearOverhaulReminderProvider =
    Provider<ScheduleGearOverhaulReminder>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final settingsRepo = ref.watch(notificationSettingsRepositoryProvider);
  return ScheduleGearOverhaulReminder(
    notificationRepository: notifRepo,
    settingsRepository: settingsRepo,
  );
});

/// 機材OHリマインダーキャンセル UseCase
final cancelGearOverhaulReminderProvider =
    Provider<CancelGearOverhaulReminder>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  return CancelGearOverhaulReminder(notifRepo);
});

/// トリップ前日準備リマインダースケジュール UseCase
final scheduleTripPackingReminderProvider =
    Provider<ScheduleTripPackingReminder>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  final settingsRepo = ref.watch(notificationSettingsRepositoryProvider);
  return ScheduleTripPackingReminder(
    notificationRepository: notifRepo,
    settingsRepository: settingsRepo,
  );
});

/// トリップ前日準備リマインダーキャンセル UseCase
final cancelTripPackingReminderProvider =
    Provider<CancelTripPackingReminder>((ref) {
  final notifRepo = ref.watch(notificationRepositoryProvider);
  return CancelTripPackingReminder(notifRepo);
});

/// 通知設定のStateクラス
class NotificationSettingsState {
  final NotificationSettings settings;
  final bool isLoading;
  final String? message;
  final Object? error;

  const NotificationSettingsState({
    this.settings = const NotificationSettings(),
    this.isLoading = false,
    this.message,
    this.error,
  });

  NotificationSettingsState copyWith({
    NotificationSettings? settings,
    bool? isLoading,
    String? message,
    Object? error,
  }) {
    return NotificationSettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      message: message,
      error: error,
    );
  }
}

/// 通知設定 Notifier
class NotificationSettingsNotifier
    extends Notifier<NotificationSettingsState> {
  @override
  NotificationSettingsState build() {
    // 初期値ロード
    Future.microtask(() => loadSettings());
    return const NotificationSettingsState(isLoading: true);
  }

  Future<void> loadSettings() async {
    try {
      final repo = ref.read(notificationSettingsRepositoryProvider);
      final settings = await repo.loadSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    try {
      state = state.copyWith(settings: newSettings);
      final repo = ref.read(notificationSettingsRepositoryProvider);
      await repo.saveSettings(newSettings);
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  Future<void> toggleNotificationsEnabled(bool enabled) async {
    if (enabled) {
      // 権限リクエスト
      final repo = ref.read(notificationRepositoryProvider);
      await repo.requestPermission();
    }
    await updateSettings(state.settings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> toggleGearOverhaulReminder(bool enabled) async {
    await updateSettings(
      state.settings.copyWith(gearOverhaulReminderEnabled: enabled),
    );
  }

  Future<void> toggleTripReminder(bool enabled) async {
    await updateSettings(
      state.settings.copyWith(tripReminderEnabled: enabled),
    );
  }

  /// テスト通知を即時送信
  Future<void> sendTestNotification() async {
    try {
      final notifRepo = ref.read(notificationRepositoryProvider);
      await notifRepo.requestPermission();
      final testItem = AppNotificationItem(
        id: NotificationIdGenerator.testNotificationId,
        title: '【Scuba Life】テスト通知',
        body: '安全リマインダー通知の設定が正常に完了しました！',
        scheduledDate: DateTime.now(),
        payload: 'test',
      );
      await notifRepo.showNotification(testItem);
      state = state.copyWith(message: 'テスト通知を送信しました');
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }
}

final notificationSettingsNotifierProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettingsState>(() {
  return NotificationSettingsNotifier();
});
