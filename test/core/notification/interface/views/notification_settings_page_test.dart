import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/notification/domain/entities/notification_settings.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_repository.dart';
import 'package:scuba_life/core/notification/infrastructure/in_memory_notification_settings_repository.dart';
import 'package:scuba_life/core/notification/interface/notification_providers.dart';
import 'package:scuba_life/core/notification/interface/views/notification_settings_page.dart';

void main() {
  late InMemoryNotificationRepository notificationRepository;
  late InMemoryNotificationSettingsRepository settingsRepository;

  setUp(() {
    notificationRepository = InMemoryNotificationRepository();
    settingsRepository = InMemoryNotificationSettingsRepository(
      const NotificationSettings(
        notificationsEnabled: true,
        gearOverhaulReminderEnabled: true,
        tripReminderEnabled: true,
      ),
    );
  });

  Widget buildTestWidget({Size screenSize = const Size(390, 844)}) {
    return ProviderScope(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(notificationRepository),
        notificationSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const NotificationSettingsPage(),
        ),
      ),
    );
  }

  group('NotificationSettingsPage Widget Tests', () {
    testWidgets('初期描画で3つのトグルとテスト通知送信ボタンが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('通知設定'), findsOneWidget);
      expect(find.text('安全リマインダー設定'), findsOneWidget);
      expect(find.text('プッシュ通知を有効にする'), findsOneWidget);
      expect(find.text('機材オーバーホール目安通知'), findsOneWidget);
      expect(find.text('トリップ前日準備リマインダー'), findsOneWidget);
      expect(find.text('通知の動作テスト'), findsOneWidget);
      expect(find.byKey(const Key('send_test_notification_button')), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));
    });

    testWidgets('プッシュ通知全体をOFFにすると配下のスイッチが無効化されること', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 先頭のSwitch（全体通知）をタップしてOFFにする
      final firstSwitch = find.byType(Switch).first;
      await tester.tap(firstSwitch);
      await tester.pumpAndSettle();

      // settingsRepository の値が更新されていること
      final currentSettings = await settingsRepository.loadSettings();
      expect(currentSettings.notificationsEnabled, isFalse);

      // 配下のスイッチが非活性（enabled = false）になっていること
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches[0].value, isFalse);
      expect(switches[1].onChanged, isNull);
      expect(switches[2].onChanged, isNull);
    });

    testWidgets('テスト通知送信ボタンをタップすると即時テスト通知が発行されスナックバーが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final testButton = find.byKey(const Key('send_test_notification_button'));
      await tester.ensureVisible(testButton);
      await tester.tap(testButton);
      await tester.pumpAndSettle();

      // InMemoryNotificationRepository にテスト通知が追加されていること
      expect(notificationRepository.shownNotifications, hasLength(1));
      final notification = notificationRepository.shownNotifications.first;
      expect(notification.title, contains('【Scuba Life】テスト通知'));
      expect(notification.payload, equals('test'));

      // スナックバーの表示確認
      expect(find.text('テスト通知を送信しました。端末の通知欄をご確認ください。'), findsOneWidget);
    });

    testWidgets('小型端末（幅360px、2376x968等の縦向き）でレンダリングしてもオーバーフローしないこと', (tester) async {
      // 360 x 800 の小型画面サイズ
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestWidget(screenSize: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('通知設定'), findsOneWidget);
      expect(find.text('機材オーバーホール目安通知'), findsOneWidget);
      expect(find.text('トリップ前日準備リマインダー'), findsOneWidget);

      // 下部までスクロールしてもエラーが出ないこと
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('send_test_notification_button')), findsOneWidget);
    });
  });
}
