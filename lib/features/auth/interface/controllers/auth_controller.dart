import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../infrastructure/repositories/firebase_auth_repository.dart';
import '../../usecase/send_password_reset.dart';
import '../../usecase/sign_in_with_email.dart';
import '../../usecase/sign_in_with_google.dart';
import '../../usecase/sign_out.dart';
import '../../usecase/sign_up_with_email.dart';
import '../../usecase/watch_auth_state.dart';

// --- DI Providers ---

/// 認証リポジトリProvider（テストやモック時は容易にoverride可能）
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// UseCase Providers
final watchAuthStateUseCaseProvider = Provider<WatchAuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return WatchAuthState(repository);
});

final signInWithEmailUseCaseProvider = Provider<SignInWithEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmail(repository);
});

final signUpWithEmailUseCaseProvider = Provider<SignUpWithEmail>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmail(repository);
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogle>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogle(repository);
});

final signOutUseCaseProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});

final sendPasswordResetUseCaseProvider = Provider<SendPasswordReset>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SendPasswordReset(repository);
});

// --- Auth State Stream Provider ---

/// ログイン状態をリアルタイムに流す StreamProvider
final authStateProvider = StreamProvider<UserAccount?>((ref) {
  final watchAuthState = ref.watch(watchAuthStateUseCaseProvider);
  return watchAuthState();
});

// --- Action Controller (ログイン・登録・ログアウト等の非同期実行Notifier) ---

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionNotifier, void>(AuthActionNotifier.new);

class AuthActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// メールアドレスとパスワードでサインイン
  Future<UserAccount?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final usecase = ref.read(signInWithEmailUseCaseProvider);
      final user = await usecase(SignInWithEmailParams(
        email: email,
        password: password,
      ));
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// メールアドレスとパスワードで新規登録
  Future<UserAccount?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final usecase = ref.read(signUpWithEmailUseCaseProvider);
      final user = await usecase(SignUpWithEmailParams(
        email: email,
        password: password,
        displayName: displayName,
      ));
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Googleサインイン
  Future<UserAccount?> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final usecase = ref.read(signInWithGoogleUseCaseProvider);
      final user = await usecase(const NoParams());
      state = const AsyncValue.data(null);
      return user;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// サインアウト
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final usecase = ref.read(signOutUseCaseProvider);
      await usecase(const NoParams());
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// パスワード再設定メール送信
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      final usecase = ref.read(sendPasswordResetUseCaseProvider);
      await usecase(email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
