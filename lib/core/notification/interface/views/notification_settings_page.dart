import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notification_providers.dart';

/// 安全リマインダー通知設定画面
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationSettingsNotifierProvider);
    final notifier = ref.read(notificationSettingsNotifierProvider.notifier);
    final settings = state.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知設定'),
        centerTitle: true,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // セクションヘッダー
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    '安全リマインダー設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),

                // 全体通知トグルカード
                _buildSettingCard(
                  context: context,
                  icon: Icons.notifications_active,
                  iconColor: Colors.blue,
                  title: 'プッシュ通知を有効にする',
                  description: '機材のメンテナンス時期や予定前日の持ち物リマインダーを受信します',
                  value: settings.notificationsEnabled,
                  onChanged: (val) => notifier.toggleNotificationsEnabled(val),
                ),
                const SizedBox(height: 12),

                // 機材OH通知トグルカード
                _buildSettingCard(
                  context: context,
                  icon: Icons.build_circle_outlined,
                  iconColor: Colors.orange,
                  title: '機材オーバーホール目安通知',
                  description:
                      '次回OH目安の${settings.overhaulDaysBefore}日前、またはダイブ本数が残り${settings.overhaulDivesThreshold}本以下に達した際にお知らせします',
                  value: settings.notificationsEnabled &&
                      settings.gearOverhaulReminderEnabled,
                  enabled: settings.notificationsEnabled,
                  onChanged: (val) => notifier.toggleGearOverhaulReminder(val),
                ),
                const SizedBox(height: 12),

                // トリップ前日準備リマインダートグルカード
                _buildSettingCard(
                  context: context,
                  icon: Icons.checklist_rtl,
                  iconColor: Colors.teal,
                  title: 'トリップ前日準備リマインダー',
                  description:
                      'ダイビング予定の前日${settings.tripReminderHour}:00に機材チェックリストの進捗をお知らせします',
                  value: settings.notificationsEnabled &&
                      settings.tripReminderEnabled,
                  enabled: settings.notificationsEnabled,
                  onChanged: (val) => notifier.toggleTripReminder(val),
                ),
                const SizedBox(height: 28),

                // テスト通知アクションエリア
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.science, color: Colors.indigo, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '通知の動作テスト',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '端末でローカル通知が正常に表示されるか今すぐ確認できます。OSの通知権限ダイアログが表示された場合は許可してください。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              key: const Key('send_test_notification_button'),
                              icon: const Icon(Icons.send),
                              label: const Text('テスト通知を送信'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () async {
                                await notifier.sendTestNotification();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('テスト通知を送信しました。端末の通知欄をご確認ください。'),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 注意書き
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '※ お使いの端末の省電力モードや「おやすみモード」の設定によっては、通知の表示が遅延・制限される場合があります。',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    bool enabled = true,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: enabled ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: enabled ? Colors.black54 : Colors.grey.shade400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}
