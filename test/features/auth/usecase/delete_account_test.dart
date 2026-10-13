import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/domain/errors/auth_failure.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/usecase/delete_account.dart';

void main() {
  group('DeleteAccount UseCase Tests', () {
    late InMemoryAuthRepository authRepository;
    late InMemoryUserRepository userRepository;
    late DeleteAccount useCase;

    const testUser = UserAccount(
      id: 'test-user-delete-01',
      email: 'delete-me@example.com',
      displayName: '削除対象ユーザー',
    );

    setUp(() {
      authRepository = InMemoryAuthRepository(initialUser: testUser);
      userRepository = InMemoryUserRepository(
        initialUsers: {testUser.id: testUser},
      );
      useCase = DeleteAccount(
        authRepository: authRepository,
        userRepository: userRepository,
      );
    });

    test('正常系: ログイン中のユーザーのアカウント及びデータが正常に削除されること', () async {
      // Arrange
      expect(authRepository.currentUser, isNotNull);
      final initialProfile = await userRepository.getUserProfile(testUser.id);
      expect(initialProfile, isNotNull);

      // Act
      await useCase(const NoParams());

      // Assert
      expect(authRepository.currentUser, isNull);
      final profileAfterDelete = await userRepository.getUserProfile(testUser.id);
      expect(profileAfterDelete, isNull);
    });

    test('異常系: 未ログイン状態の場合は UserNotFoundFailure がスローされること', () async {
      // Arrange
      await authRepository.signOut();

      // Act & Assert
      expect(
        () => useCase(const NoParams()),
        throwsA(isA<UserNotFoundFailure>()),
      );
    });
  });
}
