import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

/// ユーザープロファイルを1回取得するユースケース
class GetUserProfile implements UseCase<UserAccount?, String> {
  final UserRepository _repository;

  GetUserProfile(this._repository);

  @override
  Future<UserAccount?> call(String userId) async {
    return _repository.getUserProfile(userId);
  }
}
