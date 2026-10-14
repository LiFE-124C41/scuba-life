import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../remote_config_providers.dart';

/// 緊急メンテナンス・外部API障害お知らせバナーウィジェット
class MaintenanceBannerWidget extends ConsumerWidget {
  const MaintenanceBannerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remoteConfig = ref.watch(remoteConfigNotifierProvider);

    // バナーが無効またはメッセージが空の場合は非表示
    if (!remoteConfig.maintenanceBannerEnabled ||
        remoteConfig.maintenanceBannerMessage.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade400, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.amber.shade900,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '重要なお知らせ',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remoteConfig.maintenanceBannerMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.brown.shade900,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('dismiss_maintenance_banner_button'),
            icon: Icon(Icons.close, size: 18, color: Colors.brown.shade700),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            tooltip: '閉じる',
            onPressed: () {
              ref.read(remoteConfigNotifierProvider.notifier).dismissBanner();
            },
          ),
        ],
      ),
    );
  }
}
