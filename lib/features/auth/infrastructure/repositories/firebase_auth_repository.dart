import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/errors/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// Firebase Authentication を利用した AuthRepository の具象実装
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthDataSource _dataSource;

  FirebaseAuthRepository({FirebaseAuthDataSource? dataSource})
      : _dataSource = dataSource ?? FirebaseAuthDataSource();

  @override
  Stream<UserAccount?> watchAuthState() {
    return _dataSource.watchAuthState().map(_toDomainUser);
  }

  @override
  UserAccount? get currentUser => _toDomainUser(_dataSource.currentUser);

  @override
  Future<UserAccount> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _dataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownAuthFailure('ユーザー情報の取得に失敗しました。');
      }
      return _toDomainUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  @override
  Future<UserAccount> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _dataSource.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const UnknownAuthFailure('ユーザーの作成に失敗しました。');
      }
      if (displayName != null && displayName.isNotEmpty) {
        await _dataSource.updateDisplayName(displayName);
        await _dataSource.reloadUser();
      }
      return _toDomainUser(_dataSource.currentUser ?? user)!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  @override
  Future<UserAccount> signInWithGoogle() async {
    try {
      final credential = await _dataSource.signInWithGoogle();
      final user = credential.user;
      if (user == null) {
        throw const UnknownAuthFailure('Googleユーザー情報の取得に失敗しました。');
      }
      return _toDomainUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (e) {
      throw UnknownAuthFailure(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      if (e is AuthFailure) rethrow;
      throw UnknownAuthFailure(e.toString());
    }
  }

  @override
  Future<void> reloadUser() async {
    try {
      await _dataSource.reloadUser();
    } catch (e) {
      throw UnknownAuthFailure(e.toString());
    }
  }

  /// Firebase の User をドメインの UserAccount にマッピング
  UserAccount? _toDomainUser(User? user) {
    if (user == null) return null;
    return UserAccount(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      updatedAt: user.metadata.lastSignInTime,
    );
  }

  /// FirebaseAuthException のエラーコードをドメインの AuthFailure に変換
  AuthFailure _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'wrong-password':
      case 'invalid-credential':
        return const InvalidEmailAndPasswordFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'sign-in-cancelled':
        return const SignInCancelledFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'network-request-failed':
        return const NetworkAuthFailure();
      default:
        return UnknownAuthFailure(e.message ?? '認証エラーが発生しました (${e.code})。');
    }
  }
}
