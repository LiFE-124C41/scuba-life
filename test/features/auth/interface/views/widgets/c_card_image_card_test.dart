import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/fake_image_picker_service.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/core/media/interface/media_providers.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/user_profile_controller.dart';
import 'package:scuba_life/features/auth/interface/views/widgets/c_card_full_screen_viewer.dart';
import 'package:scuba_life/features/auth/interface/views/widgets/c_card_image_card.dart';

void main() {
  group('CCardImageCard Widget & Responsive Tests', () {
    late InMemoryUserRepository fakeUserRepo;
    late InMemoryMediaStorageRepository fakeStorage;
    late FakeImagePickerService fakePicker;

    const testUser = UserAccount(
      id: 'diver-test-01',
      email: 'diver@example.com',
      displayName: 'テストダイバー',
      certificationOrg: 'PADI',
      certificationLevel: 'AOW',
    );

    setUp(() {
      fakeUserRepo = InMemoryUserRepository(
        initialUsers: {'diver-test-01': testUser},
      );
      fakeStorage = InMemoryMediaStorageRepository();
      fakePicker = FakeImagePickerService(
        nextImageBytes: [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3], // ダミー画像バイト
      );
    });

    Widget createWidgetUnderTest({UserAccount? user}) {
      return ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeUserRepo),
          mediaStorageRepositoryProvider.overrideWithValue(fakeStorage),
          imagePickerServiceProvider.overrideWithValue(fakePicker),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CCardImageCard(user: user ?? testUser),
            ),
          ),
        ),
      );
    }

    testWidgets('初期描画: タイトルおよび表面・裏面の追加スロットが表示されること', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cカード写真 (電子ライセンス証)'), findsOneWidget);
      expect(find.text('ショップ受付時に提示できる写真を保管できます'), findsOneWidget);
      expect(find.text('表面を登録'), findsOneWidget);
      expect(find.text('裏面を登録'), findsOneWidget);
    });

    testWidgets('小型画面（幅360px）でもオーバーフローなく縦並びで描画できること', (tester) async {
      // 小型端末幅360pxを設定
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Arrange & Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(find.text('表面を登録'), findsOneWidget);
      expect(find.text('裏面を登録'), findsOneWidget);
    });

    testWidgets('画像登録フロー: スロットをタップしてカメラを選択するとアップロードが完了すること', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act 1: 「表面を登録」をタップ
      await tester.tap(find.text('表面を登録'));
      await tester.pumpAndSettle();

      // Assert 1: 写真選択ボトムシートが表示されること
      expect(find.text('Cカード (表面) の写真を選択'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);
      expect(find.text('写真ライブラリから選択'), findsOneWidget);

      // Act 2: 「カメラで撮影」を選択
      await tester.tap(find.text('カメラで撮影'));
      await tester.pumpAndSettle();

      // Assert 2: 完了SnackBarが表示され、Storageにファイルが保存されること
      expect(find.text('Cカード表面の写真を登録しました'), findsOneWidget);
      expect(
        fakeStorage.storedFiles.containsKey('users/diver-test-01/profile/c_card_front.webp'),
        isTrue,
      );
    });

    testWidgets('CCardFullScreenViewer: 単体でタイトル・閉じる・削除ダイアログが正しく描画されること', (tester) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: CCardFullScreenViewer(
            imageUrl: 'https://mockstorage.example.com/test.webp',
            title: 'Cカード写真 (表面)',
            onDelete: () {
              deleteCalled = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('Cカード写真 (表面)'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      // Act: 削除アイコンタップ
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // 確認ダイアログが表示されること
      expect(find.text('写真の削除確認'), findsOneWidget);
      expect(find.text('削除する'), findsOneWidget);

      // 削除確定
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });
  });
}
