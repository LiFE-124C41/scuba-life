import 'dart:async';

import '../domain/entities/push_notification_message.dart';
import '../domain/repositories/push_notification_repository.dart';

/// 単体テスト・モック用 InMemory PushNotificationRepository
class InMemoryPushNotificationRepository implements PushNotificationRepository {
  bool isInitialized = false;
  bool permissionGranted = true;
  String? mockToken = 'mock_fcm_token_12345';
  final Set<String> subscribedTopics = {};

  final _messageController =
      StreamController<PushNotificationMessage>.broadcast();
  final _messageOpenedAppController =
      StreamController<PushNotificationMessage>.broadcast();
  final _tokenRefreshController = StreamController<String>.broadcast();

  PushNotificationMessage? initialMessage;

  @override
  Stream<PushNotificationMessage> get onMessage => _messageController.stream;

  @override
  Stream<PushNotificationMessage> get onMessageOpenedApp =>
      _messageOpenedAppController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    return permissionGranted;
  }

  @override
  Future<String?> getToken() async {
    return mockToken;
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    subscribedTopics.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    subscribedTopics.remove(topic);
  }

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    return initialMessage;
  }

  /// テスト用: メッセージ受信をエミュレート
  void emitMessage(PushNotificationMessage message) {
    _messageController.add(message);
  }

  /// テスト用: 通知タップ起動をエミュレート
  void emitMessageOpenedApp(PushNotificationMessage message) {
    _messageOpenedAppController.add(message);
  }

  /// テスト用: トークン更新をエミュレート
  void emitNewToken(String token) {
    mockToken = token;
    _tokenRefreshController.add(token);
  }

  void dispose() {
    _messageController.close();
    _messageOpenedAppController.close();
    _tokenRefreshController.close();
  }
}
