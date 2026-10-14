import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/infrastructure/repositories/firestore_dive_log_repository.dart';

void main() {
  group('FirestoreDiveLogRepository Unit Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late FirestoreDiveLogRepository repository;

    final testLog = DiveLog(
      id: 'log-001',
      scheduleId: 'sch-001',
      entryTime: DateTime(2026, 10, 10, 10, 0),
      exitTime: DateTime(2026, 10, 10, 10, 45),
      location: '大瀬崎 湾内',
      spotId: 'spot-osezaki-1',
      latitude: 35.0308,
      longitude: 138.7903,
      diveCenter: '大瀬館マリンサービス',
      rating: 5,
      divePurpose: 'ファンダイビング',
      entryMethod: 'ビーチ',
      waterArea: '海洋',
      waterType: '海水',
      maxDepthMeter: 18.5,
      avgDepthMeter: 11.2,
      startPressureBar: 200.0,
      endPressureBar: 60.0,
      tankVolumeLiter: 10.0,
      cylinderMaterial: 'スチール',
      weather: '晴れ',
      airTemp: 22.0,
      waterTempMin: 19.0,
      waterTempMax: 20.5,
      visibilityMeter: 15.0,
      underwaterCurrent: '弱',
      surfaceCurrent: '穏やか',
      tideType: '中潮',
      buddies: const ['バディA', 'バディB'],
      marineLife: const ['ミジンベニハゼ', 'タカベ群れ'],
      selectedGearIds: const ['gear-reg-1', 'gear-bcd-1'],
      equipment: 'スチール10L',
      notes: '透明度良好、快適なダイブ。',
      photoUrls: const ['https://storage.example.com/photo1.webp', 'https://storage.example.com/photo2.webp'],
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = FirestoreDiveLogRepository(
        userId: 'test-user-123',
        firestore: fakeFirestore,
      );
    });

    test('saveLog & getLogById: ログが正常に保存され、全フィールドが復元されること', () async {
      // Act
      await repository.saveLog(testLog);
      final fetched = await repository.getLogById('log-001');

      // Assert
      expect(fetched, isNotNull);
      expect(fetched!.id, equals('log-001'));
      expect(fetched.scheduleId, equals('sch-001'));
      expect(fetched.location, equals('大瀬崎 湾内'));
      expect(fetched.rating, equals(5));
      expect(fetched.maxDepthMeter, equals(18.5));
      expect(fetched.avgDepthMeter, equals(11.2));
      expect(fetched.startPressureBar, equals(200.0));
      expect(fetched.endPressureBar, equals(60.0));
      expect(fetched.buddies, containsAll(['バディA', 'バディB']));
      expect(fetched.marineLife, containsAll(['ミジンベニハゼ', 'タカベ群れ']));
      expect(fetched.selectedGearIds, containsAll(['gear-reg-1', 'gear-bcd-1']));
      expect(fetched.notes, equals('透明度良好、快適なダイブ。'));
      expect(fetched.photoUrls, containsAll(['https://storage.example.com/photo1.webp', 'https://storage.example.com/photo2.webp']));
    });

    test('getAllLogs: 保存された複数のログが一覧取得できること', () async {
      // Arrange
      await repository.saveLog(testLog);
      final secondLog = testLog.copyWith(
        id: 'log-002',
        entryTime: DateTime(2026, 10, 11, 13, 0),
        exitTime: DateTime(2026, 10, 11, 13, 40),
        location: '伊豆海洋公園',
      );
      await repository.saveLog(secondLog);

      // Act
      final logs = await repository.getAllLogs();

      // Assert
      expect(logs.length, equals(2));
      expect(logs.any((l) => l.id == 'log-001'), isTrue);
      expect(logs.any((l) => l.id == 'log-002'), isTrue);
    });

    test('deleteLog: 指定したIDのログが削除されること', () async {
      // Arrange
      await repository.saveLog(testLog);

      // Act
      await repository.deleteLog('log-001');
      final fetched = await repository.getLogById('log-001');

      // Assert
      expect(fetched, isNull);
    });
  });
}
