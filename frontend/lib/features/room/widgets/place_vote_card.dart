import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tags.dart';
import '../../../data/models/vote_option.dart';

/// 장소 후보 카드. 탭하면 이 장소에 투표(한 곳만). 1위는 포인트 컬러 막대.
class PlaceVoteCard extends StatelessWidget {
  const PlaceVoteCard({super.key, required this.option, required this.total, required this.leading, required this.voted, required this.onTap});

  final PlaceOption option;
  final int total;
  final bool leading;
  final bool voted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final place = option.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: voted ? AppColors.pointSoft : AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: voted ? AppColors.point : AppColors.border, width: voted ? 1.5 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                const ImagePlaceholder(size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle)),
                    if (place.description.isNotEmpty) Text(place.description, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                  ]),
                ),
                Text(
                  '${option.voteCount}표',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: leading ? AppColors.point : AppColors.textSub),
                ),
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : option.voteCount / total,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceStrong,
                  color: leading ? AppColors.point : AppColors.borderStrong,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
