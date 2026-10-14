import '../domain/entities/notification_settings.dart';
import '../domain/repositories/notification_settings_repository.dart';

/// テストおよび初期用インメモリ設定リポジトリ
class InMemoryNotificationSettingsRepository
    implements NotificationSettingsRepository {
  NotificationSettings _settings;

  InMemoryNotificationSettingsRepository([NotificationSettings? initialSettings])
      : _settings = initialSettings ?? const NotificationSettings();

  @override
  Future<NotificationSettings> loadSettings() async {
    return _settings;
  }

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    _settings = settings;
  }
}
