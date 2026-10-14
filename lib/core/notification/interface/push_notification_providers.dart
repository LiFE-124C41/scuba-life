import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/push_notification_message.dart';
import '../domain/repositories/push_notification_repository.dart';
import '../infrastructure/firebase_push_notification_repository.dart';
import 'notification_providers.dart';

/// プッシュ通知リポジトリプロバイダー
final pushNotificationRepositoryProvider =
    Provider<PushNotificationRepository>((ref) {
  final localRepo = ref.watch(notificationRepositoryProvider);
  final repo = FirebasePushNotificationRepository(
    localNotificationRepository: localRepo,
  );
  return repo;
});

/// FCM デバイストークン取得 Provider
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  final repo = ref.watch(pushNotificationRepositoryProvider);
  return await repo.getToken();
});

/// フォアグラウンドプッシュ受信ストリーム Provider
final fcmMessageStreamProvider =
    StreamProvider<PushNotificationMessage>((ref) {
  final repo = ref.watch(pushNotificationRepositoryProvider);
  return repo.onMessage;
});

/// 通知タップ起動ストリーム Provider
final fcmMessageOpenedAppStreamProvider =
    StreamProvider<PushNotificationMessage>((ref) {
  final repo = ref.watch(pushNotificationRepositoryProvider);
  return repo.onMessageOpenedApp;
});

/// 通知設定とFCMトピック購読の自動同期プロバイダー
final pushTopicSyncProvider = Provider<void>((ref) {
  final settingsState = ref.watch(notificationSettingsNotifierProvider);
  final pushRepo = ref.watch(pushNotificationRepositoryProvider);
  final settings = settingsState.settings;

  // 気象・海況アラート トピック同期
  if (settings.notificationsEnabled && settings.weatherAlertPushEnabled) {
    pushRepo.subscribeToTopic('weather_alerts');
  } else {
    pushRepo.unsubscribeFromTopic('weather_alerts');
  }

  // 運営お知らせ トピック同期
  if (settings.notificationsEnabled && settings.announcementPushEnabled) {
    pushRepo.subscribeToTopic('announcements');
  } else {
    pushRepo.unsubscribeFromTopic('announcements');
  }
});
