import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../dive_spot/interface/views/widgets/spot_map_widget.dart';
import '../../domain/entities/dive_schedule.dart';
import '../controllers/schedule_controller.dart';
import 'widgets/calendar_view.dart';
import 'widgets/schedule_detail_sheet.dart';
import 'widgets/schedule_form_dialog.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> {
  bool _isMapView = false;
  DiveSchedule? _selectedScheduleForMap;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleCalendarProvider);
    final notifier = ref.read(scheduleCalendarProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビング予定'),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.calendar_month : Icons.map_outlined),
            tooltip: _isMapView ? 'カレンダー表示に切替' : 'マップ表示に切替',
            onPressed: () {
              setState(() {
                _isMapView = !_isMapView;
                _selectedScheduleForMap = null;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新',
            onPressed: () => notifier.loadSchedules(),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.schedules.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null && state.schedules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('エラーが発生しました: ${state.error}'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => notifier.loadSchedules(),
                    child: const Text('再読み込み'),
                  ),
                ],
              ),
            );
          }

          if (_isMapView) {
            return _buildMapView(context, state.schedules, notifier);
          }

          final selectedDate = state.selectedDate;
          final schedulesForSelectedDate = state.selectedDateSchedules;
          final weekdayNames = ['月', '火', '水', '木', '金', '土', '日'];
          final weekdayStr = weekdayNames[selectedDate.weekday - 1];

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // カレンダーウィジェット
                CalendarView(
                  focusedMonth: state.focusedMonth,
                  selectedDate: selectedDate,
                  hasSchedule: (date) => state.hasScheduleOn(date),
                  scheduleCount: (date) => state.scheduleCountOn(date),
                  onDateSelected: (date) => notifier.selectDate(date),
                  onPreviousMonth: () => notifier.previousMonth(),
                  onNextMonth: () => notifier.nextMonth(),
                  onToday: () => notifier.goToToday(),
                ),

                const SizedBox(height: 8),

                // 選択日付ヘッダー
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.event_note, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日 ($weekdayStr) の予定',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Badge(
                        label: Text('${schedulesForSelectedDate.length}件'),
                        backgroundColor: schedulesForSelectedDate.isNotEmpty
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ],
                  ),
                ),

                // 選択日付の予定リストまたは空状態
                if (schedulesForSelectedDate.isEmpty)
                  _buildEmptyState(context, selectedDate, notifier)
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: schedulesForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final item = schedulesForSelectedDate[index];
                      return _buildScheduleItemCard(context, item, notifier);
                    },
                  ),

                const SizedBox(height: 24),

                // 今後の予定サマリー
                if (state.schedules.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      '登録されている全予定 (${state.schedules.length}件)',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.schedules.length,
                    itemBuilder: (context, index) {
                      final item = state.schedules[index];
                      return _buildScheduleItemCard(context, item, notifier);
                    },
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScheduleFormDialog.show(
            context,
            initialDate: state.selectedDate,
            onSave: (newSchedule) {
              notifier.addSchedule(newSchedule);
            },
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('予定を追加'),
      ),
    );
  }

  Widget _buildMapView(
    BuildContext context,
    List<DiveSchedule> schedules,
    ScheduleCalendarNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final schedulesWithLocation = schedules
        .where((s) => s.latitude != null && s.longitude != null)
        .toList();

    if (schedulesWithLocation.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                '位置情報が登録された予定がありません',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '予定作成時に「ポイント選択」から指定すると、\n地図上にピンが表示されます。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isMapView = false;
                  });
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('カレンダー表示に戻る'),
              ),
            ],
          ),
        ),
      );
    }

    final mapPoints = schedulesWithLocation.map((sched) {
      return MapPointItem(
        id: sched.id,
        title: sched.destination,
        subtitle: sched.title,
        latitude: sched.latitude!,
        longitude: sched.longitude!,
        pinColor: _selectedScheduleForMap?.id == sched.id
            ? Colors.deepOrange
            : Colors.teal,
        pinIcon: Icons.calendar_today,
        onTap: () {
          setState(() {
            _selectedScheduleForMap = sched;
          });
        },
      );
    }).toList();

    final centerPoint = _selectedScheduleForMap != null
        ? LatLng(_selectedScheduleForMap!.latitude!, _selectedScheduleForMap!.longitude!)
        : LatLng(
            schedulesWithLocation.first.latitude!,
            schedulesWithLocation.first.longitude!,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: SpotMapWidget(
            points: mapPoints,
            initialCenter: centerPoint,
            initialZoom: 9.0,
            onPointSelected: (pointItem) {
              final clicked =
                  schedulesWithLocation.firstWhere((s) => s.id == pointItem.id);
              setState(() {
                _selectedScheduleForMap = clicked;
              });
            },
          ),
        ),
        if (_selectedScheduleForMap != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 84, // FABの上
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedScheduleForMap!.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            setState(() {
                              _selectedScheduleForMap = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '日程: ${_selectedScheduleForMap!.eventDate.year}/${_selectedScheduleForMap!.eventDate.month}/${_selectedScheduleForMap!.eventDate.day} • ポイント: ${_selectedScheduleForMap!.destination}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () {
                            ScheduleDetailSheet.show(
                              context,
                              schedule: _selectedScheduleForMap!,
                              onDelete: () {
                                notifier.deleteSchedule(_selectedScheduleForMap!.id);
                                setState(() {
                                  _selectedScheduleForMap = null;
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('予定詳細'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    DateTime selectedDate,
    ScheduleCalendarNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withAlpha(120),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.beach_access_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              'この日のダイビング予定はありません',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ScheduleFormDialog.show(
                  context,
                  initialDate: selectedDate,
                  onSave: (newSchedule) {
                    notifier.addSchedule(newSchedule);
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('この日に予定を追加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItemCard(
    BuildContext context,
    DiveSchedule item,
    ScheduleCalendarNotifier notifier,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.primary.withAlpha(50)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // タップで詳細ボトムシートを表示
          ScheduleDetailSheet.show(
            context,
            schedule: item,
            onDelete: () {
              notifier.deleteSchedule(item.id);
            },
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.scuba_diving,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 16,
                          color: item.latitude != null
                              ? const Color(0xFF0077B6)
                              : colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.destination,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.storefront, size: 16, color: colorScheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.diveShop,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${item.plannedDivesCount}ダイブ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (item.memo.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'メモ: ${item.memo}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
