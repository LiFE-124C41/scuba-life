import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/auth/domain/entities/user_account.dart';
import 'package:scuba_life/features/auth/infrastructure/repositories/firestore_user_repository.dart';
import 'package:scuba_life/features/dive_spot/infrastructure/repositories/firestore_dive_spot_repository.dart';
import 'package:scuba_life/features/logbook/domain/entities/dive_log.dart';
import 'package:scuba_life/features/logbook/infrastructure/repositories/firestore_dive_log_repository.dart';
import 'package:scuba_life/features/my_gear/domain/entities/gear_item.dart';
import 'package:scuba_life/features/my_gear/infrastructure/repositories/firestore_gear_repository.dart';
import 'package:scuba_life/features/schedule/domain/entities/dive_schedule.dart';
import 'package:scuba_life/features/schedule/infrastructure/repositories/firestore_schedule_repository.dart';

void main() {
  group('Firestore Offline & Resilience Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    const testUserId = 'test_diver_offline_user';

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('DiveSpot: 初回起動でサーバー接続に失敗・空の場合でもプリセット9スポットに安全フォールバックすること', () async {
      final spotRepo = FirestoreDiveSpotRepository(
        userId: testUserId,
        firestore: fakeFirestore,
      );

      // Act: 初回アクセス
      final spots = await spotRepo.getSpots();

      // Assert
      expect(spots.length, equals(FirestoreDiveSpotRepository.defaultPresetSpots.length));
      expect(spots.first.name, equals('大瀬崎 湾内'));
    });

    test('DiveSpot: 未登録スポットの個別検索時でもプリセットから安全に取得できること', () async {
      final spotRepo = FirestoreDiveSpotRepository(
        userId: testUserId,
        firestore: fakeFirestore,
      );

      // Act
      final spot = await spotRepo.getSpotById('spot-iop-1');

      // Assert
      expect(spot, isNotNull);
      expect(spot!.name, contains('伊豆海洋公園'));
    });

    test('DiveLog: オフライン保存したログがキャッシュから即座に取得できること', () async {
      final logRepo = FirestoreDiveLogRepository(
        userId: testUserId,
        firestore: fakeFirestore,
      );

      final log = DiveLog(
        id: 'offline-log-001',
        entryTime: DateTime(2026, 10, 12, 10, 0),
        exitTime: DateTime(2026, 10, 12, 10, 45),
        location: '大瀬崎 先端',
        maxDepthMeter: 24.5,
        avgDepthMeter: 14.2,
        startPressureBar: 200.0,
        endPressureBar: 50.0,
        tankVolumeLiter: 10.0,
      );

      // Act: 保存して取得
      await logRepo.saveLog(log);
      final logs = await logRepo.getAllLogs();
      final fetched = await logRepo.getLogById('offline-log-001');

      // Assert
      expect(logs.length, equals(1));
      expect(logs.first.id, equals('offline-log-001'));
      expect(logs.first.location, equals('大瀬崎 先端'));
      expect(fetched, isNotNull);
      expect(fetched!.maxDepthMeter, equals(24.5));
    });

    test('Gear: オフライン状態で登録・更新した機材データが安全に保持されること', () async {
      final gearRepo = FirestoreGearRepository(
        userId: testUserId,
        firestore: fakeFirestore,
      );

      final gear = GearItem(
        id: 'offline-gear-001',
        name: 'Aqualung Legend 3',
        category: GearCategory.regulator,
        purchaseDate: DateTime(2025, 5, 1),
        divesSinceOverhaul: 15,
        overhaulIntervalMonths: 12,
        overhaulIntervalDives: 100,
      );

      // Act
      await gearRepo.saveGear(gear);
      final items = await gearRepo.getAllGear();
      final fetched = await gearRepo.getGearById('offline-gear-001');

      // Assert
      expect(items.length, equals(1));
      expect(items.first.name, equals('Aqualung Legend 3'));
      expect(fetched, isNotNull);
      expect(fetched!.divesSinceOverhaul, equals(15));
    });

    test('Schedule: オフライン状態での予定登録およびチェックリストが保持されること', () async {
      final scheduleRepo = FirestoreScheduleRepository(
        userId: testUserId,
        firestore: fakeFirestore,
      );

      final schedule = DiveSchedule(
        id: 'offline-schedule-001',
        title: '伊豆大島 秋のダイブツアー',
        eventDate: DateTime(2026, 11, 3),
        destination: '伊豆大島',
        diveShop: '大島ダイビングサービス',
        checkedGearIds: const ['gear-001'],
        targetGearIds: const ['gear-001', 'gear-002'],
      );

      // Act
      await scheduleRepo.addSchedule(schedule);
      final schedules = await scheduleRepo.getUpcomingSchedules();

      // Assert
      expect(schedules.length, equals(1));
      expect(schedules.first.title, equals('伊豆大島 秋のダイブツアー'));
      expect(schedules.first.checkedGearIds, contains('gear-001'));
      expect(schedules.first.targetGearIds, contains('gear-002'));
    });

    test('UserProfile: オフライン時のプロファイル取得が安全に動作すること', () async {
      final userRepo = FirestoreUserRepository(
        firestore: fakeFirestore,
      );

      final user = const UserAccount(
        id: testUserId,
        email: 'diver@ocean.jp',
        displayName: '海風ダイバー',
        certificationOrg: 'PADI',
        certificationLevel: 'AOW',
        totalDivesOffset: 85,
      );

      // Act
      await userRepo.saveUserProfile(user);
      final profile = await userRepo.getUserProfile(testUserId);

      // Assert
      expect(profile, isNotNull);
      expect(profile!.displayName, equals('海風ダイバー'));
      expect(profile.certificationOrg, equals('PADI'));
      expect(profile.totalDivesOffset, equals(85));
    });
  });
}
