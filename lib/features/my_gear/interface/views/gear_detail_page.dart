import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/gear_item.dart';
import '../controllers/gear_controller.dart';
import 'gear_form_page.dart';
import 'widgets/overhaul_status_badge.dart';

/// 機材詳細閲覧画面
class GearDetailPage extends ConsumerStatefulWidget {
  final String gearId;

  const GearDetailPage({super.key, required this.gearId});

  @override
  ConsumerState<GearDetailPage> createState() => _GearDetailPageState();
}

class _GearDetailPageState extends ConsumerState<GearDetailPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gearListNotifierProvider);
    final gear = state.allItems.where((g) => g.id == widget.gearId).firstOrNull;

    if (gear == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('機材詳細')),
        body: const Center(child: Text('該当する機材情報が見つかりません。')),
      );
    }

    final days = gear.calculateDaysUntilOverhaul();
    final dives = gear.calculateDivesUntilOverhaul();
    final status = gear.calculateStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text(gear.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '編集',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GearFormPage(initialGear: gear),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '削除',
            onPressed: () => _confirmDelete(gear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダーカード
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(
                            _getCategoryIcon(gear.category),
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gear.category.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                gear.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (gear.brand.isNotEmpty || gear.model.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [gear.brand, gear.model].where((s) => s.isNotEmpty).join(' / '),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'メンテナンス状態:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        OverhaulStatusBadge(gear: gear, showDetailText: true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // オーバーホール情報セクション（OH対象機材のみ）
            if (gear.requiresOverhaul) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.build_circle, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              const Text(
                                'オーバーホール目安・状況',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => _showRecordOverhaulDialog(gear),
                            icon: const Icon(Icons.check, size: 18),
                            label: const Text('OH完了を記録'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        '次回推奨時期',
                        '${gear.nextOverhaulDate.year}年${gear.nextOverhaulDate.month}月${gear.nextOverhaulDate.day}日',
                        highlight: status == OverhaulStatus.overdue,
                      ),
                      _buildDetailRow(
                        '残り日数目安',
                        days <= 0 ? '${-days}日超過' : 'あと $days 日',
                        highlight: days <= 0,
                      ),
                      if (gear.overhaulIntervalDives != null) ...[
                        _buildDetailRow(
                          'OH後ダイブ本数',
                          '${gear.divesSinceOverhaul} / ${gear.overhaulIntervalDives}本',
                          highlight: dives != null && dives <= 0,
                        ),
                        if (dives != null)
                          _buildDetailRow(
                            '残りダイブ本数目安',
                            dives <= 0 ? '${-dives}本超過' : 'あと $dives 本',
                            highlight: dives <= 0,
                          ),
                      ],
                      _buildDetailRow(
                        '最終オーバーホール日',
                        gear.lastOverhaulDate != null
                            ? '${gear.lastOverhaulDate!.year}年${gear.lastOverhaulDate!.month}月${gear.lastOverhaulDate!.day}日'
                            : '未実施（購入日を基準に計算）',
                      ),
                      _buildDetailRow(
                        '推奨サイクル',
                        '${gear.overhaulIntervalMonths}ヶ月ごと'
                            '${gear.overhaulIntervalDives != null ? " または ${gear.overhaulIntervalDives}本ごと" : ""}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 機材スペック・購入情報カード
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '基本情報・購入情報',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      '購入日',
                      '${gear.purchaseDate.year}年${gear.purchaseDate.month}月${gear.purchaseDate.day}日',
                    ),
                    if (gear.serialNumber.isNotEmpty)
                      _buildDetailRow('シリアル番号', gear.serialNumber),
                    _buildDetailRow('OH対象設定', gear.requiresOverhaul ? '定期OH対象' : 'OH対象外'),
                  ],
                ),
              ),
            ),

            if (gear.memo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'メンテナンス履歴・メモ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        gear.memo,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? Colors.red.shade700 : Colors.black87,
            ),
          ),
        ],
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
        return Icons.flash_on;
    }
  }

  Future<void> _showRecordOverhaulDialog(GearItem gear) async {
    DateTime selectedDate = DateTime.now();
    final noteController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('オーバーホール完了を記録'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '実施日を記録すると、OH後ダイブ本数は0本にリセットされ、次回目安日が再計算されます。',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('実施日', style: TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: '作業内容・ショップ・交換パーツ等メモ（任意）',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('キャンセル'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogCtx, true),
                child: const Text('記録を保存'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true && mounted) {
      await ref.read(gearListNotifierProvider.notifier).recordOverhaul(
            gearId: gear.id,
            overhaulDate: selectedDate,
            memo: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('オーバーホール完了を記録しました')),
        );
      }
    }
  }

  Future<void> _confirmDelete(GearItem gear) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('機材の削除'),
        content: Text('「${gear.name}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(gearListNotifierProvider.notifier).deleteGear(gear.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('機材を削除しました')),
        );
      }
    }
  }
}
