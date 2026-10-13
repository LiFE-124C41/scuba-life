import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/infrastructure/in_memory_media_storage_repository.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/in_memory_user_repository.dart';
import 'package:scuba_life/features/auth/usecase/delete_c_card_image.dart';
import 'package:scuba_life/features/auth/usecase/upload_c_card_image.dart';

void main() {
  group('C-Card Image UseCases Unit Tests', () {
    late InMemoryMediaStorageRepository fakeStorage;
    late InMemoryUserRepository fakeUserRepo;
    late UploadCCardImage uploadUseCase;
    late DeleteCCardImage deleteUseCase;

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
      uploadUseCase = UploadCCardImage(
        mediaStorageRepository: fakeStorage,
        userRepository: fakeUserRepo,
      );
      deleteUseCase = DeleteCCardImage(
        mediaStorageRepository: fakeStorage,
        userRepository: fakeUserRepo,
      );
    });

    test('UploadCCardImage (表面): 表面の画像がアップロードされプロファイルが更新されること', () async {
      // Arrange
      final dummyBytes = [0xFF, 0xD8, 0xFF, 0xE0]; // JPEGヘッダー例

      // Act
      final updated = await uploadUseCase(
        UploadCCardImageParams(
          userId: 'diver-001',
          imageBytes: dummyBytes,
          isFront: true,
          contentType: 'image/jpeg',
        ),
      );

      // Assert
      expect(
        updated.cCardFrontUrl,
        equals('https://mockstorage.example.com/users/diver-001/profile/c_card_front.webp'),
      );
      expect(updated.cCardBackUrl, isNull);

      // Repository の永続化も確認
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.cCardFrontUrl, equals(updated.cCardFrontUrl));
      expect(fakeStorage.storedFiles.containsKey('users/diver-001/profile/c_card_front.webp'), isTrue);
    });

    test('UploadCCardImage (裏面): 裏面の画像がアップロードされプロファイルが更新されること', () async {
      // Arrange
      final dummyBytes = [0x89, 0x50, 0x4E, 0x47]; // PNGヘッダー例

      // Act
      final updated = await uploadUseCase(
        UploadCCardImageParams(
          userId: 'diver-001',
          imageBytes: dummyBytes,
          isFront: false,
          contentType: 'image/png',
        ),
      );

      // Assert
      expect(
        updated.cCardBackUrl,
        equals('https://mockstorage.example.com/users/diver-001/profile/c_card_back.webp'),
      );

      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.cCardBackUrl, equals(updated.cCardBackUrl));
    });

    test('UploadCCardImage: ユーザーが存在しない場合にStateErrorがスローされること', () async {
      // Act & Assert
      expect(
        () => uploadUseCase(
          UploadCCardImageParams(
            userId: 'unknown-user',
            imageBytes: [1, 2, 3],
            isFront: true,
          ),
        ),
        throwsStateError,
      );
    });

    test('DeleteCCardImage (表面): 表面画像が削除されプロファイルからURLが消去されること', () async {
      // Arrange: 事前に表面画像を登録
      await uploadUseCase(
        UploadCCardImageParams(
          userId: 'diver-001',
          imageBytes: [1, 2, 3],
          isFront: true,
        ),
      );
      expect(fakeStorage.storedFiles.isNotEmpty, isTrue);

      // Act
      final updated = await deleteUseCase(
        const DeleteCCardImageParams(
          userId: 'diver-001',
          isFront: true,
        ),
      );

      // Assert
      expect(updated.cCardFrontUrl, isNull);
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.cCardFrontUrl, isNull);
      expect(fakeStorage.storedFiles.containsKey('users/diver-001/profile/c_card_front.webp'), isFalse);
    });

    test('DeleteCCardImage (裏面): 裏面画像が削除されプロファイルからURLが消去されること', () async {
      // Arrange: 事前に裏面画像を登録
      await uploadUseCase(
        UploadCCardImageParams(
          userId: 'diver-001',
          imageBytes: [1, 2, 3],
          isFront: false,
        ),
      );

      // Act
      final updated = await deleteUseCase(
        const DeleteCCardImageParams(
          userId: 'diver-001',
          isFront: false,
        ),
      );

      // Assert
      expect(updated.cCardBackUrl, isNull);
      final stored = await fakeUserRepo.getUserProfile('diver-001');
      expect(stored?.cCardBackUrl, isNull);
    });
  });
}
