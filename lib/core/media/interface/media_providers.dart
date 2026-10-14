import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/media_storage_repository.dart';
import '../domain/services/image_picker_service.dart';
import '../infrastructure/default_image_picker_service.dart';
import '../infrastructure/fake_image_picker_service.dart';
import '../infrastructure/firebase_media_storage_repository.dart';
import '../infrastructure/in_memory_media_storage_repository.dart';

/// メディアストレージリポジトリを提供する Provider
/// テスト環境等で容易に override 可能
final mediaStorageRepositoryProvider = Provider<MediaStorageRepository>((ref) {
  try {
    return FirebaseMediaStorageRepository();
  } catch (_) {
    return InMemoryMediaStorageRepository();
  }
});

/// 画像ピッカーサービスを提供する Provider
/// テスト環境等で容易に override 可能
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  try {
    return DefaultImagePickerService();
  } catch (_) {
    return FakeImagePickerService();
  }
});
