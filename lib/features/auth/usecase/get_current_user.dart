import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/auth_repository.dart';

/// 現在ログイン中のユーザー情報を取得するユースケース
class GetCurrentUser implements UseCase<UserAccount?, NoParams> {
  final AuthRepository _repository;

  GetCurrentUser(this._repository);

  @override
  Future<UserAccount?> call(NoParams params) async {
    return _repository.currentUser;
  }
}
