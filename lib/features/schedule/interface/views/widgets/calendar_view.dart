import 'package:flutter/material.dart';

/// カレンダーグリッドおよび月送りヘッダーを表示するウィジェット
class CalendarView extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final bool Function(DateTime date) hasSchedule;
  final int Function(DateTime date) scheduleCount;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;

  const CalendarView({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.hasSchedule,
    required this.scheduleCount,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildHeader(context, colorScheme),
            const SizedBox(height: 8),
            _buildWeekdayHeader(theme),
            const SizedBox(height: 4),
            _buildDaysGrid(context, colorScheme),
          ],
        ),
      ),
    );
  }

  /// 月移動と「今日」ボタンを含むヘッダー
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前月',
          onPressed: onPreviousMonth,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${focusedMonth.year}年 ${focusedMonth.month}月',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '次月',
          onPressed: onNextMonth,
        ),
        TextButton.icon(
          onPressed: onToday,
          icon: const Icon(Icons.today, size: 16),
          label: const Text('今日'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        ),
      ],
    );
  }

  /// 曜日行（日〜土）
  Widget _buildWeekdayHeader(ThemeData theme) {
    const weekdays = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      children: List.generate(7, (index) {
        Color textColor = theme.colorScheme.onSurfaceVariant;
        if (index == 0) {
          textColor = Colors.redAccent;
        } else if (index == 6) {
          textColor = Colors.blueAccent;
        }
        return Expanded(
          child: Center(
            child: Text(
              weekdays[index],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// カレンダーの日付セルグリッド
  Widget _buildDaysGrid(BuildContext context, ColorScheme colorScheme) {
    final year = focusedMonth.year;
    final month = focusedMonth.month;

    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final previousMonthDays = DateTime(year, month, 0).day;

    // 日曜始まり (Dart weekday: 月=1, ..., 日=7)
    // 日曜なら0、月曜なら1、... 土曜なら6
    final startWeekdayOffset = firstDayOfMonth.weekday % 7;

    // 表示するマスの総数（5行=35 または 6行=42）
    final totalCells = ((startWeekdayOffset + daysInMonth) > 35) ? 42 : 35;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final List<Widget> dayWidgets = [];

    for (int i = 0; i < totalCells; i++) {
      DateTime cellDate;
      bool isCurrentMonth = true;

      if (i < startWeekdayOffset) {
        // 前月
        final prevDay = previousMonthDays - (startWeekdayOffset - i - 1);
        cellDate = DateTime(year, month - 1, prevDay);
        isCurrentMonth = false;
      } else if (i < startWeekdayOffset + daysInMonth) {
        // 当月
        final day = i - startWeekdayOffset + 1;
        cellDate = DateTime(year, month, day);
      } else {
        // 翌月
        final nextDay = i - (startWeekdayOffset + daysInMonth) + 1;
        cellDate = DateTime(year, month + 1, nextDay);
        isCurrentMonth = false;
      }

      final isSelected = cellDate.year == selectedDate.year &&
          cellDate.month == selectedDate.month &&
          cellDate.day == selectedDate.day;

      final isToday = cellDate.year == today.year &&
          cellDate.month == today.month &&
          cellDate.day == today.day;

      final hasEvents = hasSchedule(cellDate);
      final count = scheduleCount(cellDate);

      dayWidgets.add(
        _buildDayCell(
          date: cellDate,
          isCurrentMonth: isCurrentMonth,
          isSelected: isSelected,
          isToday: isToday,
          hasEvents: hasEvents,
          eventCount: count,
          colorScheme: colorScheme,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 2,
      children: dayWidgets,
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool isToday,
    required bool hasEvents,
    required int eventCount,
    required ColorScheme colorScheme,
  }) {
    // 曜日に応じた基本テキストカラー
    Color textColor;
    if (!isCurrentMonth) {
      textColor = colorScheme.outline.withAlpha(80);
    } else if (date.weekday == DateTime.sunday) {
      textColor = Colors.redAccent.shade700;
    } else if (date.weekday == DateTime.saturday) {
      textColor = Colors.blueAccent.shade700;
    } else {
      textColor = colorScheme.onSurface;
    }

    if (isSelected) {
      textColor = colorScheme.onPrimary;
    }

    return InkWell(
      onTap: () => onDateSelected(date),
      borderRadius: BorderRadius.circular(20),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? colorScheme.primary
                : (isToday
                    ? colorScheme.primaryContainer.withAlpha(120)
                    : Colors.transparent),
            border: (isToday && !isSelected)
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isSelected || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: textColor,
                ),
              ),
              if (hasEvents)
                Positioned(
                  bottom: 3,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : Colors.orangeAccent.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
