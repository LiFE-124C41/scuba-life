import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../logbook/domain/entities/dive_log.dart';
import '../../../../logbook/interface/controllers/dive_log_controller.dart';
import '../../../../logbook/interface/views/dive_log_detail_page.dart';
import '../../../../logbook/interface/views/dive_log_form_page.dart';
import '../../../../my_gear/domain/entities/gear_item.dart';
import '../../../../my_gear/interface/controllers/gear_controller.dart';
import '../../../domain/entities/dive_schedule.dart';
import '../../controllers/schedule_controller.dart';
import '../schedule_gear_selection_page.dart';
import 'package:latlong2/latlong.dart';
import '../../../../dive_spot/interface/views/widgets/spot_map_widget.dart';
import '../../../../weather/domain/entities/marine_weather.dart';
import '../../../../weather/interface/controllers/weather_controller.dart';

/// 予定の詳細情報を表示するボトムシート
class ScheduleDetailSheet extends ConsumerWidget {
  final DiveSchedule schedule;
  final VoidCallback onDelete;

  const ScheduleDetailSheet({
    super.key,
    required this.schedule,
    required this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required DiveSchedule schedule,
    required VoidCallback onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleDetailSheet(
        schedule: schedule,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final calendarState = ref.watch(scheduleCalendarProvider);
    final currentSchedule =
        calendarState.schedules.where((s) => s.id == schedule.id).firstOrNull ?? schedule;
    final date = currentSchedule.eventDate;
    final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
    final weekdayStr = weekdayNames[date.weekday - 1];

    final logsAsync = ref.watch(diveLogListProvider);
    final linkedLogs = logsAsync.maybeWhen(
      data: (logs) => logs.where((l) => l.scheduleId == currentSchedule.id).toList(),
      orElse: () => <DiveLog>[],
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ドラッグハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // タイトル & アクション
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    schedule.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: '予定を削除',
                  onPressed: () {
                    _showDeleteConfirmDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基本情報カード
            Card(
              color: colorScheme.surfaceContainerHighest.withAlpha(120),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.calendar_month,
                      label: '日程',
                      value: '${date.year}年${date.month}月${date.day}日 ($weekdayStr)',
                      color: colorScheme.primary,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.place,
                      label: '目的地 / ポイント',
                      value: schedule.destination,
                      color: Colors.teal,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.storefront,
                      label: '利用ダイブショップ',
                      value: schedule.diveShop,
                      color: Colors.indigo,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      icon: Icons.scuba_diving,
                      label: '予定ダイビング数',
                      value: '${schedule.plannedDivesCount} ダイブ',
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ),

            if (schedule.latitude != null && schedule.longitude != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.map, size: 18, color: Color(0xFF0077B6)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ダイビングポイント位置',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${schedule.latitude!.toStringAsFixed(4)}, ${schedule.longitude!.toStringAsFixed(4)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 160,
                      child: SpotMapWidget(
                        points: [
                          MapPointItem(
                            id: schedule.id,
                            title: schedule.destination,
                            latitude: schedule.latitude!,
                            longitude: schedule.longitude!,
                            pinColor: Colors.teal,
                            pinIcon: Icons.calendar_today,
                          ),
                        ],
                        initialCenter: LatLng(schedule.latitude!, schedule.longitude!),
                        initialZoom: 12.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            _buildWeatherSection(context, ref),

            const SizedBox(height: 16),
            _buildGearChecklistSection(context, ref, currentSchedule),

            if (schedule.memo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'メモ・準備事項',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  schedule.memo,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 連携機能: この予定に紐付くダイビングログセクション
            Row(
              children: [
                Icon(Icons.book, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '記録済みダイビングログ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  label: Text('${linkedLogs.length}件'),
                  backgroundColor: linkedLogs.isNotEmpty
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (linkedLogs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(100)),
                ),
                child: Column(
                  children: [
                    Text(
                      'この予定に紐付くログはまだ記録されていません',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      icon: const Icon(Icons.edit_note, size: 20),
                      label: const Text('この予定からログを記録する'),
                      onPressed: () {
                        Navigator.of(context).pop(); // シートを閉じる
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DiveLogFormPage(initialSchedule: schedule),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  ...linkedLogs.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final log = entry.value;
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colorScheme.primary.withAlpha(60)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Text(
                            '#$index',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          log.location,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '水深: ${log.maxDepthMeter}m / 時間: ${log.bottomTimeMinutes}分 / 評価: ★${log.rating}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pop(); // シートを閉じる
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => DiveLogDetailPage(logId: log.id),
                            ),
                          );
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('さらにこの予定のログを追加'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DiveLogFormPage(initialSchedule: schedule),
                        ),
                      );
                    },
                  ),
                ],
              ),

            const SizedBox(height: 20),

            // 閉じるボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(width: 12),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherSection(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 緯度経度が未登録の場合の表示
    if (schedule.latitude == null || schedule.longitude == null) {
      return Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: Colors.grey, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ダイビングポイントの緯度・経度が設定されていないため、海況予報を取得できません。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final weatherAsync = ref.watch(scheduleMarineWeatherProvider(schedule));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.waves, size: 20, color: Color(0xFF0077B6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '予定日の海況・気象予報',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '海況予報を再取得',
                  onPressed: () {
                    ref.invalidate(scheduleMarineWeatherProvider(schedule));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            weatherAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Open-Meteo から海況データを取得中...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '海況データの取得に失敗しました。通信環境をご確認ください。',
                        style: TextStyle(fontSize: 12, color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
              data: (weather) {
                if (weather == null) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '海況予報は予定日の約7日前から取得できます。\n（指定された日程は予報期間外です）',
                            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final condColor = _getConditionColor(weather.conditionLevel);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // コンディション判定ヘッダー
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: condColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: condColor.withAlpha(120)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, size: 18, color: condColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '潜水コンディション: ${weather.conditionLevel.label}',
                              style: TextStyle(
                                color: condColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${weather.forecastTime.month}月${weather.forecastTime.day}日 予報',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 各種指標グリッド
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisExtent: 68,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      children: [
                        _buildWeatherGridItem(
                          label: '天気 / 気温',
                          value: '${weather.weatherDescription}\n${weather.airTemperatureCelsius.toStringAsFixed(1)}℃',
                          icon: Icons.wb_sunny_outlined,
                          iconColor: Colors.orange,
                        ),
                        _buildWeatherGridItem(
                          label: '予想水温',
                          value: '${weather.waterTemperatureCelsius.toStringAsFixed(1)}℃',
                          icon: Icons.water_outlined,
                          iconColor: Colors.blue,
                        ),
                        _buildWeatherGridItem(
                          label: '波高',
                          value: '${weather.waveHeightMeter.toStringAsFixed(1)} m',
                          icon: Icons.waves,
                          iconColor: Colors.teal,
                        ),
                        _buildWeatherGridItem(
                          label: '風向・風速',
                          value: '${weather.windDirection}\n${weather.windSpeedMeterPerSec.toStringAsFixed(1)} m/s',
                          icon: Icons.air,
                          iconColor: Colors.blueGrey,
                        ),
                        _buildWeatherGridItem(
                          label: '予想透明度',
                          value: '約${weather.estimatedVisibilityMeter.toInt()} m',
                          icon: Icons.visibility_outlined,
                          iconColor: Colors.cyan,
                        ),
                        _buildWeatherGridItem(
                          label: '潮回り',
                          value: weather.tideType.label,
                          icon: Icons.nights_stay_outlined,
                          iconColor: Colors.deepPurple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '提供: Open-Meteo Marine API',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant.withAlpha(150),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherGridItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: iconColor.withAlpha(15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(DivingConditionLevel level) {
    switch (level) {
      case DivingConditionLevel.good:
        return const Color(0xFF2E7D32);
      case DivingConditionLevel.caution:
        return const Color(0xFFEF6C00);
      case DivingConditionLevel.closed:
        return const Color(0xFFC62828);
    }
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('予定の削除'),
        content: Text('「${schedule.title}」の予定を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop(); // ダイアログ閉じる
              Navigator.of(context).pop(); // シート閉じる
              onDelete();
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  /// 持ち物・機材チェックリストセクション
  Widget _buildGearChecklistSection(
    BuildContext context,
    WidgetRef ref,
    DiveSchedule currentSchedule,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gearState = ref.watch(gearListNotifierProvider);
    final allRegisteredGears = gearState.allItems;

    // 今回の予定の持参対象機材のみを抽出
    final gears = allRegisteredGears.where((g) => currentSchedule.isGearTarget(g.id)).toList();

    final totalCount = gears.length;
    final checkedCount = gears.where((g) => currentSchedule.isGearChecked(g.id)).length;
    final isAllChecked = totalCount > 0 && checkedCount == totalCount;
    final progress = totalCount > 0 ? (checkedCount / totalCount) : 0.0;
    final isFiltered = currentSchedule.targetGearIds != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー行 (GEMINI.mdルール準拠: Wrapで横溢れを防止)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.checklist_rtl, size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '持ち物・機材チェックリスト',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (totalCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isAllChecked
                              ? Colors.green.withAlpha(30)
                              : colorScheme.primaryContainer.withAlpha(50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isAllChecked
                                ? Colors.green
                                : colorScheme.primary.withAlpha(100),
                          ),
                        ),
                        child: Text(
                          isAllChecked ? '準備完了!' : '$checkedCount / $totalCount 完了',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAllChecked ? Colors.green.shade700 : colorScheme.primary,
                          ),
                        ),
                      ),
                    if (totalCount > 0)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          final targetIds = gears.map((g) => g.id).toList();
                          ref
                              .read(scheduleCalendarProvider.notifier)
                              .toggleAllGearCheck(currentSchedule.id, targetIds, !isAllChecked);
                        },
                        child: Text(
                          isAllChecked ? '全解除' : '全選択',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    if (allRegisteredGears.isNotEmpty)
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: isFiltered ? colorScheme.primary : colorScheme.outline,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ScheduleGearSelectionPage(schedule: currentSchedule),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.tune,
                          size: 14,
                          color: isFiltered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        ),
                        label: Text(
                          isFiltered ? '機材変更中' : '機材を選択',
                          style: TextStyle(
                            fontSize: 12,
                            color: isFiltered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            if (totalCount > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAllChecked ? Colors.green : colorScheme.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              // 機材一覧リスト
              ...gears.map((gear) {
                final isChecked = currentSchedule.isGearChecked(gear.id);
                return InkWell(
                  onTap: () {
                    ref
                        .read(scheduleCalendarProvider.notifier)
                        .toggleGearCheck(currentSchedule.id, gear.id);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            value: isChecked,
                            onChanged: (_) {
                              ref
                                  .read(scheduleCalendarProvider.notifier)
                                  .toggleGearCheck(currentSchedule.id, gear.id);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          _getCategoryIcon(gear.category),
                          size: 18,
                          color: isChecked ? Colors.grey : colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gear.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                  color: isChecked ? Colors.grey : null,
                                  fontWeight: isChecked ? FontWeight.normal : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (gear.brand.isNotEmpty || gear.model.isNotEmpty)
                                Text(
                                  [gear.brand, gear.model].where((s) => s.isNotEmpty).join(' / '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else if (allRegisteredGears.isNotEmpty) ...[
              // 全機材はあるが、持参機材が0件に設定されている場合
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 18, color: colorScheme.outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '今回持参する機材が未選択です。',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '「機材を選択」から、今回のトリップに持参する機材を選んでください。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ScheduleGearSelectionPage(schedule: currentSchedule),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune, size: 16),
                      label: const Text('持参機材を選択する'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: colorScheme.outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '機材管理でマイ機材を登録すると、ここに自動で持ち物チェックリストとして表示されます。',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GearCategory category) {
    switch (category) {
      case GearCategory.regulator:
        return Icons.water;
      case GearCategory.bcd:
        return Icons.shield;
      case GearCategory.diveComputer:
        return Icons.watch;
      case GearCategory.suit:
        return Icons.accessibility_new;
      case GearCategory.maskSnorkelFin:
        return Icons.visibility;
      case GearCategory.accessories:
        return Icons.inventory_2_outlined;
    }
  }
}

