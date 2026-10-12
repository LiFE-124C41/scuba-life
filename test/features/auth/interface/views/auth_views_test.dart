import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/auth_controller.dart';
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(loggedInRepo),
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

      // Act: ログアウトボタン押下
      await tester.tap(find.widgetWithText(OutlinedButton, 'ログアウト'));
      await tester.pumpAndSettle();

      // Assert: ダイアログ表示
      expect(find.text('ログアウト確認'), findsOneWidget);
      expect(find.text('アカウントからログアウトしますか？'), findsOneWidget);

      loggedInRepo.dispose();
    });
  });
}
