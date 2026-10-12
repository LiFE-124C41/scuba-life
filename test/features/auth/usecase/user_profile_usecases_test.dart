import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/usecase/get_user_profile.dart';
import 'package:scuba_life/features/auth/usecase/sync_initial_profile.dart';
import 'package:scuba_life/features/auth/usecase/update_user_profile.dart';
import 'package:scuba_life/features/auth/usecase/watch_user_profile.dart';

void main() {
  group('UserProfile UseCases Unit Tests', () {
    late InMemoryUserRepository repository;

    final dummyUser = UserAccount(
      id: 'test-user-123',
      email: 'diver@example.com',
      displayName: 'テストダイバー',
      photoUrl: 'https://example.com/avatar.jpg',
      isEmailVerified: true,
      certificationOrg: 'PADI',
      certificationLevel: 'AOW (アドヴァンスド)',
      cCardNumber: '1234567890',
      totalDivesOffset: 30,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

    setUp(() {
      repository = InMemoryUserRepository(initialUsers: {
        dummyUser.id: dummyUser,
      });
    });

    tearDown(() {
      repository.dispose();
    });

    group('GetUserProfile', () {
      test('存在するユーザーIDを指定した場合、該当のプロファイル情報が取得できること', () async {
        // Arrange
        final usecase = GetUserProfile(repository);

        // Act
        final result = await usecase('test-user-123');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals('test-user-123'));
        expect(result.certificationOrg, equals('PADI'));
        expect(result.certificationLevel, equals('AOW (アドヴァンスド)'));
        expect(result.cCardNumber, equals('1234567890'));
        expect(result.totalDivesOffset, equals(30));
      });

      test('存在しないユーザーIDを指定した場合、null が返却されること', () async {
        // Arrange
        final usecase = GetUserProfile(repository);

        // Act
        final result = await usecase('non-existing-user');

        // Assert
        expect(result, isNull);
      });
    });

    group('WatchUserProfile', () {
      test('プロファイルのリアルタイムストリームを監視できること', () async {
        // Arrange
        final usecase = WatchUserProfile(repository);

        // Act & Assert
        expect(
          usecase('test-user-123'),
          emits(dummyUser),
        );
      });
    });

    group('UpdateUserProfile', () {
      test('プロファイル情報（指導団体・ランク・Cカード番号・潜水本数）を更新・保存できること', () async {
        // Arrange
        final usecase = UpdateUserProfile(repository);
        const params = UpdateUserProfileParams(
          userId: 'test-user-123',
          displayName: '更新後ダイバー',
          certificationOrg: 'NAUI',
          certificationLevel: 'RED (レスキュー・ダイバー)',
          cCardNumber: '999888777',
          totalDivesOffset: 50,
        );

        // Act
        final updated = await usecase(params);

        // Assert
        expect(updated.displayName, equals('更新後ダイバー'));
        expect(updated.certificationOrg, equals('NAUI'));
        expect(updated.certificationLevel, equals('RED (レスキュー・ダイバー)'));
        expect(updated.cCardNumber, equals('999888777'));
        expect(updated.totalDivesOffset, equals(50));

        // リポジトリ内のデータも永続化・更新されていることを確認
        final stored = await repository.getUserProfile('test-user-123');
        expect(stored, equals(updated));
      });
    });

    group('SyncInitialProfile', () {
      test('初回サインアップ時: ドキュメントが存在しない場合は新規に初期データが作成されること', () async {
        // Arrange
        final usecase = SyncInitialProfile(repository);
        final newUser = UserAccount(
          id: 'new-user-456',
          email: 'newbie@example.com',
          displayName: '新規ダイバー',
          createdAt: DateTime.now(),
        );

        // Act
        final result = await usecase(newUser);

        // Assert
        expect(result.id, equals('new-user-456'));
        expect(result.email, equals('newbie@example.com'));
        final stored = await repository.getUserProfile('new-user-456');
        expect(stored, isNotNull);
        expect(stored!.email, equals('newbie@example.com'));
      });

      test('既存ユーザーログイン時: 既にドキュメントが存在する場合は既存データが保持・返却されること', () async {
        // Arrange
        final usecase = SyncInitialProfile(repository);
        // Auth側から渡された基本情報（Cカード情報はまだ持っていない）
        final loginUser = UserAccount(
          id: 'test-user-123',
          email: 'diver@example.com',
        );

        // Act
        final result = await usecase(loginUser);

        // Assert
        // 既存のFirestoreデータ（PADI, AOW）が返却されること
        expect(result.id, equals('test-user-123'));
        expect(result.certificationOrg, equals('PADI'));
        expect(result.certificationLevel, equals('AOW (アドヴァンスド)'));
        expect(result.totalDivesOffset, equals(30));
      });
    });
  });
}
