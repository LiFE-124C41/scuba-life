import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/core/usecase/usecase.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_auth_repository.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/usecase/delete_account.dart';
import 'package:scuba_life/features/logbook/usecase/delete_dive_log_photo.dart';
import 'package:scuba_life/features/logbook/usecase/upload_dive_log_photo.dart';

void main() {
  group('Dive Log Photo UseCases Unit Tests', () {
    late InMemoryMediaStorageRepository fakeStorage;
    late UploadDiveLogPhoto uploadUseCase;
    late DeleteDiveLogPhoto deleteUseCase;

    setUp(() {
      fakeStorage = InMemoryMediaStorageRepository();
      uploadUseCase = UploadDiveLogPhoto(fakeStorage);
      deleteUseCase = DeleteDiveLogPhoto(fakeStorage);
    });

    test('UploadDiveLogPhoto: 写真がアップロードされURLが返却されること', () async {
      // Arrange
      final dummyBytes = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEGヘッダー例

      // Act
      final url = await uploadUseCase(
        UploadDiveLogPhotoParams(
          userId: 'user-001',
          logId: 'log-101',
          imageBytes: dummyBytes,
          customPhotoId: 'photo_01',
        ),
      );

      // Assert
      expect(
        url,
        equals('https://mockstorage.example.com/users/user-001/dive_logs/log-101/photo_01.webp'),
      );
      expect(
        fakeStorage.storedFiles.containsKey('users/user-001/dive_logs/log-101/photo_01.webp'),
        isTrue,
      );
    });

    test('UploadDiveLogPhoto: PNGヘッダーが検出されて正しく保存されること', () async {
      // Arrange
      final dummyBytes = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]; // PNG

      // Act
      final url = await uploadUseCase(
        UploadDiveLogPhotoParams(
          userId: 'user-001',
          logId: 'log-101',
          imageBytes: dummyBytes,
          customPhotoId: 'photo_png',
        ),
      );

      // Assert
      expect(url, contains('photo_png.webp'));
      expect(
        fakeStorage.storedFiles.containsKey('users/user-001/dive_logs/log-101/photo_png.webp'),
        isTrue,
      );
    });

    test('DeleteDiveLogPhoto: 指定URLの写真がストレージから削除されること', () async {
      // Arrange
      final url = await uploadUseCase(
        UploadDiveLogPhotoParams(
          userId: 'user-001',
          logId: 'log-101',
          imageBytes: [1, 2, 3],
          customPhotoId: 'photo_to_delete',
        ),
      );
      expect(
        fakeStorage.storedFiles.containsKey('users/user-001/dive_logs/log-101/photo_to_delete.webp'),
        isTrue,
      );

      // Act
      await deleteUseCase(DeleteDiveLogPhotoParams(photoUrl: url));

      // Assert
      expect(
        fakeStorage.storedFiles.containsKey('users/user-001/dive_logs/log-101/photo_to_delete.webp'),
        isFalse,
      );
    });
  });

  group('DeleteAccount Storage Cleanup Integration Unit Tests', () {
    test('DeleteAccount: 退会時にユーザー固有ディレクトリ (/users/{userId}) 配下の全メディアが一括消去されること', () async {
      // Arrange
      const user = UserAccount(
        id: 'user-cleanup-01',
        email: 'cleanup@example.com',
      );
      final fakeAuth = InMemoryAuthRepository(initialUser: user);
      final fakeUserRepo = InMemoryUserRepository(initialUsers: {user.id: user});
      final fakeStorage = InMemoryMediaStorageRepository();

      // 事前に複数のメディア（アバター、Cカード、ログ写真）を登録
      fakeStorage.storedFiles['users/user-cleanup-01/profile/avatar.webp'] = [1];
      fakeStorage.storedFiles['users/user-cleanup-01/profile/c_card_front.webp'] = [2];
      fakeStorage.storedFiles['users/user-cleanup-01/dive_logs/log-01/photo_1.webp'] = [3];
      fakeStorage.storedFiles['users/user-cleanup-01/dive_logs/log-02/photo_2.webp'] = [4];
      // 他ユーザーのデータ（消えてはならないもの）
      fakeStorage.storedFiles['users/other-user/profile/avatar.webp'] = [99];

      final deleteAccountUseCase = DeleteAccount(
        authRepository: fakeAuth,
        userRepository: fakeUserRepo,
        mediaStorageRepository: fakeStorage,
      );

      // Act
      await deleteAccountUseCase(const NoParams());

      // Assert
      // 対象ユーザーのファイルがすべて削除されていること
      expect(
        fakeStorage.storedFiles.keys.where((k) => k.startsWith('users/user-cleanup-01/')),
        isEmpty,
      );
      // 別ユーザーのファイルは保持されていること
      expect(
        fakeStorage.storedFiles.containsKey('users/other-user/profile/avatar.webp'),
        isTrue,
      );
      // ユーザーデータも削除されていること
      expect(await fakeUserRepo.getUserProfile(user.id), isNull);
      expect(fakeAuth.currentUser, isNull);
    });
  });
}
