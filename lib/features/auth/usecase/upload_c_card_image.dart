import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

class UploadCCardImageParams {
  final String userId;
  final List<int> imageBytes;
  final bool isFront;
  final String contentType;

  const UploadCCardImageParams({
    required this.userId,
    required this.imageBytes,
    required this.isFront,
    this.contentType = 'image/webp',
  });
}

/// Cカード画像（表面/裏面）をCloud Storageにアップロードし、プロファイルを更新するユースケース (Pure Dart)
class UploadCCardImage implements UseCase<UserAccount, UploadCCardImageParams> {
  final MediaStorageRepository mediaStorageRepository;
  final UserRepository userRepository;

  UploadCCardImage({
    required this.mediaStorageRepository,
    required this.userRepository,
  });

  @override
  Future<UserAccount> call(UploadCCardImageParams params) async {
    final currentProfile = await userRepository.getUserProfile(params.userId);
    if (currentProfile == null) {
      throw StateError('ユーザープロファイルが見つかりません。');
    }

    final side = params.isFront ? 'front' : 'back';
    final detectedContentType = _detectContentType(params.imageBytes, params.contentType);
    final path = 'users/${params.userId}/profile/c_card_$side.webp';

    // 1. Cloud Storage へアップロード
    final downloadUrl = await mediaStorageRepository.uploadBytes(
      path: path,
      bytes: params.imageBytes,
      contentType: detectedContentType,
    );

    // 2. ユーザープロファイルに画像URLを反映して保存
    final updatedProfile = params.isFront
        ? currentProfile.copyWith(cCardFrontUrl: downloadUrl)
        : currentProfile.copyWith(cCardBackUrl: downloadUrl);

    await userRepository.saveUserProfile(updatedProfile);
    return updatedProfile;
  }

  String _detectContentType(List<int> bytes, String fallback) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }
    return fallback;
  }
}
