import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/dive_spot/domain/entities/dive_spot.dart';

void main() {
  group('DiveSpot Entity Tests', () {
    test('正常系: 有効なパラメータで正しくインスタンス化できること', () {
      // Arrange & Act
      final spot = DiveSpot(
        id: 'spot-1',
        name: '大瀬崎 湾内',
        area: '静岡県・西伊豆',
        latitude: 35.0308,
        longitude: 138.7903,
        description: '初心者から上級者まで潜れる穏やかな湾内。',
        isFavorite: true,
      );

      // Assert
      expect(spot.id, 'spot-1');
      expect(spot.name, '大瀬崎 湾内');
      expect(spot.area, '静岡県・西伊豆');
      expect(spot.latitude, 35.0308);
      expect(spot.longitude, 138.7903);
      expect(spot.description, '初心者から上級者まで潜れる穏やかな湾内。');
      expect(spot.isFavorite, isTrue);
    });

    test('異常系: スポット名が空の場合はArgumentErrorをスローすること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveSpot(
          id: 'spot-1',
          name: '',
          area: '静岡県',
          latitude: 35.0,
          longitude: 138.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'スポット名は必須です。',
        )),
      );
    });

    test('異常系: エリア名が空の場合はArgumentErrorをスローすること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveSpot(
          id: 'spot-1',
          name: '大瀬崎',
          area: '   ',
          latitude: 35.0,
          longitude: 138.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          'エリア名は必須です。',
        )),
      );
    });

    test('異常系: 緯度が範囲外(-90〜90)の場合はArgumentErrorをスローすること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveSpot(
          id: 'spot-1',
          name: '大瀬崎',
          area: '静岡県',
          latitude: 91.0,
          longitude: 138.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          '緯度は-90から90の範囲である必要があります。',
        )),
      );
    });

    test('異常系: 経度が範囲外(-180〜180)の場合はArgumentErrorをスローすること', () {
      // Arrange & Act & Assert
      expect(
        () => DiveSpot(
          id: 'spot-1',
          name: '大瀬崎',
          area: '静岡県',
          latitude: 35.0,
          longitude: 181.0,
        ),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          '経度は-180から180の範囲である必要があります。',
        )),
      );
    });

    test('copyWith: 指定したプロパティのみ更新された新しいインスタンスが生成されること', () {
      // Arrange
      final spot = DiveSpot(
        id: 'spot-1',
        name: '大瀬崎 湾内',
        area: '静岡県・西伊豆',
        latitude: 35.0308,
        longitude: 138.7903,
      );

      // Act
      final updated = spot.copyWith(isFavorite: true, name: '大瀬崎 先端');

      // Assert
      expect(updated.id, spot.id);
      expect(updated.name, '大瀬崎 先端');
      expect(updated.isFavorite, isTrue);
      expect(updated.area, spot.area);
      expect(updated.latitude, spot.latitude);
    });

    test('等値比較: 同一プロパティを持つ別インスタンスが同一と判定されること', () {
      // Arrange
      final spot1 = DiveSpot(
        id: 'spot-1',
        name: '大瀬崎 湾内',
        area: '静岡県',
        latitude: 35.0,
        longitude: 138.0,
      );
      final spot2 = DiveSpot(
        id: 'spot-1',
        name: '大瀬崎 湾内',
        area: '静岡県',
        latitude: 35.0,
        longitude: 138.0,
      );

      // Act & Assert
      expect(spot1 == spot2, isTrue);
      expect(spot1.hashCode, spot2.hashCode);
    });
  });
}
