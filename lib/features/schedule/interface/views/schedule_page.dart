import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/schedule_controller.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(diveScheduleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ダイビングスケジュール'),
      ),
      body: schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Center(child: Text('予定されているダイビングはありません'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              final item = schedules[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.calendar_month),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('日程: ${item.eventDate.year}/${item.eventDate.month}/${item.eventDate.day}'),
                      Text('場所: ${item.destination} (${item.diveShop})'),
                      Text('予定本数: ${item.plannedDivesCount}本'),
                      if (item.memo.isNotEmpty) Text('メモ: ${item.memo}'),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
