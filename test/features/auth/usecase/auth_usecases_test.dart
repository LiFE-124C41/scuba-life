import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/domain/errors/auth_failure.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/usecase/get_current_user.dart';
import 'package:scuba_life/features/auth/usecase/send_password_reset.dart';
import 'package:scuba_life/features/auth/usecase/sign_in_with_email.dart';
import 'package:scuba_life/features/auth/usecase/sign_in_with_google.dart';
import 'package:scuba_life/features/auth/usecase/sign_out.dart';
import 'package:scuba_life/features/auth/usecase/sign_up_with_email.dart';
import 'package:scuba_life/features/auth/usecase/watch_auth_state.dart';

void main() {
  group('Auth UseCases Unit Tests', () {
    late InMemoryAuthRepository repository;

    setUp(() {
      repository = InMemoryAuthRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    group('SignUpWithEmail', () {
      test('新規登録成功: 有効な情報でユーザーが作成され、ログイン状態になること', () async {
        // Arrange
        final usecase = SignUpWithEmail(repository);
        const params = SignUpWithEmailParams(
          email: 'test@example.com',
          password: 'password123',
          displayName: 'Test Diver',
        );

        // Act
        final user = await usecase(params);

        // Assert
        expect(user.email, equals('test@example.com'));
        expect(user.displayName, equals('Test Diver'));
        expect(repository.currentUser, equals(user));
      });

      test('新規登録失敗: パスワードが短すぎる場合は WeakPasswordFailure がスローされること', () async {
        // Arrange
        final usecase = SignUpWithEmail(repository);
        const params = SignUpWithEmailParams(
          email: 'short@example.com',
          password: '123',
        );

        // Act & Assert
        expect(
          () => usecase(params),
          throwsA(isA<WeakPasswordFailure>()),
        );
      });

      test('新規登録失敗: 既に登録済みのメールアドレスの場合は EmailAlreadyInUseFailure がスローされること', () async {
        // Arrange
        final usecase = SignUpWithEmail(repository);
        const params = SignUpWithEmailParams(
          email: 'duplicate@example.com',
          password: 'password123',
        );
        await usecase(params); // 初回登録

        // Act & Assert (2回目の登録)
        expect(
          () => usecase(params),
          throwsA(isA<EmailAlreadyInUseFailure>()),
        );
      });
    });

    group('SignInWithEmail', () {
      setUp(() async {
        // 既存ユーザーを事前登録
        await repository.signUpWithEmail(
          email: 'registered@example.com',
          password: 'correctPassword',
          displayName: 'Registered User',
        );
        await repository.signOut();
      });

      test('ログイン成功: 正しい認証情報でログインできること', () async {
        // Arrange
        final usecase = SignInWithEmail(repository);
        const params = SignInWithEmailParams(
          email: 'registered@example.com',
          password: 'correctPassword',
        );

        // Act
        final user = await usecase(params);

        // Assert
        expect(user.email, equals('registered@example.com'));
        expect(repository.currentUser, equals(user));
      });

      test('ログイン失敗: パスワードが誤っている場合は InvalidEmailAndPasswordFailure がスローされること', () async {
        // Arrange
        final usecase = SignInWithEmail(repository);
        const params = SignInWithEmailParams(
          email: 'registered@example.com',
          password: 'wrongPassword',
        );

        // Act & Assert
        expect(
          () => usecase(params),
          throwsA(isA<InvalidEmailAndPasswordFailure>()),
        );
      });

      test('ログイン失敗: 未登録のメールアドレスの場合は UserNotFoundFailure がスローされること', () async {
        // Arrange
        final usecase = SignInWithEmail(repository);
        const params = SignInWithEmailParams(
          email: 'unknown@example.com',
          password: 'anyPassword',
        );

        // Act & Assert
        expect(
          () => usecase(params),
          throwsA(isA<UserNotFoundFailure>()),
        );
      });
    });

    group('SignInWithGoogle', () {
      test('Googleサインイン成功: Googleユーザー情報でログインできること', () async {
        // Arrange
        final usecase = SignInWithGoogle(repository);

        // Act
        final user = await usecase(const NoParams());

        // Assert
        expect(user.email, equals('diver.google@example.com'));
        expect(user.displayName, equals('Google Diver'));
        expect(repository.currentUser, equals(user));
      });
    });

    group('SignOut', () {
      test('サインアウト成功: currentUser が null になること', () async {
        // Arrange
        await repository.signUpWithEmail(
          email: 'logout@example.com',
          password: 'password123',
        );
        expect(repository.currentUser, isNotNull);

        final usecase = SignOut(repository);

        // Act
        await usecase(const NoParams());

        // Assert
        expect(repository.currentUser, isNull);
      });
    });

    group('WatchAuthState & GetCurrentUser', () {
      test('WatchAuthState: 認証状態の変化がストリームで正しく通知されること', () async {
        // Arrange
        final watchAuthState = WatchAuthState(repository);
        final getCurrentUser = GetCurrentUser(repository);

        final states = <UserAccount?>[];
        final subscription = watchAuthState().listen(states.add);

        // Act & Assert
        expect(await getCurrentUser(const NoParams()), isNull);

        // サインアップ
        final user = await repository.signUpWithEmail(
          email: 'stream@example.com',
          password: 'password123',
        );
        expect(await getCurrentUser(const NoParams()), equals(user));

        // サインアウト
        await repository.signOut();
        expect(await getCurrentUser(const NoParams()), isNull);

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(states.length, greaterThanOrEqualTo(2));

        await subscription.cancel();
      });
    });

    group('SendPasswordReset', () {
      test('パスワード再設定: 登録済みメールアドレスに対して例外なく成功すること', () async {
        // Arrange
        await repository.signUpWithEmail(
          email: 'reset@example.com',
          password: 'password123',
        );
        final usecase = SendPasswordReset(repository);

        // Act & Assert (例外が発生しないこと)
        await expectLater(usecase('reset@example.com'), completes);
      });

      test('パスワード再設定: 未登録アドレスの場合は UserNotFoundFailure がスローされること', () async {
        // Arrange
        final usecase = SendPasswordReset(repository);

        // Act & Assert
        expect(
          () => usecase('unregistered@example.com'),
          throwsA(isA<UserNotFoundFailure>()),
        );
      });
    });
  });
}
