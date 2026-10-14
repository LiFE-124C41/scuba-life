import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/fake_image_picker_service.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/core/media/interface/media_providers.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/auth_controller.dart';
import 'package:scuba_life/features/logbook/interface/views/widgets/dive_log_photo_picker_widget.dart';

void main() {
  group('DiveLogPhotoPickerWidget Tests', () {
    late InMemoryAuthRepository fakeAuth;
    late InMemoryMediaStorageRepository fakeStorage;
    late FakeImagePickerService fakePicker;

    const testUser = UserAccount(
      id: 'diver-photo-01',
      email: 'diver@example.com',
    );

    setUp(() {
      fakeAuth = InMemoryAuthRepository(initialUser: testUser);
      fakeStorage = InMemoryMediaStorageRepository();
      fakePicker = FakeImagePickerService(
        nextImageBytes: [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3], // ダミー画像
      );
    });

    Widget createWidgetUnderTest({
      required List<String> initialPhotos,
      required ValueChanged<List<String>> onPhotosChanged,
    }) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          mediaStorageRepositoryProvider.overrideWithValue(fakeStorage),
          imagePickerServiceProvider.overrideWithValue(fakePicker),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: DiveLogPhotoPickerWidget(
                  logId: 'test-log-01',
                  initialPhotoUrls: initialPhotos,
                  onPhotosChanged: onPhotosChanged,
                  maxPhotos: 5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('初期描画 (空状態): タイトル、0/5枚、追加ボタンが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialPhotos: const [],
        onPhotosChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('水中写真・思い出写真'), findsOneWidget);
      expect(find.text('0/5枚'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    });

    testWidgets('小型画面（幅360px）でもオーバーフローなく描画できること', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(
        initialPhotos: const [
          'https://mockstorage.example.com/photo1.webp',
          'https://mockstorage.example.com/photo2.webp',
        ],
        onPhotosChanged: (_) {},
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2/5枚'), findsOneWidget);
      expect(find.text('追加'), findsOneWidget);
    });

    testWidgets('写真追加フロー: 追加ボタンタップからカメラ選択で写真がアップロードされコールバックが呼ばれること', (tester) async {
      List<String>? changedList;

      await tester.pumpWidget(createWidgetUnderTest(
        initialPhotos: const [],
        onPhotosChanged: (photos) {
          changedList = photos;
        },
      ));
      await tester.pumpAndSettle();

      // 追加ボタンタップ
      await tester.tap(find.text('追加'));
      await tester.pumpAndSettle();

      // モーダルが表示されていること
      expect(find.text('写真を追加 (残り5枚)'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);

      // カメラを選択
      await tester.tap(find.text('カメラで撮影'));
      await tester.pumpAndSettle();

      // 完了SnackBarが表示されること
      expect(find.text('写真を追加しました'), findsOneWidget);
      expect(changedList, isNotNull);
      expect(changedList!.length, equals(1));
      expect(find.text('1/5枚'), findsOneWidget);
    });

    testWidgets('写真削除フロー: 削除アイコンタップでリストから削除されること', (tester) async {
      List<String>? changedList;

      await tester.pumpWidget(createWidgetUnderTest(
        initialPhotos: const [
          'https://mockstorage.example.com/photo_delete_test.webp',
        ],
        onPhotosChanged: (photos) {
          changedList = photos;
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('1/5枚'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // 削除ボタンタップ
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // リストが空になること
      expect(changedList, isNotNull);
      expect(changedList!.isEmpty, isTrue);
      expect(find.text('0/5枚'), findsOneWidget);
    });
  });
}
