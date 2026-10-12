import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/auth_repository.dart';

class SignUpWithEmailParams {
  final String email;
  final String password;
  final String? displayName;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    this.displayName,
  });
}

/// メールアドレスとパスワードによる新規アカウント登録ユースケース
class SignUpWithEmail implements UseCase<UserAccount, SignUpWithEmailParams> {
  final AuthRepository _repository;

  SignUpWithEmail(this._repository);

  @override
  Future<UserAccount> call(SignUpWithEmailParams params) async {
    return _repository.signUpWithEmail(
      email: params.email.trim(),
      password: params.password,
      displayName: params.displayName?.trim(),
    );
  }
}
