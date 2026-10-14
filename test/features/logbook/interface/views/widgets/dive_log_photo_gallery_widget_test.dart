import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scuba_life/features/logbook/interface/views/widgets/dive_log_photo_gallery_widget.dart';

void main() {
  group('DiveLogPhotoGalleryWidget Tests', () {
    testWidgets('写真が空の場合は何も描画されないこと', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DiveLogPhotoGalleryWidget(
              photoUrls: [],
              locationName: '大瀬崎',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('水中写真・思い出ギャラリー'), findsNothing);
    });

    testWidgets('写真がある場合はタイトル、枚数バッジ、各サムネイルが描画されること', (tester) async {
      final samplePhotos = [
        'https://mockstorage.example.com/p1.webp',
        'https://mockstorage.example.com/p2.webp',
        'https://mockstorage.example.com/p3.webp',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiveLogPhotoGalleryWidget(
                photoUrls: samplePhotos,
                locationName: '大瀬崎 湾内',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('水中写真・思い出ギャラリー'), findsOneWidget);
      expect(find.text('3枚'), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsNWidgets(3));
    });

    testWidgets('小型画面（幅360px）でもオーバーフローなく描画できること', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final samplePhotos = [
        'https://mockstorage.example.com/p1.webp',
        'https://mockstorage.example.com/p2.webp',
        'https://mockstorage.example.com/p3.webp',
        'https://mockstorage.example.com/p4.webp',
        'https://mockstorage.example.com/p5.webp',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiveLogPhotoGalleryWidget(
                photoUrls: samplePhotos,
                locationName: '白浜沈船',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('5枚'), findsOneWidget);
    });
  });
}
