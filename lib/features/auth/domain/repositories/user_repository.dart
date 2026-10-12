import '../entities/user_account.dart';

/// ユーザープロファイル管理（Firestore /users/{userId}）の抽象リポジトリ (Pure Dart)
///
/// 外部DB (Cloud Firestore, In-Memory 等) の具象実装は infrastructure 層で提供し、
/// ドメイン層およびユースケース層はこの抽象にのみ依存する。
abstract class UserRepository {
  /// ユーザープロファイルのリアルタイムストリーム
  Stream<UserAccount?> watchUserProfile(String userId);

  /// ユーザープロファイルを1回取得
  Future<UserAccount?> getUserProfile(String userId);

  /// ユーザープロファイルの更新・保存
  Future<void> saveUserProfile(UserAccount user);

  /// サインアップ・サインイン時の初期プロファイル同期（ドキュメントが存在しない場合のみ作成し、最新を返す）
  Future<UserAccount> syncInitialProfile(UserAccount user);
}
