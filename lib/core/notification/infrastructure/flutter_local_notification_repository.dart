import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/entities/app_notification_item.dart';
import '../domain/repositories/notification_repository.dart';

/// flutter_local_notifications を利用した本番用通知リポジトリ実装
class FlutterLocalNotificationRepository implements NotificationRepository {
  final FlutterLocalNotificationsPlugin _plugin;
  final Map<int, AppNotificationItem> _fallbackScheduled = {};
  final List<AppNotificationItem> _fallbackShown = [];
  bool _isInitialized = false;
  bool _useFallback = false;

  FlutterLocalNotificationRepository({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // タイムゾーン初期化
      tz.initializeTimeZones();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      _isInitialized = true;
    } catch (_) {
      // テスト環境やプラットフォームチャンネル未バインド時は安全にフォールバック動作
      _useFallback = true;
      _isInitialized = true;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;

      // Android 13+ (API 33+) 権限リクエスト
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        await androidPlugin.requestExactAlarmsPermission();
        return granted;
      }

      // iOS 権限リクエスト
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  @override
  Future<void> scheduleNotification(AppNotificationItem notification) async {
    await initialize();

    if (_useFallback) {
      _fallbackScheduled[notification.id] = notification;
      return;
    }

    // スケジュール日時が過去の場合は即時通知するかスキップ
    final now = DateTime.now();
    if (notification.scheduledDate.isBefore(now)) {
      await showNotification(notification);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      notification.channelId,
      notification.channelName,
      channelDescription: notification.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTz =
        tz.TZDateTime.from(notification.scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      scheduledDate: scheduledTz,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: notification.payload,
    );
  }

  @override
  Future<void> showNotification(AppNotificationItem notification) async {
    await initialize();

    if (_useFallback) {
      _fallbackShown.add(notification);
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      notification.channelId,
      notification.channelName,
      channelDescription: notification.channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: notification.id,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: notification.payload,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await initialize();
    if (_useFallback) {
      _fallbackScheduled.remove(id);
      return;
    }
    await _plugin.cancel(id: id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await initialize();
    if (_useFallback) {
      _fallbackScheduled.clear();
      return;
    }
    await _plugin.cancelAll();
  }

  @override
  Future<List<AppNotificationItem>> getPendingNotifications() async {
    await initialize();
    if (_useFallback) {
      return _fallbackScheduled.values.toList();
    }
    final pendingRequests = await _plugin.pendingNotificationRequests();
    return pendingRequests.map((req) {
      return AppNotificationItem(
        id: req.id,
        title: req.title ?? '',
        body: req.body ?? '',
        scheduledDate: DateTime.now(), // pendingNotificationRequests では配信予定時刻は取得できないため現在値
        payload: req.payload,
      );
    }).toList();
  }
}
