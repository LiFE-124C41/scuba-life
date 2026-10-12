import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

/// ユーザープロファイルをリアルタイムに監視するユースケース
class WatchUserProfile {
  final UserRepository _repository;

  WatchUserProfile(this._repository);

  Stream<UserAccount?> call(String userId) {
    return _repository.watchUserProfile(userId);
  }
}
