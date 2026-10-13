import '../../../core/usecase/usecase.dart';
import '../domain/repositories/auth_repository.dart';

/// サインアウトユースケース
class SignOut implements UseCase<void, NoParams> {
  final AuthRepository _repository;

  SignOut(this._repository);

  @override
  Future<void> call(NoParams params) async {
    return _repository.signOut();
  }
}
