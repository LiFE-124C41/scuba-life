import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// 地図上にプロットするマーカー情報
class MapPointItem {
  final String id;
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;
  final Color pinColor;
  final IconData pinIcon;
  final VoidCallback? onTap;

  const MapPointItem({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.latitude,
    required this.longitude,
    this.pinColor = const Color(0xFF0077B6),
    this.pinIcon = Icons.location_on,
    this.onTap,
  });
}

/// OpenStreetMap を利用したダイビングポイント共通地図ウィジェット
class SpotMapWidget extends StatelessWidget {
  final List<MapPointItem> points;
  final LatLng? initialCenter;
  final double initialZoom;
  final bool isInteractive;
  final ValueChanged<MapPointItem>? onPointSelected;

  const SpotMapWidget({
    super.key,
    required this.points,
    this.initialCenter,
    this.initialZoom = 11.0,
    this.isInteractive = true,
    this.onPointSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 中心座標の算出
    final center = initialCenter ??
        (points.isNotEmpty
            ? LatLng(points.first.latitude, points.first.longitude)
            : const LatLng(35.0308, 138.7903)); // デフォルトは大瀬崎

    final markers = points.map((p) {
      return Marker(
        point: LatLng(p.latitude, p.longitude),
        width: 44,
        height: 44,
        child: GestureDetector(
          onTap: () {
            if (p.onTap != null) {
              p.onTap!();
            }
            if (onPointSelected != null) {
              onPointSelected!(p);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(51),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  p.pinIcon,
                  color: p.pinColor,
                  size: 24,
                ),
              ),
              CustomPaint(
                size: const Size(8, 6),
                painter: _PinArrowPainter(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: initialZoom,
        interactionOptions: InteractionOptions(
          flags: isInteractive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.scuba_life',
          maxZoom: 19,
          // タイル読み込み失敗時もUIがクラッシュしないように安全にフォールバック
          errorTileCallback: (tile, error, stackTrace) {},
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }
}

class _PinArrowPainter extends CustomPainter {
  final Color color;

  _PinArrowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
