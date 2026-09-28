import 'package:flutter/material.dart';
import '../../controllers/gear_controller.dart';

/// 機材オーバーホール状態の全体サマリーカード
class GearSummaryCard extends StatelessWidget {
  final GearListState state;

  const GearSummaryCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final overdue = state.overdueCount;
    final warning = state.warningCount;
    final good = state.goodCount;
    final hasAttention = overdue > 0 || warning > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: overdue > 0
            ? BorderSide(color: Colors.red.shade300, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasAttention
                      ? Icons.build_circle_rounded
                      : Icons.verified_user_rounded,
                  color: overdue > 0
                      ? Colors.red.shade700
                      : (warning > 0 ? Colors.orange.shade700 : const Color(0xFF0077B6)),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  '機材メンテナンス・OH状況',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0077B6),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCountChip(
                  label: '要オーバーホール',
                  count: overdue,
                  color: Colors.red.shade700,
                  bgColor: Colors.red.shade50,
                  icon: Icons.error_outline,
                ),
                _buildCountChip(
                  label: 'まもなく推奨',
                  count: warning,
                  color: Colors.orange.shade800,
                  bgColor: Colors.orange.shade50,
                  icon: Icons.access_time,
                ),
                _buildCountChip(
                  label: '状態良好',
                  count: good,
                  color: Colors.green.shade800,
                  bgColor: Colors.green.shade50,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            if (overdue > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade800),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '推奨期限またはダイブ本数を超過している機材があります。ダイビング前の点検・OHをおすすめします。',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.w500,
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

  Widget _buildCountChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(' 件', style: TextStyle(fontSize: 11, color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
