import 'package:flutter/foundation.dart';

/// 認証済みユーザー情報を表すドメインエンティティ (Pure Dart)
///
/// Firebase SDKの `User` クラス等には依存せず、
/// ドメイン層として必要なプロパティのみを保持する。
@immutable
class UserAccount {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
  final String? certificationOrg;
  final String? certificationLevel;
  final String? cCardNumber;
  final int totalDivesOffset;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.certificationOrg,
    this.certificationLevel,
    this.cCardNumber,
    this.totalDivesOffset = 0,
    this.createdAt,
    this.updatedAt,
  });

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    String? certificationOrg,
    String? certificationLevel,
    String? cCardNumber,
    int? totalDivesOffset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      certificationOrg: certificationOrg ?? this.certificationOrg,
      certificationLevel: certificationLevel ?? this.certificationLevel,
      cCardNumber: cCardNumber ?? this.cCardNumber,
      totalDivesOffset: totalDivesOffset ?? this.totalDivesOffset,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAccount &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          isEmailVerified == other.isEmailVerified &&
          certificationOrg == other.certificationOrg &&
          certificationLevel == other.certificationLevel &&
          cCardNumber == other.cCardNumber &&
          totalDivesOffset == other.totalDivesOffset;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      isEmailVerified.hashCode ^
      certificationOrg.hashCode ^
      certificationLevel.hashCode ^
      cCardNumber.hashCode ^
      totalDivesOffset.hashCode;

  @override
  String toString() =>
      'UserAccount(id: $id, email: $email, displayName: $displayName, verified: $isEmailVerified, org: $certificationOrg, level: $certificationLevel, cCard: $cCardNumber, offset: $totalDivesOffset)';
}
