import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/core/media/interface/widgets/app_cached_network_image.dart';

void main() {
  group('AppCachedNetworkImage Widget Tests', () {
    testWidgets('初期描画: AppCachedNetworkImage が例外なくビルドされること', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCachedNetworkImage(
              imageUrl: 'https://example.com/c_card.webp',
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppCachedNetworkImage), findsOneWidget);
    });

    testWidgets('カスタムプレースホルダーとエラーウィジェットが指定できること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedNetworkImage(
              imageUrl: 'https://example.com/custom.webp',
              placeholder: (context, url) => const Text('読み込み中プレースホルダー'),
              errorWidget: (context, url, error) => const Text('エラー発生ウィジェット'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('読み込み中プレースホルダー'), findsOneWidget);
    });
  });
}
