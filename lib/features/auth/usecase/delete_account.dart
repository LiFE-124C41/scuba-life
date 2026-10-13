import '../../../core/usecase/usecase.dart';
import '../domain/errors/auth_failure.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/user_repository.dart';

/// 退会・アカウント完全削除ユースケース (Pure Dart)
class DeleteAccount implements UseCase<void, NoParams> {
  final AuthRepository authRepository;
  final UserRepository userRepository;

  DeleteAccount({
    required this.authRepository,
    required this.userRepository,
  });

  @override
  Future<void> call(NoParams params) async {
    final user = authRepository.currentUser;
    if (user == null) {
      throw const UserNotFoundFailure('ログインしていません。');
    }

    // 1. 先に Firestore ユーザーデータを削除（Auth削除後はセキュリティルールによりアクセス拒否されるため）
    try {
      await userRepository.deleteUserData(user.id);
    } catch (_) {
      // ネットワークや既存データ未存在の場合もAuth削除へ継続
    }

    // 2. Firebase Authentication のアカウントを完全削除
    await authRepository.deleteAccount();
  }
}
