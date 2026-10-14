import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/notification/domain/entities/push_notification_message.dart';
import 'package:scuba_life/core/notification/domain/notification_id_generator.dart';
import 'package:scuba_life/core/notification/infrastructure/firebase_push_notification_repository.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_push_notification_repository.dart';

void main() {
  group('PushNotificationMessage Unit Tests', () {
    test('fromMap: データ構造が正常にパースされること', () {
      final msg = PushNotificationMessage.fromMap(
        id: 'msg_001',
        title: '【緊急】波浪警報',
        body: '伊豆海洋公園周辺で急な波浪が観測されました',
        data: {
          'category': 'weather',
          'spotId': 'spot_izu_01',
        },
      );

      expect(msg.id, 'msg_001');
      expect(msg.title, '【緊急】波浪警報');
      expect(msg.body, '伊豆海洋公園周辺で急な波浪が観測されました');
      expect(msg.category, 'weather');
      expect(msg.data['spotId'], 'spot_izu_01');
    });

    test('NotificationIdGenerator: forPushMessage で決定的なIDが生成されること', () {
      final id1 = NotificationIdGenerator.forPushMessage('msg_abc_123');
      final id2 = NotificationIdGenerator.forPushMessage('msg_abc_123');
      final id3 = NotificationIdGenerator.forPushMessage('msg_xyz_999');
      final nullId = NotificationIdGenerator.forPushMessage(null);

      expect(id1, id2);
      expect(id1 >= 3000000 && id1 <= 3899999, isTrue);
      expect(id3 >= 3000000 && id3 <= 3899999, isTrue);
      expect(nullId, 3000000);
    });
  });

  group('InMemoryPushNotificationRepository Unit Tests', () {
    late InMemoryPushNotificationRepository repo;

    setUp(() {
      repo = InMemoryPushNotificationRepository();
    });

    tearDown(() {
      repo.dispose();
    });

    test('初期化とトークン取得、トピック購読/解除が動作すること', () async {
      await repo.initialize();
      expect(repo.isInitialized, isTrue);

      final token = await repo.getToken();
      expect(token, 'mock_fcm_token_12345');

      await repo.subscribeToTopic('weather_alerts');
      expect(repo.subscribedTopics.contains('weather_alerts'), isTrue);

      await repo.unsubscribeFromTopic('weather_alerts');
      expect(repo.subscribedTopics.contains('weather_alerts'), isFalse);
    });

    test('onMessage ストリームで受信通知を購読できること', () async {
      await repo.initialize();

      final emittedMessages = <PushNotificationMessage>[];
      final sub = repo.onMessage.listen(emittedMessages.add);

      final testMsg = PushNotificationMessage(
        id: '123',
        title: '新着スポット追加',
        body: '沖縄・万座ドリームホールが追加されました',
        category: 'announcement',
        receivedAt: DateTime.now(),
      );

      repo.emitMessage(testMsg);
      await Future.delayed(Duration.zero);

      expect(emittedMessages.length, 1);
      expect(emittedMessages.first.title, '新着スポット追加');

      await sub.cancel();
    });
  });

  group('FirebasePushNotificationRepository Unit Tests', () {
    test('Firebase未初期化時はエラーにならず安全にフォールバックすること', () async {
      final repo = FirebasePushNotificationRepository();
      await repo.initialize();

      final token = await repo.getToken();
      expect(token, isNull);

      final initialMsg = await repo.getInitialMessage();
      expect(initialMsg, isNull);

      // トピック操作や権限リクエストで例外が発生しないこと
      await repo.subscribeToTopic('weather_alerts');
      await repo.unsubscribeFromTopic('weather_alerts');
      final granted = await repo.requestPermission();
      expect(granted, isFalse);

      repo.dispose();
    });
  });
}
