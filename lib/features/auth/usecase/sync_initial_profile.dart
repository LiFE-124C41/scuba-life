import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

/// サインアップ・サインイン時の初期プロファイル同期ユースケース
class SyncInitialProfile implements UseCase<UserAccount, UserAccount> {
  final UserRepository _repository;

  SyncInitialProfile(this._repository);

  @override
  Future<UserAccount> call(UserAccount user) async {
    return _repository.syncInitialProfile(user);
  }
}
