import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dive_log.dart';
import '../../domain/entities/dive_statistics.dart';
import '../controllers/dive_statistics_controller.dart';
import 'dive_log_detail_page.dart';

/// インストラクター提示用 ダイバー統計・スキルシート画面
///
/// 新規で訪れるダイビングサービスやインストラクターに、
/// 自身の経験本数、最大深度、ブランク状況、エア消費傾向、
/// エントリー比率、潮流適性を一目で分かりやすく提示できる。
class DiveLogStatisticsPage extends ConsumerWidget {
  const DiveLogStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(diveStatisticsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイバー統計・スキルシート'),
        elevation: 0,
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('統計の取得に失敗しました: $err'),
          ),
        ),
        data: (stats) {
          if (stats.totalDives == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 64,
                      color: colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ダイブログがまだ登録されていません',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ログを記録すると、インストラクターに見せるための統計やスキルシートが自動作成されます。',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. トップ案内バナー
              _buildGuideBanner(context),
              const SizedBox(height: 16),

              // 2. メインサマリーカード（総ダイブ数、ブランク判定、累計時間）
              _buildMainProfileCard(context, stats),
              const SizedBox(height: 16),

              // 3. スキル・安全指標カード（水深、時間、SACレート）
              _buildSkillMetricsSection(context, stats),
              const SizedBox(height: 16),

              // 4. エントリー形式 & 潮流経験カード
              _buildEnvironmentSection(context, stats),
              const SizedBox(height: 16),

              // 5. 直近の潜水実績（最新ログ）
              _buildRecentDivesSection(context, stats.recentLogs),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  /// インストラクター提示用の案内バナー
  Widget _buildGuideBanner(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(
            Icons.badge_outlined,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '初めてのショップで、インストラクターにこの画面をそのまま提示してご活用ください。',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// メインプロファイルカード（総本数・ブランク・累計時間）
  Widget _buildMainProfileCard(BuildContext context, DiveStatistics stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ブランクステータスの色
    final Color statusColor;
    final IconData statusIcon;
    final int? days = stats.daysSinceLastDive;

    if (days == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
    } else if (days <= 30) {
      statusColor = Colors.teal;
      statusIcon = Icons.check_circle;
    } else if (days <= 90) {
      statusColor = Colors.blue;
      statusIcon = Icons.info;
    } else if (days <= 180) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = Colors.redAccent;
      statusIcon = Icons.error_outline;
    }

    final dateStr = stats.lastDiveDate != null
        ? '${stats.lastDiveDate!.year}/${stats.lastDiveDate!.month.toString().padLeft(2, '0')}/${stats.lastDiveDate!.day.toString().padLeft(2, '0')}'
        : '-';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              colorScheme.primaryContainer.withAlpha(70),
              colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 総本数表示
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '総ダイブ本数',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${stats.totalDives}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Dives (本)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // ステータスバッジ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(100)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        stats.statusBadgeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            // サブ指標（最終潜水日・ブランク日数・累計時間）
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最終潜水日 (ブランク)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days != null ? '$dateStr ($days日前)' : dateStr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: colorScheme.outlineVariant.withAlpha(80),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '累計水中時間',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stats.totalBottomTimeFormatted,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// スキル・安全指標カード（深度・潜水時間・SACレート）
  Widget _buildSkillMetricsSection(BuildContext context, DiveStatistics stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'スキル & 安全プロファイル',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _buildMetricBox(
                  context,
                  title: '最大経験水深',
                  value: '${stats.maxDepthMeter.toStringAsFixed(1)} m',
                  subtitle: 'ディープ経験値',
                  icon: Icons.vertical_align_bottom,
                ),
                _buildMetricBox(
                  context,
                  title: '平均最大水深',
                  value: '${stats.avgMaxDepthMeter.toStringAsFixed(1)} m',
                  subtitle: '通常の潜水レンジ',
                  icon: Icons.layers_outlined,
                ),
                _buildMetricBox(
                  context,
                  title: '平均潜水時間',
                  value: '${stats.avgBottomTimeMinutes.toStringAsFixed(0)} 分',
                  subtitle: '1ダイブあたり',
                  icon: Icons.timer_outlined,
                ),
                _buildMetricBox(
                  context,
                  title: '平均SACレート',
                  value: stats.avgSacRate != null
                      ? '${stats.avgSacRate!.toStringAsFixed(1)} L/分'
                      : '計算不可',
                  subtitle: '水面空気消費率(燃費)',
                  icon: Icons.air,
                  tooltip: '水面での1分間あたりの空気消費量目安。12〜16 L/min前後が一般的です。',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, size: 16, color: colorScheme.primary.withAlpha(180)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.tap,
        child: content,
      );
    }
    return content;
  }

  /// エントリー環境 & 潮流経験セクション
  Widget _buildEnvironmentSection(BuildContext context, DiveStatistics stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final boatRatioPercent = (stats.boatRatio * 100).toStringAsFixed(0);
    final beachRatioPercent = (stats.beachRatio * 100).toStringAsFixed(0);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined,
                    size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ダイブスタイル & 環境適性',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ボート vs ビーチ 比率
            Text(
              'エントリー形式比率',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: [
                    if (stats.boatDiveCount > 0)
                      Expanded(
                        flex: stats.boatDiveCount,
                        child: Container(color: Colors.blue),
                      ),
                    if (stats.beachDiveCount > 0)
                      Expanded(
                        flex: stats.beachDiveCount,
                        child: Container(color: Colors.amber),
                      ),
                    if (stats.otherEntryCount > 0)
                      Expanded(
                        flex: stats.otherEntryCount,
                        child: Container(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ボート: ${stats.boatDiveCount}本 ($boatRatioPercent%)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ビーチ: ${stats.beachDiveCount}本 ($beachRatioPercent%)',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // 潮流経験
            Text(
              '潮流・ドリフトダイビング経験度',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCurrentBadge(
                  context,
                  label: '強潮流',
                  count: stats.currentExperienceMap['強'] ?? 0,
                  color: Colors.redAccent,
                ),
                _buildCurrentBadge(
                  context,
                  label: '中潮流',
                  count: stats.currentExperienceMap['中'] ?? 0,
                  color: Colors.orange,
                ),
                _buildCurrentBadge(
                  context,
                  label: '弱潮流',
                  count: stats.currentExperienceMap['弱'] ?? 0,
                  color: Colors.blue,
                ),
                _buildCurrentBadge(
                  context,
                  label: '潮流なし',
                  count: stats.currentExperienceMap['なし'] ?? 0,
                  color: Colors.teal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBadge(
    BuildContext context, {
    required String label,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final hasExperience = count > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: hasExperience ? color.withAlpha(20) : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              hasExperience ? color.withAlpha(80) : Colors.grey.withAlpha(50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: hasExperience ? color : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count本',
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasExperience ? color : Colors.grey,
              fontWeight: hasExperience ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// 直近の潜水実績
  Widget _buildRecentDivesSection(
      BuildContext context, List<DiveLog> recentLogs) {
    if (recentLogs.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Icon(Icons.history, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                '直近の潜水実績（最新${recentLogs.length}本）',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...recentLogs.map((log) {
          final dateStr =
              '${log.date.year}/${log.date.month.toString().padLeft(2, '0')}/${log.date.day.toString().padLeft(2, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: colorScheme.outlineVariant.withAlpha(60),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      log.location,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Text('水深 ${log.maxDepthMeter.toStringAsFixed(1)}m'),
                    const SizedBox(width: 8),
                    Text('時間 ${log.bottomTimeMinutes}分'),
                    const SizedBox(width: 8),
                    Text(log.entryMethod),
                    if (log.underwaterCurrent.isNotEmpty &&
                        log.underwaterCurrent != 'なし') ...[
                      const SizedBox(width: 8),
                      Text('流れ:${log.underwaterCurrent}'),
                    ],
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiveLogDetailPage(logId: log.id),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
