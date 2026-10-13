import '../../../core/usecase/usecase.dart';
import '../domain/repositories/auth_repository.dart';

/// パスワード再設定メール送信ユースケース
class SendPasswordReset implements UseCase<void, String> {
  final AuthRepository _repository;

  SendPasswordReset(this._repository);

  @override
  Future<void> call(String email) async {
    return _repository.sendPasswordResetEmail(email.trim());
  }
}
