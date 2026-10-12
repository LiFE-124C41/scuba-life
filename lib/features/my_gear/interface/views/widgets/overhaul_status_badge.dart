import 'package:flutter/material.dart';
import '../../../domain/entities/gear_item.dart';

/// オーバーホールステータスを表示するバッジウィジェット
class OverhaulStatusBadge extends StatelessWidget {
  final GearItem gear;
  final bool showDetailText;

  const OverhaulStatusBadge({
    super.key,
    required this.gear,
    this.showDetailText = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = gear.calculateStatus();
    final days = gear.calculateDaysUntilOverhaul();
    final dives = gear.calculateDivesUntilOverhaul();

    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    switch (status) {
      case OverhaulStatus.overdue:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.warning_amber_rounded;
        text = '要オーバーホール';
        break;
      case OverhaulStatus.warning:
        bgColor = Colors.amber.shade100;
        textColor = Colors.brown.shade800;
        icon = Icons.access_time_rounded;
        text = 'まもなく推奨時期';
        break;
      case OverhaulStatus.good:
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle_outline_rounded;
        text = '状態良好';
        break;
      case OverhaulStatus.none:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
        icon = Icons.remove_circle_outline_rounded;
        text = 'OH対象外';
        break;
    }

    String detailSuffix = '';
    if (showDetailText && gear.requiresOverhaul) {
      if (status == OverhaulStatus.overdue) {
        final overdueDays = -days;
        if (overdueDays > 0) {
          detailSuffix = ' ($overdueDays日超過)';
        } else if (dives != null && dives <= 0) {
          detailSuffix = ' (${-dives}本超過)';
        }
      } else if (status == OverhaulStatus.warning) {
        detailSuffix = ' (あと$days日)';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            '$text$detailSuffix',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
