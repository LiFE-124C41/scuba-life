/// ダイビングポイント（スポット）エンティティ
///
/// 外部フレームワークに一切依存しないPure Dartクラス。
class DiveSpot {
  final String id;
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final String description;
  final bool isFavorite;

  DiveSpot({
    required this.id,
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    this.description = '',
    this.isFavorite = false,
  }) {
    if (name.trim().isEmpty) {
      throw ArgumentError('スポット名は必須です。');
    }
    if (area.trim().isEmpty) {
      throw ArgumentError('エリア名は必須です。');
    }
    if (latitude < -90.0 || latitude > 90.0) {
      throw ArgumentError('緯度は-90から90の範囲である必要があります。');
    }
    if (longitude < -180.0 || longitude > 180.0) {
      throw ArgumentError('経度は-180から180の範囲である必要があります。');
    }
  }

  DiveSpot copyWith({
    String? id,
    String? name,
    String? area,
    double? latitude,
    double? longitude,
    String? description,
    bool? isFavorite,
  }) {
    return DiveSpot(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiveSpot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          area == other.area &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          description == other.description &&
          isFavorite == other.isFavorite;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      area.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      description.hashCode ^
      isFavorite.hashCode;
}
