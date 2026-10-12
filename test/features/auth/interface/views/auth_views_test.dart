import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/auth_controller.dart';
import 'package:scuba_life/features/auth/interface/controllers/user_profile_controller.dart';
import 'package:scuba_life/features/auth/interface/views/password_reset_page.dart';
import 'package:scuba_life/features/auth/interface/views/profile_page.dart';
import 'package:scuba_life/features/auth/interface/views/sign_in_page.dart';
import 'package:scuba_life/features/auth/interface/views/sign_up_page.dart';

void main() {
  group('Auth Views Widget & Responsive Tests', () {
    late InMemoryAuthRepository fakeAuthRepo;

    setUp(() {
      fakeAuthRepo = InMemoryAuthRepository();
    });

    tearDown(() {
      fakeAuthRepo.dispose();
    });

    testWidgets('SignInPage: 小型画面（幅360px）でもオーバーフローなく描画され、バリデーションが動作すること',
        (WidgetTester tester) async {
      // 幅360px（2376x968の縦画面相当）を設定
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const MaterialApp(
            home: SignInPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert (初期描画)
      expect(find.text('Scuba Life'), findsOneWidget);
      expect(find.text('メールアドレス'), findsOneWidget);
      expect(find.text('パスワード'), findsOneWidget);
      expect(find.text('Google でログイン'), findsOneWidget);

      // Act: 未入力でログインボタン押下
      await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
      await tester.pumpAndSettle();

      // Assert: バリデーションエラーメッセージの表示確認
      expect(find.text('メールアドレスを入力してください'), findsOneWidget);
      expect(find.text('パスワードを入力してください'), findsOneWidget);
    });

    testWidgets('SignUpPage: 新規登録画面の各入力欄が表示され、画面遷移と入力ができること',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const MaterialApp(
            home: SignUpPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('新規アカウント登録'), findsOneWidget);
      expect(find.text('ダイバーアカウントを作成'), findsOneWidget);
      expect(find.text('ダイバー名 / 表示名 (任意)'), findsOneWidget);
      expect(find.text('アカウントを作成する'), findsOneWidget);

      // Act: フォーム入力
      await tester.enterText(
        find.widgetWithText(TextFormField, 'メールアドレス *'),
        'newdiver@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'パスワード (6文字以上) *'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'パスワードの確認 *'),
        'password123',
      );
      await tester.pumpAndSettle();

      // 登録ボタン押下
      await tester.tap(find.widgetWithText(FilledButton, 'アカウントを作成する'));
      await tester.pumpAndSettle();

      // ユーザーが作成されていること
      expect(fakeAuthRepo.currentUser?.email, equals('newdiver@example.com'));
    });

    testWidgets('SignUpPage: Google で登録ボタンからGoogle SSO会員登録ができること',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const MaterialApp(
            home: SignUpPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ボタンが存在すること
      expect(find.text('Google で登録'), findsOneWidget);

      // Act: Google で登録ボタンを押下
      await tester.tap(find.widgetWithText(OutlinedButton, 'Google で登録'));
      await tester.pumpAndSettle();

      // Assert: Googleユーザーとしてログイン・登録されていること
      expect(fakeAuthRepo.currentUser?.email, equals('diver.google@example.com'));
      expect(fakeAuthRepo.currentUser?.displayName, equals('Google Diver'));
    });

    testWidgets('PasswordResetPage: パスワード再設定画面の描画と送信確認', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const MaterialApp(
            home: PasswordResetPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('パスワードをお忘れですか？'), findsOneWidget);
      expect(find.text('再設定メールを送信'), findsOneWidget);
    });

    testWidgets('ProfilePage: ログイン中ユーザー情報の表示とログアウトダイアログの表示', (WidgetTester tester) async {
      // Arrange
      final loggedInRepo = InMemoryAuthRepository(
        initialUser: const UserAccount(
          id: 'user-xyz',
          email: 'diver.profile@example.com',
          displayName: '海野 プロフィール',
          isEmailVerified: true,
        ),
      );
      final fakeUserRepo = InMemoryUserRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(loggedInRepo),
            userRepositoryProvider.overrideWithValue(fakeUserRepo),
          ],
          child: const MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: プロフィール情報
      expect(find.text('海野 プロフィール'), findsOneWidget);
      expect(find.text('diver.profile@example.com'), findsOneWidget);
      expect(find.text('クラウド同期中'), findsOneWidget);
      expect(find.text('メール確認済'), findsOneWidget);
      expect(find.text('user-xyz'), findsOneWidget);

      // Assert: 初期未登録ガイダンス
      expect(find.text('Cカード・ダイバー情報'), findsOneWidget);
      expect(find.text('Cカード（ライセンス）情報を登録すると、ログ記録やスキルシートに反映されます。'),
          findsOneWidget);

      // Act: ログアウトボタン押下
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'ログアウト'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'ログアウト'));
      await tester.pumpAndSettle();

      // Assert: ダイアログ表示
      expect(find.text('ログアウト確認'), findsOneWidget);
      expect(find.text('アカウントからログアウトしますか？'), findsOneWidget);

      loggedInRepo.dispose();
      fakeUserRepo.dispose();
    });

    testWidgets('ProfilePage: Cカード登録済み情報の表示と編集ダイアログによる更新（小型画面幅360px対応）',
        (WidgetTester tester) async {
      // 幅360px（小型端末）を設定
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Arrange
      const initialUser = UserAccount(
        id: 'diver-c-card',
        email: 'padi.diver@example.com',
        displayName: '波乗りダイバー',
        certificationOrg: 'PADI',
        certificationLevel: 'AOW (アドヴァンスド)',
        cCardNumber: '987654321',
        totalDivesOffset: 45,
      );
      final loggedInRepo = InMemoryAuthRepository(initialUser: initialUser);
      final fakeUserRepo = InMemoryUserRepository(initialUsers: {
        initialUser.id: initialUser,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(loggedInRepo),
            userRepositoryProvider.overrideWithValue(fakeUserRepo),
          ],
          child: const MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Cカード情報が表示されていること
      expect(find.text('Cカード・ダイバー情報'), findsOneWidget);
      expect(find.text('指導団体'), findsOneWidget);
      expect(find.text('PADI'), findsWidgets);
      expect(find.text('認定ランク'), findsOneWidget);
      expect(find.text('AOW (アドヴァンスド)'), findsOneWidget);
      expect(find.text('Cカード番号'), findsOneWidget);
      expect(find.text('987654321'), findsOneWidget);
      expect(find.text('開始前の経験本数'), findsOneWidget);
      expect(find.text('45 本'), findsOneWidget);

      // Act: 「編集」ボタンタップ
      await tester.tap(find.widgetWithText(TextButton, '編集'));
      await tester.pumpAndSettle();

      // Assert: 編集ダイアログが開いていること
      expect(find.text('ダイバー情報・Cカード'), findsOneWidget);

      // Act: 表示名を変更
      await tester.enterText(
          find.widgetWithText(TextFormField, 'ダイバー名 / 表示名'), 'マスターダイバー');
      // 保存ボタン押下
      await tester.ensureVisible(find.widgetWithText(FilledButton, '保存'));
      await tester.tap(find.widgetWithText(FilledButton, '保存'));
      await tester.pumpAndSettle();

      // Assert: ダイアログが閉じ、SnackBarと更新された表示名が表示されること
      expect(find.text('ダイバー情報を更新しました'), findsOneWidget);
      expect(find.text('マスターダイバー'), findsOneWidget);

      loggedInRepo.dispose();
      fakeUserRepo.dispose();
    });

    testWidgets('ProfilePage: アカウント完全削除（退会）ボタン押下で確認ダイアログが表示され、キャンセルできること',
        (WidgetTester tester) async {
      // Arrange
      const initialUser = UserAccount(
        id: 'user-delete-test',
        email: 'delete.test@example.com',
        displayName: '退会テストダイバー',
      );
      final loggedInRepo = InMemoryAuthRepository(initialUser: initialUser);
      final fakeUserRepo = InMemoryUserRepository(initialUsers: {
        initialUser.id: initialUser,
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(loggedInRepo),
            userRepositoryProvider.overrideWithValue(fakeUserRepo),
          ],
          child: const MaterialApp(
            home: ProfilePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: アカウント完全削除（退会）ボタンが存在すること
      final deleteButton = find.text('アカウントを完全に削除（退会）');
      expect(deleteButton, findsOneWidget);

      // Act: アカウント削除ボタンをタップ
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Assert: 確認ダイアログが表示されること
      expect(find.text('退会・アカウント削除の確認'), findsOneWidget);
      expect(find.text('アカウントを削除する'), findsOneWidget);

      // Act: ダイアログのキャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      // Assert: ダイアログが閉じ、まだログイン状態であること
      expect(find.text('退会・アカウント削除の確認'), findsNothing);
      expect(loggedInRepo.currentUser, isNotNull);

      loggedInRepo.dispose();
      fakeUserRepo.dispose();
    });
  });
}
