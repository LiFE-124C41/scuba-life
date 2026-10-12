import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/auth_repository.dart';

/// Googleアカウントによるサインインユースケース
class SignInWithGoogle implements UseCase<UserAccount, NoParams> {
  final AuthRepository _repository;

  SignInWithGoogle(this._repository);

  @override
  Future<UserAccount> call(NoParams params) async {
    return _repository.signInWithGoogle();
  }
}
