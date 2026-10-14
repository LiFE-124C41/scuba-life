import '../../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

class DeleteAvatarImageParams {
  final String userId;

  const DeleteAvatarImageParams({
    required this.userId,
  });
}

/// プロフィール写真（アバター画像）を Cloud Storage から削除し、プロファイルを更新するユースケース (Pure Dart)
class DeleteAvatarImage implements UseCase<UserAccount, DeleteAvatarImageParams> {
  final MediaStorageRepository mediaStorageRepository;
  final UserRepository userRepository;

  DeleteAvatarImage({
    required this.mediaStorageRepository,
    required this.userRepository,
  });

  @override
  Future<UserAccount> call(DeleteAvatarImageParams params) async {
    final currentProfile = await userRepository.getUserProfile(params.userId);
    if (currentProfile == null) {
      throw StateError('ユーザープロファイルが見つかりません。');
    }

    final targetUrl = currentProfile.photoUrl;

    // 1. Cloud Storage から削除
    if (targetUrl != null && targetUrl.isNotEmpty) {
      try {
        await mediaStorageRepository.deleteFile(targetUrl);
      } catch (_) {
        // 万一ファイルが既に存在しない場合等でもプロファイル更新は継続
      }
    }

    // 2. ユーザープロファイルから photoUrl を消去して保存
    final updatedProfile = currentProfile.copyWith(clearPhotoUrl: true);
    await userRepository.saveUserProfile(updatedProfile);

    return updatedProfile;
  }
}
