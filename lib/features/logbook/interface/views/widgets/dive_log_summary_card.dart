import 'package:flutter/material.dart';
import '../../../domain/entities/dive_statistics.dart';
import '../dive_log_statistics_page.dart';

/// ログ一覧画面上部に表示するコンパクトな統計サマリーカード
///
/// 総本数、最大水深、ブランク状況を一目で把握でき、
/// タップすることでインストラクター提示用の詳細統計画面へ遷移する。
class DiveLogSummaryCard extends StatelessWidget {
  final DiveStatistics statistics;

  const DiveLogSummaryCard({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ブランク日数に応じたステータスカラーとアイコン
    final Color badgeColor;
    final IconData badgeIcon;
    final int? days = statistics.daysSinceLastDive;

    if (days == null) {
      badgeColor = Colors.grey;
      badgeIcon = Icons.help_outline;
    } else if (days <= 30) {
      badgeColor = Colors.teal;
      badgeIcon = Icons.check_circle_outline;
    } else if (days <= 90) {
      badgeColor = Colors.blue;
      badgeIcon = Icons.info_outline;
    } else if (days <= 180) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.watch_later_outlined;
    } else {
      badgeColor = Colors.redAccent;
      badgeIcon = Icons.warning_amber_rounded;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DiveLogStatisticsPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer.withAlpha(60),
                colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // タイトル ＋ 「詳細統計」遷移ヒント
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.insights,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ダイバーサマリー',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '統計詳細',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 指標の横並び表示
              Row(
                children: [
                  // 総ダイブ数
                  Expanded(
                    flex: 4,
                    child: _buildMetricItem(
                      context,
                      label: '総ダイブ数',
                      value: '${statistics.totalDives}',
                      unit: '本',
                      highlight: true,
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: colorScheme.outlineVariant.withAlpha(100),
                  ),
                  // 最大深度
                  Expanded(
                    flex: 4,
                    child: _buildMetricItem(
                      context,
                      label: '最大深度',
                      value: statistics.maxDepthMeter.toStringAsFixed(1),
                      unit: 'm',
                    ),
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: colorScheme.outlineVariant.withAlpha(100),
                  ),
                  // 累計時間
                  Expanded(
                    flex: 5,
                    child: _buildMetricItem(
                      context,
                      label: '累計潜水時間',
                      value: statistics.totalBottomTimeFormatted,
                      unit: '',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ブランク状況ステータスチップ
              if (statistics.totalDives > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeColor.withAlpha(80),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        badgeIcon,
                        size: 14,
                        color: badgeColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '最終潜水: ${days ?? 0}日前 (${statistics.statusBadgeLabel})',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: highlight ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
