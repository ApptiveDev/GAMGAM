import 'package:flutter/material.dart';

import '../../data/models/participant.dart';
import '../theme/app_colors.dart';
import 'dashed_border.dart';

/// 프로필 원. 프로필 사진이 생기기 전까지 이름 첫 글자를 보여준다.
class Avatar extends StatelessWidget {
  const Avatar(this.participant, {super.key, this.size = 28, this.highlighted = false, this.dashed = false});

  final Participant participant;
  final double size;
  final bool highlighted;

  /// 앱 미설치 등 "아직 아닌" 상태.
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      participant.initial,
      style: TextStyle(fontSize: size * 0.4, color: dashed ? AppColors.textMuted : AppColors.textBody, fontWeight: FontWeight.w500),
    );
    if (dashed) {
      return DashedBorder(radius: size / 2, child: SizedBox.square(dimension: size, child: Center(child: label)));
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatar,
        border: Border.all(color: highlighted ? AppColors.point : Colors.white, width: 2),
      ),
      child: label,
    );
  }
}

/// 겹쳐서 보여주는 아바타 줄. 넘치면 "+N".
class AvatarStack extends StatelessWidget {
  const AvatarStack(this.participants, {super.key, this.size = 28, this.max = 3, this.dashedIds = const {}});

  final List<Participant> participants;
  final double size;
  final int max;
  final Set<String> dashedIds;

  @override
  Widget build(BuildContext context) {
    final shown = participants.take(max).toList();
    final rest = participants.length - shown.length;
    final step = size * 0.68;
    final count = shown.length + (rest > 0 ? 1 : 0);

    return SizedBox(
      width: count == 0 ? 0 : step * (count - 1) + size,
      height: size,
      child: Stack(children: [
        for (final (i, p) in shown.indexed) Positioned(left: step * i, child: Avatar(p, size: size, dashed: dashedIds.contains(p.id))),
        if (rest > 0)
          Positioned(
            left: step * shown.length,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: Colors.white, width: 2)),
              child: Text('+$rest', style: TextStyle(fontSize: size * 0.38, color: AppColors.textSub)),
            ),
          ),
      ]),
    );
  }
}
