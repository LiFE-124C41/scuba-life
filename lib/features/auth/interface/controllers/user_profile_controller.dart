import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/user_repository.dart';
import '../../infrastructure/repositories/firestore_user_repository.dart';
import '../../usecase/get_user_profile.dart';
import '../../usecase/sync_initial_profile.dart';
import '../../usecase/update_user_profile.dart';
import '../../usecase/watch_user_profile.dart';
import 'auth_controller.dart';

// --- DI Providers ---

/// ユーザープロファイルリポジトリProvider（テスト時は override 可能）
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository();
});

/// UseCase Providers
final watchUserProfileUseCaseProvider = Provider<WatchUserProfile>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return WatchUserProfile(repository);
});

final getUserProfileUseCaseProvider = Provider<GetUserProfile>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserProfile(repository);
});

final updateUserProfileUseCaseProvider = Provider<UpdateUserProfile>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateUserProfile(repository);
});

final syncInitialProfileUseCaseProvider = Provider<SyncInitialProfile>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return SyncInitialProfile(repository);
});

// --- State Providers ---

/// ログイン中ユーザーの最新プロファイル情報（Firestore `/users/{userId}`）をリアルタイムに監視する Provider
final currentUserProfileProvider = StreamProvider<UserAccount?>((ref) async* {
  final authState = ref.watch(authStateProvider);
  final authUser = authState.asData?.value;

  if (authUser == null) {
    yield null;
    return;
  }

  // 初回同期（ドキュメント未作成時は生成）
  final syncInitialProfile = ref.watch(syncInitialProfileUseCaseProvider);
  try {
    await syncInitialProfile(authUser);
  } catch (_) {
    // ネットワークエラーやオフライン時等は Auth 側の情報でフォールバック
  }

  final watchUserProfile = ref.watch(watchUserProfileUseCaseProvider);
  yield* watchUserProfile(authUser.id).map((profile) => profile ?? authUser);
});

// --- Action Controller ---

final userProfileControllerProvider =
    AsyncNotifierProvider<UserProfileNotifier, void>(UserProfileNotifier.new);

class UserProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// プロファイル（Cカード情報、表示名、オフセット本数等）の更新
  Future<bool> updateProfile({
    required String userId,
    String? displayName,
    String? certificationOrg,
    String? certificationLevel,
    String? cCardNumber,
    int? totalDivesOffset,
  }) async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(updateUserProfileUseCaseProvider);
      await useCase(UpdateUserProfileParams(
        userId: userId,
        displayName: displayName,
        certificationOrg: certificationOrg,
        certificationLevel: certificationLevel,
        cCardNumber: cCardNumber,
        totalDivesOffset: totalDivesOffset,
      ));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}
