import '../../../core/media/domain/repositories/media_storage_repository.dart';
import '../../../core/usecase/usecase.dart';
import '../domain/errors/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';

/// 退会・アカウント完全削除ユースケース (Pure Dart)
class DeleteAccount implements UseCase<void, NoParams> {
  final AuthRepository authRepository;
  final UserRepository userRepository;
  final MediaStorageRepository? mediaStorageRepository;

  DeleteAccount({
    required this.authRepository,
    required this.userRepository,
    this.mediaStorageRepository,
  });

  @override
  Future<void> call(NoParams params) async {
    final user = authRepository.currentUser;
    if (user == null) {
      throw const UserNotFoundFailure('ログインしていません。');
    }

    // 1. Cloud Storage のユーザー固有ディレクトリ (/users/{userId}) を一括削除
    if (mediaStorageRepository != null) {
      try {
        await mediaStorageRepository!.deleteDirectory('users/${user.id}');
      } catch (_) {
        // 万一のストレージエラーでもアカウント退会フローは継続
      }
    }

    // 2. 先に Firestore ユーザーデータを削除（Auth削除後はセキュリティルールによりアクセス拒否されるため）
    try {
      await userRepository.deleteUserData(user.id);
    } catch (_) {
      // ネットワークや既存データ未存在の場合もAuth削除へ継続
    }

    // 3. Firebase Authentication のアカウントを完全削除
    await authRepository.deleteAccount();
  }
}
