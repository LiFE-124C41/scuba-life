import 'dart:async';
import '../../domain/entities/user_account.dart';
import '../../domain/errors/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

/// テストおよびオフライン・デモ用のインメモリ認証リポジトリ実装
class InMemoryAuthRepository implements AuthRepository {
  final StreamController<UserAccount?> _authStateController =
      StreamController<UserAccount?>.broadcast();

  final Map<String, String> _userPasswords = {}; // email -> password
  final Map<String, UserAccount> _usersByEmail = {}; // email -> UserAccount
  UserAccount? _currentUser;

  InMemoryAuthRepository({UserAccount? initialUser}) {
    if (initialUser != null) {
      _currentUser = initialUser;
      _usersByEmail[initialUser.email] = initialUser;
      _userPasswords[initialUser.email] = 'password123';
    }
  }

  @override
  UserAccount? get currentUser => _currentUser;

  @override
  Stream<UserAccount?> watchAuthState() async* {
    yield _currentUser;
    yield* _authStateController.stream;
  }

  @override
  Future<UserAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = _usersByEmail[email];
    if (user == null) {
      throw const UserNotFoundFailure();
    }
    if (_userPasswords[email] != password) {
      throw const InvalidEmailAndPasswordFailure();
    }
    _currentUser = user;
    _authStateController.add(_currentUser);
    return user;
  }

  @override
  Future<UserAccount> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    if (password.length < 6) {
      throw const WeakPasswordFailure();
    }
    if (_usersByEmail.containsKey(email)) {
      throw const EmailAlreadyInUseFailure();
    }

    final newUser = UserAccount(
      id: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _usersByEmail[email] = newUser;
    _userPasswords[email] = password;
    _currentUser = newUser;
    _authStateController.add(_currentUser);
    return newUser;
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    final googleUser = UserAccount(
      id: 'google-uid-${DateTime.now().millisecondsSinceEpoch}',
      email: 'diver.google@example.com',
      displayName: 'Google Diver',
      photoUrl: 'https://example.com/avatar.png',
      isEmailVerified: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _currentUser = googleUser;
    _usersByEmail[googleUser.email] = googleUser;
    _authStateController.add(_currentUser);
    return googleUser;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (!_usersByEmail.containsKey(email)) {
      throw const UserNotFoundFailure();
    }
    // パスワード再設定メール送信処理（擬似成功）
  }

  @override
  Future<void> reloadUser() async {
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      _usersByEmail.remove(_currentUser!.email);
      _userPasswords.remove(_currentUser!.email);
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  void dispose() {
    _authStateController.close();
  }
}
