import '../entities/user_account.dart';

/// 認証操作の抽象インターフェース (Pure Dart)
///
/// 具象実装（Firebase Auth, In-Memory 等）は infrastructure 層で提供し、
/// ドメイン層およびユースケース層はこの抽象にのみ依存する。
abstract class AuthRepository {
  /// 現在の認証状態（ログイン中ユーザーまたは null）をリアルタイムに監視するストリーム
  Stream<UserAccount?> watchAuthState();

  /// 現在ログイン中のユーザー情報を取得する（未ログイン時は null）
  UserAccount? get currentUser;

  /// メールアドレスとパスワードでサインインする
  Future<UserAccount> signInWithEmail({
    required String email,
    required String password,
  });

  /// メールアドレスとパスワードで新規アカウント登録する
  Future<UserAccount> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  /// Googleアカウントでサインインする
  Future<UserAccount> signInWithGoogle();

  /// サインアウトする
  Future<void> signOut();

  /// パスワード再設定用メールを送信する
  Future<void> sendPasswordResetEmail(String email);

  /// ユーザー情報を最新状態にリロードする
  Future<void> reloadUser();
}
