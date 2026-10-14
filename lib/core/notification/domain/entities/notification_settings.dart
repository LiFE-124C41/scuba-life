/// 通知設定のドメインエンティティ
class NotificationSettings {
  /// 通知全体の有効/無効
  final bool notificationsEnabled;

  /// 機材OH目安リマインダーの有効/無効
  final bool gearOverhaulReminderEnabled;

  /// トリップ前日準備リマインダーの有効/無効
  final bool tripReminderEnabled;

  /// トリップ前日通知時刻（時、0〜23）
  final int tripReminderHour;

  /// OH目安通知の何日前に通知するか
  final int overhaulDaysBefore;

  /// OH残り本数アラート閾値（本）
  final int overhaulDivesThreshold;

  /// 海況・気象アラートプッシュ通知（FCM）の有効/無効
  final bool weatherAlertPushEnabled;

  /// 運営・スポット新着お知らせプッシュ通知（FCM）の有効/無効
  final bool announcementPushEnabled;

  const NotificationSettings({
    this.notificationsEnabled = true,
    this.gearOverhaulReminderEnabled = true,
    this.tripReminderEnabled = true,
    this.tripReminderHour = 18,
    this.overhaulDaysBefore = 30,
    this.overhaulDivesThreshold = 10,
    this.weatherAlertPushEnabled = true,
    this.announcementPushEnabled = true,
  });

  NotificationSettings copyWith({
    bool? notificationsEnabled,
    bool? gearOverhaulReminderEnabled,
    bool? tripReminderEnabled,
    int? tripReminderHour,
    int? overhaulDaysBefore,
    int? overhaulDivesThreshold,
    bool? weatherAlertPushEnabled,
    bool? announcementPushEnabled,
  }) {
    return NotificationSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      gearOverhaulReminderEnabled:
          gearOverhaulReminderEnabled ?? this.gearOverhaulReminderEnabled,
      tripReminderEnabled: tripReminderEnabled ?? this.tripReminderEnabled,
      tripReminderHour: tripReminderHour ?? this.tripReminderHour,
      overhaulDaysBefore: overhaulDaysBefore ?? this.overhaulDaysBefore,
      overhaulDivesThreshold:
          overhaulDivesThreshold ?? this.overhaulDivesThreshold,
      weatherAlertPushEnabled:
          weatherAlertPushEnabled ?? this.weatherAlertPushEnabled,
      announcementPushEnabled:
          announcementPushEnabled ?? this.announcementPushEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'gearOverhaulReminderEnabled': gearOverhaulReminderEnabled,
      'tripReminderEnabled': tripReminderEnabled,
      'tripReminderHour': tripReminderHour,
      'overhaulDaysBefore': overhaulDaysBefore,
      'overhaulDivesThreshold': overhaulDivesThreshold,
      'weatherAlertPushEnabled': weatherAlertPushEnabled,
      'announcementPushEnabled': announcementPushEnabled,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      gearOverhaulReminderEnabled:
          json['gearOverhaulReminderEnabled'] as bool? ?? true,
      tripReminderEnabled: json['tripReminderEnabled'] as bool? ?? true,
      tripReminderHour: json['tripReminderHour'] as int? ?? 18,
      overhaulDaysBefore: json['overhaulDaysBefore'] as int? ?? 30,
      overhaulDivesThreshold: json['overhaulDivesThreshold'] as int? ?? 10,
      weatherAlertPushEnabled:
          json['weatherAlertPushEnabled'] as bool? ?? true,
      announcementPushEnabled:
          json['announcementPushEnabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettings &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled &&
          gearOverhaulReminderEnabled == other.gearOverhaulReminderEnabled &&
          tripReminderEnabled == other.tripReminderEnabled &&
          tripReminderHour == other.tripReminderHour &&
          overhaulDaysBefore == other.overhaulDaysBefore &&
          overhaulDivesThreshold == other.overhaulDivesThreshold &&
          weatherAlertPushEnabled == other.weatherAlertPushEnabled &&
          announcementPushEnabled == other.announcementPushEnabled;

  @override
  int get hashCode =>
      notificationsEnabled.hashCode ^
      gearOverhaulReminderEnabled.hashCode ^
      tripReminderEnabled.hashCode ^
      tripReminderHour.hashCode ^
      overhaulDaysBefore.hashCode ^
      overhaulDivesThreshold.hashCode ^
      weatherAlertPushEnabled.hashCode ^
      announcementPushEnabled.hashCode;
}
