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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserAccount({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  UserAccount copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
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
          isEmailVerified == other.isEmailVerified;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      displayName.hashCode ^
      photoUrl.hashCode ^
      isEmailVerified.hashCode;

  @override
  String toString() =>
      'UserAccount(id: $id, email: $email, displayName: $displayName, verified: $isEmailVerified)';
}
