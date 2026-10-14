import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/fake_image_picker_service.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/core/media/interface/media_providers.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/user_profile_controller.dart';
import 'package:scuba_life/features/auth/interface/views/widgets/profile_avatar_widget.dart';

void main() {
  group('ProfileAvatarWidget Widget & Responsive Tests', () {
    late InMemoryUserRepository fakeUserRepo;
    late InMemoryMediaStorageRepository fakeStorage;
    late FakeImagePickerService fakePicker;

    const testUserWithoutPhoto = UserAccount(
      id: 'diver-test-01',
      email: 'diver@example.com',
      displayName: 'テストダイバー',
    );

    const testUserWithPhoto = UserAccount(
      id: 'diver-test-02',
      email: 'diver2@example.com',
      displayName: 'テストダイバー2',
      photoUrl: 'https://mockstorage.example.com/users/diver-test-02/profile/avatar.webp',
    );

    setUp(() {
      fakeUserRepo = InMemoryUserRepository(
        initialUsers: {
          'diver-test-01': testUserWithoutPhoto,
          'diver-test-02': testUserWithPhoto,
        },
      );
      fakeStorage = InMemoryMediaStorageRepository();
      fakePicker = FakeImagePickerService(
        nextImageBytes: [0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3], // ダミー画像バイト
      );
    });

    Widget createWidgetUnderTest({required UserAccount user}) {
      return ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeUserRepo),
          mediaStorageRepositoryProvider.overrideWithValue(fakeStorage),
          imagePickerServiceProvider.overrideWithValue(fakePicker),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileAvatarWidget(user: user),
            ),
          ),
        ),
      );
    }

    testWidgets('初期描画 (写真未設定): 人物アイコンとカメラバッジが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('初期描画 (写真設定済み): 編集アイコンバッジが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithPhoto));
      await tester.pump();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('小型画面（幅360px）でもオーバーフローなく描画できること', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('タップ操作: アクションシートが開き、選択肢が表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithPhoto));
      await tester.pump();

      // アバターをタップ
      await tester.tap(find.byType(ProfileAvatarWidget));
      await tester.pumpAndSettle();

      // ボトムシートの項目検証
      expect(find.text('プロフィール写真の変更'), findsOneWidget);
      expect(find.text('カメラで撮影'), findsOneWidget);
      expect(find.text('写真ライブラリから選択'), findsOneWidget);
      expect(find.text('写真を拡大表示'), findsOneWidget);
      expect(find.text('プロフィール写真を削除'), findsOneWidget);
    });

    testWidgets('写真アップロードフロー: カメラ撮影を選択するとStorageにアップロードされSnackBarが表示されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithoutPhoto));
      await tester.pumpAndSettle();

      // タップしてアクションシートを開く
      await tester.tap(find.byType(ProfileAvatarWidget));
      await tester.pumpAndSettle();

      // 「カメラで撮影」をタップ
      await tester.tap(find.text('カメラで撮影'));
      await tester.pumpAndSettle();

      // 結果の検証
      expect(find.text('プロフィール写真を更新しました'), findsOneWidget);
      expect(
        fakeStorage.storedFiles.containsKey('users/diver-test-01/profile/avatar.webp'),
        isTrue,
      );
    });

    testWidgets('写真削除フロー: 削除を選択し確認ダイアログで確定すると削除されること', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(user: testUserWithPhoto));
      await tester.pump();

      // タップしてアクションシートを開く
      await tester.tap(find.byType(ProfileAvatarWidget));
      await tester.pumpAndSettle();

      // 「プロフィール写真を削除」をタップ
      await tester.tap(find.text('プロフィール写真を削除'));
      await tester.pumpAndSettle();

      // 削除確認ダイアログが表示されること
      expect(find.text('写真の削除確認'), findsOneWidget);
      expect(find.text('設定済みのプロフィール写真を削除しますか？'), findsOneWidget);

      // 「削除する」をタップ
      await tester.tap(find.text('削除する'));
      await tester.pumpAndSettle();

      // 完了SnackBarが表示されること
      expect(find.text('プロフィール写真を削除しました'), findsOneWidget);
    });
  });
}
