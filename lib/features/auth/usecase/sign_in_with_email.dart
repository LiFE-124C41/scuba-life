import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/auth_repository.dart';

class SignInWithEmailParams {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });
}

/// メールアドレスとパスワードによるサインインユースケース
class SignInWithEmail implements UseCase<UserAccount, SignInWithEmailParams> {
  final AuthRepository _repository;

  SignInWithEmail(this._repository);

  @override
  Future<UserAccount> call(SignInWithEmailParams params) async {
    return _repository.signInWithEmail(
      email: params.email.trim(),
      password: params.password,
    );
  }
}
