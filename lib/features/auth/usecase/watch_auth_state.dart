import '../domain/entities/user_account.dart';
import '../domain/repositories/auth_repository.dart';

/// 認証状態をリアルタイムに監視するユースケース
class WatchAuthState {
  final AuthRepository _repository;

  WatchAuthState(this._repository);

  Stream<UserAccount?> call() {
    return _repository.watchAuthState();
  }
}
