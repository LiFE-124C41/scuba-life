import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/remote_config/domain/entities/app_remote_config.dart';
import 'package:scuba_life/core/remote_config/infrastructure/in_memory_remote_config_repository.dart';
import 'package:scuba_life/core/remote_config/interface/remote_config_providers.dart';
import 'package:scuba_life/core/remote_config/interface/views/maintenance_banner_widget.dart';

void main() {
  Widget buildTestWidget({
    required InMemoryRemoteConfigRepository repo,
    Size screenSize = const Size(390, 844),
  }) {
    return ProviderScope(
      overrides: [
        remoteConfigRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  MaintenanceBannerWidget(),
                  Expanded(child: Center(child: Text('Main Content'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('MaintenanceBannerWidget Tests', () {
    testWidgets('maintenanceBannerEnabled が false の場合、バナーが表示されないこと',
        (tester) async {
      final repo = InMemoryRemoteConfigRepository(
        const AppRemoteConfig(
          maintenanceBannerEnabled: false,
          maintenanceBannerMessage: 'テストメッセージ',
        ),
      );

      await tester.pumpWidget(buildTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('重要なお知らせ'), findsNothing);
      expect(find.text('テストメッセージ'), findsNothing);
      expect(find.byType(MaintenanceBannerWidget), findsOneWidget);
    });

    testWidgets('maintenanceBannerEnabled が true の場合、バナーと文言が表示されること',
        (tester) async {
      final repo = InMemoryRemoteConfigRepository(
        const AppRemoteConfig(
          maintenanceBannerEnabled: true,
          maintenanceBannerMessage: '気象データ提供元の障害により海況情報が一部遅延しています',
        ),
      );

      await tester.pumpWidget(buildTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('重要なお知らせ'), findsOneWidget);
      expect(find.text('気象データ提供元の障害により海況情報が一部遅延しています'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byKey(const Key('dismiss_maintenance_banner_button')), findsOneWidget);
    });

    testWidgets('閉じるボタンをタップするとバナーが非表示になること', (tester) async {
      final repo = InMemoryRemoteConfigRepository(
        const AppRemoteConfig(
          maintenanceBannerEnabled: true,
          maintenanceBannerMessage: '緊急メンテナンスのお知らせ',
        ),
      );

      await tester.pumpWidget(buildTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('緊急メンテナンスのお知らせ'), findsOneWidget);

      final dismissButton = find.byKey(const Key('dismiss_maintenance_banner_button'));
      await tester.tap(dismissButton);
      await tester.pumpAndSettle();

      expect(find.text('緊急メンテナンスのお知らせ'), findsNothing);
    });

    testWidgets('幅360px（特殊アスペクト比2376x968等）の小型画面でもオーバーフローなく表示されること',
        (tester) async {
      final repo = InMemoryRemoteConfigRepository(
        const AppRemoteConfig(
          maintenanceBannerEnabled: true,
          maintenanceBannerMessage:
              '外部気象庁APIの計画メンテナンスに伴い、波高・風速・潮流予測データが2026年10月15日12:00までご利用いただけません。大変ご不便をおかけいたします。',
        ),
      );

      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestWidget(repo: repo, screenSize: const Size(360, 800)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('重要なお知らせ'), findsOneWidget);
      expect(find.byKey(const Key('dismiss_maintenance_banner_button')), findsOneWidget);
    });
  });
}
