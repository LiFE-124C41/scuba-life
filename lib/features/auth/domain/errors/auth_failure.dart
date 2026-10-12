import '../../../../core/error/failures.dart';

/// 認証関連のドメインエラー抽象クラス
abstract class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// メールアドレスまたはパスワードが正しくない場合のエラー
class InvalidEmailAndPasswordFailure extends AuthFailure {
  const InvalidEmailAndPasswordFailure([
    super.message = 'メールアドレスまたはパスワードが正しくありません。',
  ]);
}

/// 指定のメールアドレスが既に登録されている場合のエラー
class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure([
    super.message = 'このメールアドレスは既に登録されています。',
  ]);
}

/// ユーザーが存在しない場合のエラー
class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure([
    super.message = 'アカウントが見つかりませんでした。新規登録をお試しください。',
  ]);
}

/// パスワード強度が不足している場合のエラー
class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure([
    super.message = 'パスワードは6文字以上で入力してください。',
  ]);
}

/// アカウントが無効化されている場合のエラー
class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure([
    super.message = 'このアカウントは現在無効化されています。管理者にお問い合わせください。',
  ]);
}

/// 認証処理がユーザーによってキャンセルされた場合（Googleサインイン等）
class SignInCancelledFailure extends AuthFailure {
  const SignInCancelledFailure([
    super.message = 'サインインがキャンセルされました。',
  ]);
}

/// 試行回数超過など一時的な制限エラー
class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure([
    super.message = 'ログイン試行回数が上限を超えました。しばらく時間をおいてから再試行してください。',
  ]);
}

/// ネットワーク通信エラー
class NetworkAuthFailure extends AuthFailure {
  const NetworkAuthFailure([
    super.message = 'ネットワーク通信に失敗しました。接続環境をご確認ください。',
  ]);
}

/// 再認証（再ログイン）が必要な場合のエラー（退会・PW変更等の重要操作時）
class RequiresRecentLoginFailure extends AuthFailure {
  const RequiresRecentLoginFailure([
    super.message = 'セキュリティ保護のため再ログインが必要です。一度ログアウトし、再ログイン後にもう一度お試しください。',
  ]);
}

/// 原因不明・未分類の認証エラー
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([
    super.message = '認証処理中に予期せぬエラーが発生しました。',
  ]);
}

