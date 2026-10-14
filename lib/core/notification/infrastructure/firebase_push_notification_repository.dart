import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../domain/entities/app_notification_item.dart';
import '../domain/entities/push_notification_message.dart';
import '../domain/notification_id_generator.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/repositories/push_notification_repository.dart';

/// バックグラウンド・アプリ終了時のFCMメッセージハンドラ（トップレベル関数必須）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message received: ${message.messageId}');
}

/// Firebase Cloud Messaging (FCM) 本番用リポジトリ実装
class FirebasePushNotificationRepository implements PushNotificationRepository {
  final FirebaseMessaging? _injectedMessaging;
  final NotificationRepository? localNotificationRepository;

  FirebaseMessaging? _messaging;
  bool _isAvailable = false;
  bool _isInitialized = false;

  final _messageController =
      StreamController<PushNotificationMessage>.broadcast();
  final _messageOpenedAppController =
      StreamController<PushNotificationMessage>.broadcast();

  FirebasePushNotificationRepository({
    FirebaseMessaging? messaging,
    this.localNotificationRepository,
  }) : _injectedMessaging = messaging;

  @override
  Stream<PushNotificationMessage> get onMessage => _messageController.stream;

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp =>
      _messageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefresh {
    if (!_isAvailable || _messaging == null) {
      return const Stream.empty();
    }
    return _messaging!.onTokenRefresh;
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_injectedMessaging != null) {
        _messaging = _injectedMessaging;
        _isAvailable = true;
      } else if (Firebase.apps.isNotEmpty) {
        _messaging = FirebaseMessaging.instance;
        _isAvailable = true;
      } else {
        _isAvailable = false;
      }

      if (_isAvailable && _messaging != null) {
        // バックグラウンドハンドラ設定
        if (!kIsWeb) {
          FirebaseMessaging.onBackgroundMessage(
              firebaseMessagingBackgroundHandler);
        }

        // フォアグラウンド受信リスナー
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          final pushMsg = PushNotificationMessage.fromMap(
            id: message.messageId,
            title: message.notification?.title,
            body: message.notification?.body,
            data: message.data,
            sentTime: message.sentTime,
          );
          _messageController.add(pushMsg);

          // フォアグラウンド時はローカル通知でバナー表示
          if (localNotificationRepository != null) {
            String channelId = 'scuba_safety_reminders';
            String channelName = '安全リマインダー';

            if (pushMsg.category == 'weather') {
              channelId = 'scuba_weather_alerts';
              channelName = '海況・気象アラート';
            } else if (pushMsg.category == 'announcement') {
              channelId = 'scuba_announcements';
              channelName = '運営からのお知らせ';
            }

            final item = AppNotificationItem(
              id: NotificationIdGenerator.forPushMessage(message.messageId),
              title: pushMsg.title,
              body: pushMsg.body,
              scheduledDate: DateTime.now(),
              payload: message.data['route'] as String? ?? pushMsg.category,
              channelId: channelId,
              channelName: channelName,
              channelDescription: 'Scuba Life リモートプッシュ通知',
            );
            try {
              await localNotificationRepository!.showNotification(item);
            } catch (e) {
              debugPrint('Failed to show foreground notification: $e');
            }
          }
        });

        // バックグラウンドからの復帰タップリスナー
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final pushMsg = PushNotificationMessage.fromMap(
            id: message.messageId,
            title: message.notification?.title,
            body: message.notification?.body,
            data: message.data,
            sentTime: message.sentTime,
          );
          _messageOpenedAppController.add(pushMsg);
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('FirebasePushNotificationRepository initialize error: $e');
      _isAvailable = false;
      _isInitialized = true;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isAvailable || _messaging == null) return false;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      debugPrint('FCM requestPermission error: $e');
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    if (!_isAvailable || _messaging == null) return null;
    try {
      final token = await _messaging!.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Registration Token: $token');
      }
      return token;
    } catch (e) {
      debugPrint('FCM getToken error: $e');
      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    if (!_isAvailable || _messaging == null || kIsWeb) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      debugPrint('Subscribed to FCM topic: $topic');
    } catch (e) {
      debugPrint('FCM subscribeToTopic error ($topic): $e');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!_isAvailable || _messaging == null || kIsWeb) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from FCM topic: $topic');
    } catch (e) {
      debugPrint('FCM unsubscribeFromTopic error ($topic): $e');
    }
  }

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    if (!_isAvailable || _messaging == null) return null;
    try {
      final message = await _messaging!.getInitialMessage();
      if (message == null) return null;
      return PushNotificationMessage.fromMap(
        id: message.messageId,
        title: message.notification?.title,
        body: message.notification?.body,
        data: message.data,
        sentTime: message.sentTime,
      );
    } catch (e) {
      debugPrint('FCM getInitialMessage error: $e');
      return null;
    }
  }

  void dispose() {
    _messageController.close();
    _messageOpenedAppController.close();
  }
}
