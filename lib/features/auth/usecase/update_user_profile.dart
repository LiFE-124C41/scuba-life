import '../../../core/usecase/usecase.dart';
import '../domain/entities/user_account.dart';
import '../domain/repositories/user_repository.dart';

/// ユーザープロファイル更新パラメータ
class UpdateUserProfileParams {
  final String userId;
  final String? displayName;
  final String? photoUrl;
  final String? certificationOrg;
  final String? certificationLevel;
  final String? cCardNumber;
  final int? totalDivesOffset;

  const UpdateUserProfileParams({
    required this.userId,
    this.displayName,
    this.photoUrl,
    this.certificationOrg,
    this.certificationLevel,
    this.cCardNumber,
    this.totalDivesOffset,
  });
}

/// ユーザープロファイルを更新・保存するユースケース
class UpdateUserProfile implements UseCase<UserAccount, UpdateUserProfileParams> {
  final UserRepository _repository;

  UpdateUserProfile(this._repository);

  @override
  Future<UserAccount> call(UpdateUserProfileParams params) async {
    final currentProfile = await _repository.getUserProfile(params.userId);

    final updatedProfile = (currentProfile ??
            UserAccount(
              id: params.userId,
              email: '',
            ))
        .copyWith(
      displayName: params.displayName,
      photoUrl: params.photoUrl,
      certificationOrg: params.certificationOrg,
      certificationLevel: params.certificationLevel,
      cCardNumber: params.cCardNumber,
      totalDivesOffset: params.totalDivesOffset,
      updatedAt: DateTime.now(),
    );

    await _repository.saveUserProfile(updatedProfile);
    return updatedProfile;
  }
}
