import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../data/models/participant.dart';
import '../../../data/models/vote_option.dart';

/// 시간 후보 한 줄: 날짜·시간 + 투표자 + [투표]/[투표함]
class TimeVoteTile extends StatelessWidget {
  const TimeVoteTile({super.key, required this.option, required this.voters, required this.voted, required this.onTap});

  final TimeOption option;
  final List<Participant> voters;
  final bool voted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: voted ? AppColors.pointSoft : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: voted ? AppColors.point : AppColors.border, width: voted ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(DateText.dateTime(option.value), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
              const SizedBox(height: 8),
              Row(children: [
                AvatarStack(voters, size: 20, max: 4),
                if (voters.isNotEmpty) const SizedBox(width: 6),
                Text('${option.voteCount}표', style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
              ]),
            ]),
          ),
          SizedBox(
            width: 72,
            height: 38,
            child: voted
                ? FilledButton(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                    child: const Text('투표함', style: TextStyle(fontSize: 13)),
                  )
                : OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
                    child: const Text('투표', style: TextStyle(fontSize: 13)),
                  ),
          ),
        ]),
      );
}
