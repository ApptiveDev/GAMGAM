import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar.dart';
import '../../../data/models/appointment.dart';

/// 참여자 한 줄씩. 방장·나 표시, 조율 중이면 투표 여부도 보여준다.
class ParticipantList extends StatelessWidget {
  const ParticipantList({super.key, required this.appointment, this.meId});

  final Appointment appointment;

  /// 이 브라우저의 게스트. 아직 참여 전이면 null.
  final String? meId;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final showVote = a.isCoordinating && a.template.hasVote;
    return Column(children: [
      for (final p in a.participants)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Avatar(p, size: 32, highlighted: p.id == meId),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: p.name),
                  if (p.id == meId) const TextSpan(text: ' (나)', style: TextStyle(color: AppColors.point)),
                  if (a.isHost(p.id)) const TextSpan(text: '  방장', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
                style: const TextStyle(fontSize: 15, color: AppColors.textTitle),
              ),
            ),
            if (showVote)
              Text(
                a.hasVoted(p.id) ? '투표함' : '아직',
                style: TextStyle(fontSize: 12, color: a.hasVoted(p.id) ? AppColors.textSub : AppColors.textMuted),
              ),
          ]),
        ),
    ]);
  }
}
