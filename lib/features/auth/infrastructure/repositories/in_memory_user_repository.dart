import 'dart:async';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/user_repository.dart';

/// テストおよびオフライン・開発用のインメモリ UserRepository 実装
class InMemoryUserRepository implements UserRepository {
  final Map<String, UserAccount> _users = {};
  final Map<String, StreamController<UserAccount?>> _controllers = {};

  InMemoryUserRepository({Map<String, UserAccount>? initialUsers}) {
    if (initialUsers != null) {
      _users.addAll(initialUsers);
    }
  }

  StreamController<UserAccount?> _getController(String userId) {
    return _controllers.putIfAbsent(
      userId,
      () => StreamController<UserAccount?>.broadcast(),
    );
  }

  @override
  Stream<UserAccount?> watchUserProfile(String userId) async* {
    yield _users[userId];
    yield* _getController(userId).stream;
  }

  @override
  Future<UserAccount?> getUserProfile(String userId) async {
    return _users[userId];
  }

  @override
  Future<void> saveUserProfile(UserAccount user) async {
    _users[user.id] = user;
    _getController(user.id).add(user);
  }

  @override
  Future<UserAccount> syncInitialProfile(UserAccount user) async {
    final existing = _users[user.id];
    if (existing != null) {
      // 既存のドキュメントがあれば、最新のプロファイルを返す
      return existing;
    }
    // 未存在の場合は初期ドキュメントを作成
    _users[user.id] = user;
    _getController(user.id).add(user);
    return user;
  }

  @override
  Future<void> deleteUserData(String userId) async {
    _users.remove(userId);
    _controllers[userId]?.add(null);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
