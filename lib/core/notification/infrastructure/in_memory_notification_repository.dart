import '../domain/entities/app_notification_item.dart';
import '../domain/repositories/notification_repository.dart';

/// テストおよびオフライン・初期環境用のインメモリ通知リポジトリ
class InMemoryNotificationRepository implements NotificationRepository {
  final Map<int, AppNotificationItem> _scheduledNotifications = {};
  final List<AppNotificationItem> _shownNotifications = [];
  bool permissionGranted = true;
  bool isInitialized = false;

  List<AppNotificationItem> get shownNotifications => List.unmodifiable(_shownNotifications);
  Map<int, AppNotificationItem> get scheduledNotifications => Map.unmodifiable(_scheduledNotifications);

  @override
  Future<void> initialize() async {
    isInitialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    return permissionGranted;
  }

  @override
  Future<void> scheduleNotification(AppNotificationItem notification) async {
    _scheduledNotifications[notification.id] = notification;
  }

  @override
  Future<void> showNotification(AppNotificationItem notification) async {
    _shownNotifications.add(notification);
  }

  @override
  Future<void> cancelNotification(int id) async {
    _scheduledNotifications.remove(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    _scheduledNotifications.clear();
  }

  @override
  Future<List<AppNotificationItem>> getPendingNotifications() async {
    return _scheduledNotifications.values.toList();
  }

  void clear() {
    _scheduledNotifications.clear();
    _shownNotifications.clear();
  }
}
