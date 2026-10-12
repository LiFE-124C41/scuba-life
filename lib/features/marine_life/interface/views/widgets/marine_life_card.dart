import 'package:flutter/material.dart';
import 'package:scuba_life/features/marine_life/domain/entities/marine_life_summary.dart';
import 'marine_life_detail_sheet.dart';

/// 生き物図鑑の一覧カードウィジェット
class MarineLifeCard extends StatelessWidget {
  final MarineLifeSummary summary;

  const MarineLifeCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0.8,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => MarineLifeDetailSheet.show(context, summary),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー: 生物名 & 遭遇回数バッジ
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primaryContainer.withAlpha(200),
                    child: Icon(
                      Icons.set_meal,
                      size: 22,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      summary.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 14,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${summary.encounterCount}回遭遇',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 出会った月（横並びチップ）
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '遭遇月:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: summary.months.map((m) {
                          return Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$m月',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 出会った場所（横並びチップ）
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Icon(
                      Icons.place_outlined,
                      size: 15,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      '場所:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: summary.locations.take(3).map((loc) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.withAlpha(25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            loc,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      }).toList()
                        ..addAll(
                          summary.locations.length > 3
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '+${summary.locations.length - 3}ヶ所',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ]
                              : [],
                        ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // フッター: 直近遭遇日 & タップ誘導
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (summary.lastEncounterDate != null)
                    Text(
                      '直近: ${summary.lastEncounterDate!.year}/${summary.lastEncounterDate!.month.toString().padLeft(2, '0')}/${summary.lastEncounterDate!.day.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      Text(
                        '遭遇ログを見る',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
