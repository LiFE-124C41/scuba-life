import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/firestore_user_repository.dart';

void main() {
  group('FirestoreUserRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreUserRepository repository;

    const testUser = UserAccount(
      id: 'user-001',
      email: 'diver@example.com',
      displayName: 'テストダイバー',
      certificationOrg: 'PADI',
      certificationLevel: 'AOW (アドヴァンスド)',
      cCardNumber: '1234567890',
      totalDivesOffset: 30,
      cCardFrontUrl: 'https://storage.example.com/front.webp',
      cCardBackUrl: 'https://storage.example.com/back.webp',
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreUserRepository(firestore: fakeFirestore);
    });

    test('saveUserProfile & getUserProfile: ユーザープロファイルが正しく保存され取得できること', () async {
      // Act
      await repository.saveUserProfile(testUser);
      final fetched = await repository.getUserProfile('user-001');

      // Assert
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('user-001'));
      expect(fetched.email, equals('diver@example.com'));
      expect(fetched.displayName, equals('テストダイバー'));
      expect(fetched.certificationOrg, equals('PADI'));
      expect(fetched.certificationLevel, equals('AOW (アドヴァンスド)'));
      expect(fetched.cCardNumber, equals('1234567890'));
      expect(fetched.totalDivesOffset, equals(30));
      expect(fetched.cCardFrontUrl, equals('https://storage.example.com/front.webp'));
      expect(fetched.cCardBackUrl, equals('https://storage.example.com/back.webp'));
    });

    test('syncInitialProfile: 未作成時は新規ドキュメントが作成されること', () async {
      // Act
      final synced = await repository.syncInitialProfile(testUser);

      // Assert
      expect(synced.id, equals('user-001'));
      final stored = await repository.getUserProfile('user-001');
      expect(stored, isNotNull);
      expect(stored!.email, equals('diver@example.com'));
    });

    test('watchUserProfile: リアルタイムにストリームでデータが流れること', () async {
      // Act & Assert
      expect(
        repository.watchUserProfile('user-001'),
        emitsInOrder([
          isNull, // 初期は存在しない
        ]),
      );
    });
  });
}
