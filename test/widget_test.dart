import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/app/app.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/interface/controllers/auth_controller.dart';

void main() {
  group('ScubaLifeApp Smoke Tests', () {
    testWidgets('未ログイン時: サインイン画面が初期表示されること', (WidgetTester tester) async {
      final fakeAuthRepo = InMemoryAuthRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const ScubaLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // サインイン画面のタイトル・入力欄・ボタンが表示されていることを確認
      expect(find.text('Scuba Life'), findsOneWidget);
      expect(find.text('ログイン'), findsWidgets);
      expect(find.text('新規登録'), findsOneWidget);
      expect(find.text('Google でログイン'), findsOneWidget);

      fakeAuthRepo.dispose();
    });

    testWidgets('ログイン済み時: メインナビゲーション画面（ログブック）が表示されること', (WidgetTester tester) async {
      final fakeAuthRepo = InMemoryAuthRepository(
        initialUser: const UserAccount(
          id: 'test-user-1',
          email: 'diver@example.com',
          displayName: '海野 ダイバー',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeAuthRepo),
          ],
          child: const ScubaLifeApp(),
        ),
      );
      await tester.pumpAndSettle();

      // ログブックのタイトルが表示されていることを確認
      expect(find.text('ダイビングログ'), findsOneWidget);
      // ナビゲーションバーの各項目が表示されていることを確認
      expect(find.text('生き物図鑑'), findsOneWidget);
      expect(find.text('予定管理'), findsOneWidget);
      expect(find.text('機材管理'), findsOneWidget);

      fakeAuthRepo.dispose();
    });
  });
}
