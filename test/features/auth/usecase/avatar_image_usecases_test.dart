import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/usecase/delete_avatar_image.dart';
import 'package:scuba_life/features/auth/usecase/upload_avatar_image.dart';

void main() {
  group('Avatar Image UseCases Unit Tests', () {
    late InMemoryMediaStorageRepository fakeStorage;
    late InMemoryUserRepository fakeUserRepo;
    late UploadAvatarImage uploadUseCase;
    late DeleteAvatarImage deleteUseCase;

    const initialUser = UserAccount(
      id: 'diver-001',
      email: 'diver@example.com',
      displayName: 'Ocean Diver',
      certificationOrg: 'PADI',
      certificationLevel: 'AOW',
    );

    setUp(() {
      fakeStorage = InMemoryMediaStorageRepository();
      fakeUserRepo = InMemoryUserRepository(
        initialUsers: {'diver-001': initialUser},
      );
      uploadUseCase = UploadAvatarImage(
        mediaStorageRepository: fakeStorage,
        userRepository: fakeUserRepo,
      );
      deleteUseCase = DeleteAvatarImage(
        mediaStorageRepository: fakeStorage,
        userRepository: fakeUserRepo,
      );
    });

    test('UploadAvatarImage: プロフィール写真がStorageに保存されphotoUrlが更新されること', () async {
      // Arrange
      final dummyBytes = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEGヘッダー例

      // Act
      final updated = await uploadUseCase(
        UploadAvatarImageParams(
          userId: 'diver-001',
          imageBytes: dummyBytes,
          contentType: 'image/jpeg',
        ),
      );

      // Assert
      expect(
        updated.photoUrl,
        equals('https://mockstorage.example.com/users/diver-001/profile/avatar.webp'),
      );

      // Repository の永続化も確認
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.photoUrl, equals(updated.photoUrl));
      expect(
        fakeStorage.storedFiles.containsKey('users/diver-001/profile/avatar.webp'),
        isTrue,
      );
    });

    test('UploadAvatarImage: PNGバイトデータが正しく検出されてアップロードされること', () async {
      // Arrange
      final dummyBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]; // PNGヘッダー

      // Act
      final updated = await uploadUseCase(
        UploadAvatarImageParams(
          userId: 'diver-001',
          imageBytes: dummyBytes,
        ),
      );

      // Assert
      expect(
        updated.photoUrl,
        equals('https://mockstorage.example.com/users/diver-001/profile/avatar.webp'),
      );
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.photoUrl, isNotNull);
    });

    test('UploadAvatarImage: ユーザーが存在しない場合にStateErrorがスローされること', () async {
      // Act & Assert
      expect(
        () => uploadUseCase(
          UploadAvatarImageParams(
            userId: 'unknown-user',
            imageBytes: [1, 2, 3],
          ),
        ),
        throwsStateError,
      );
    });

    test('DeleteAvatarImage: 設定済みプロフィール写真が削除されphotoUrlがnullになること', () async {
      // Arrange: 事前にアバター写真を登録
      await uploadUseCase(
        UploadAvatarImageParams(
          userId: 'diver-001',
          imageBytes: [1, 2, 3],
        ),
      );
      expect(fakeStorage.storedFiles.isNotEmpty, isTrue);

      // Act
      final updated = await deleteUseCase(
        const DeleteAvatarImageParams(
          userId: 'diver-001',
        ),
      );

      // Assert
      expect(updated.photoUrl, isNull);
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.photoUrl, isNull);
      expect(
        fakeStorage.storedFiles.containsKey('users/diver-001/profile/avatar.webp'),
        isFalse,
      );
    });

    test('DeleteAvatarImage: 元々写真が未設定の場合でも正常に完了すること', () async {
      // Act
      final updated = await deleteUseCase(
        const DeleteAvatarImageParams(
          userId: 'diver-001',
        ),
      );

      // Assert
      expect(updated.photoUrl, isNull);
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.photoUrl, isNull);
    });
  });
}
