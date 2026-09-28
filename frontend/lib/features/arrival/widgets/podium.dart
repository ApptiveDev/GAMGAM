import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../data/models/live_location.dart';

/// 도착 순위 시상대. 가운데 1등, 왼쪽 2등, 오른쪽 3등.
class Podium extends StatelessWidget {
  const Podium({super.key, required this.top});

  /// 도착 순서대로 최대 3명.
  final List<LiveParticipant> top;

  @override
  Widget build(BuildContext context) {
    final places = [
      if (top.length > 1) (top[1], 2),
      if (top.isNotEmpty) (top[0], 1),
      if (top.length > 2) (top[2], 3),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, (p, rank)) in places.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          _Step(person: p, rank: rank),
        ],
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.person, required this.rank});

  final LiveParticipant person;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final first = rank == 1;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Avatar(person.participant, size: first ? 60 : 50, highlighted: first),
      const SizedBox(height: 8),
      Container(
        width: first ? 86 : 78,
        height: switch (rank) { 1 => 100.0, 2 => 70.0, _ => 54.0 },
        decoration: BoxDecoration(
          color: first ? AppColors.point : AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('$rank', style: TextStyle(fontSize: first ? 26 : 20, fontWeight: FontWeight.w700, color: first ? Colors.white : AppColors.textSub)),
          const SizedBox(height: 2),
          Text(
            DateText.time(person.arrivedAt!),
            style: TextStyle(fontSize: 10, color: first ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted),
          ),
        ]),
      ),
    ]);
  }
}
