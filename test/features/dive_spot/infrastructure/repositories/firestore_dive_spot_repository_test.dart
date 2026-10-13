import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';
import 'package:scuba_life/features/dive_spot/infrastructure/repositories/firestore_dive_spot_repository.dart';

void main() {
  group('FirestoreDiveSpotRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDiveSpotRepository repository;

    final customSpot = DiveSpot(
      id: 'spot-custom-001',
      name: 'シークレットケーブ',
      area: '沖縄県・本部町',
      latitude: 26.6800,
      longitude: 127.8800,
      description: '地元ダイバーおすすめの穴場ケーブスポット。',
      isFavorite: true,
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDiveSpotRepository(
        userId: 'test-user-123',
        firestore: fakeFirestore,
      );
    });

    test('getSpots: 初回呼び出し時にプリセットスポットがシードされ、全スポットが取得できること', () async {
      // Act
      final spots = await repository.getSpots();

      // Assert
      expect(spots.isNotEmpty, isTrue);
      expect(spots.any((s) => s.name.contains('大瀬崎')), isTrue);
      expect(spots.any((s) => s.name.contains('伊豆海洋公園')), isTrue);
    });

    test('addSpot: 新しいスポットを追加でき、取得できること', () async {
      // Act
      await repository.addSpot(customSpot);
      final fetched = await repository.getSpotById('spot-custom-001');

      // Assert
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('シークレットケーブ'));
      expect(fetched.area, equals('沖縄県・本部町'));
      expect(fetched.isFavorite, isTrue);
    });

    test('toggleFavorite: お気に入り状態がトグルされること', () async {
      // Arrange: スポットを追加
      await repository.addSpot(customSpot.copyWith(isFavorite: false));
      var spot = await repository.getSpotById('spot-custom-001');
      expect(spot!.isFavorite, isFalse);

      // Act: お気に入りにする
      await repository.toggleFavorite('spot-custom-001');
      spot = await repository.getSpotById('spot-custom-001');

      // Assert
      expect(spot!.isFavorite, isTrue);

      // Act: お気に入りを解除する
      await repository.toggleFavorite('spot-custom-001');
      spot = await repository.getSpotById('spot-custom-001');

      // Assert
      expect(spot!.isFavorite, isFalse);
    });
  });
}
