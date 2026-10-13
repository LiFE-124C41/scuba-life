import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

class DeleteCCardImageParams {
  final String userId;
  final bool isFront;

  const DeleteCCardImageParams({
    required this.userId,
    required this.isFront,
  });
}

/// Cカード画像（表面/裏面）をCloud Storageから削除し、プロファイルを更新するユースケース (Pure Dart)
class DeleteCCardImage implements UseCase<UserAccount, DeleteCCardImageParams> {
  final MediaStorageRepository mediaStorageRepository;
  final UserRepository userRepository;

  DeleteCCardImage({
    required this.mediaStorageRepository,
    required this.userRepository,
  });

  @override
  Future<UserAccount> call(DeleteCCardImageParams params) async {
    final currentProfile = await userRepository.getUserProfile(params.userId);
    if (currentProfile == null) {
      throw StateError('ユーザープロファイルが見つかりません。');
    }

    final targetUrl = params.isFront
        ? currentProfile.cCardFrontUrl
        : currentProfile.cCardBackUrl;

    // 1. Cloud Storage から削除
    if (targetUrl != null && targetUrl.isNotEmpty) {
      await mediaStorageRepository.deleteFile(targetUrl);
    }

    // 2. ユーザープロファイルから画像URLを消去して保存
    final updatedProfile = UserAccount(
      id: currentProfile.id,
      email: currentProfile.email,
      displayName: currentProfile.displayName,
      photoUrl: currentProfile.photoUrl,
      isEmailVerified: currentProfile.isEmailVerified,
      certificationOrg: currentProfile.certificationOrg,
      certificationLevel: currentProfile.certificationLevel,
      cCardNumber: currentProfile.cCardNumber,
      totalDivesOffset: currentProfile.totalDivesOffset,
      cCardFrontUrl: params.isFront ? null : currentProfile.cCardFrontUrl,
      cCardBackUrl: !params.isFront ? null : currentProfile.cCardBackUrl,
      createdAt: currentProfile.createdAt,
      updatedAt: currentProfile.updatedAt,
    );

    await userRepository.saveUserProfile(updatedProfile);
    return updatedProfile;
  }
}
