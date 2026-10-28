import 'package:flutter/material.dart';

import '../../../data/models/participant.dart';
import '../../theme/gam_colors.dart';
import '../../theme/gam_text.dart';

/// 프로필 사진 원. 사진이 없으면 이름 첫 글자.
class PhotoAvatar extends StatelessWidget {
  const PhotoAvatar(this.participant, {super.key, this.size = 24, this.borderWidth = 0.7});

  final Participant participant;
  final double size;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    final image = participant.avatarAsset;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: GamColors.surface,
        border: Border.all(color: GamColors.text800, width: borderWidth),
      ),
      alignment: Alignment.center,
      child: image != null
          ? Image.asset(image, fit: BoxFit.cover, width: size, height: size)
          : Text(participant.initial, style: GamText.meta11.copyWith(fontSize: size * 0.42, color: GamColors.text800)),
    );
  }
}

/// 겹친 프로필 4개 + 검은 "3+". Figma에서 간격은 -5.4.
class MemberAvatars extends StatelessWidget {
  const MemberAvatars(this.participants, {super.key, this.max = 4});

  final List<Participant> participants;
  final int max;

  static const _size = 24.0;
  static const _step = _size - 5.429;

  @override
  Widget build(BuildContext context) {
    final shown = participants.take(max).toList();
    final rest = participants.length - shown.length;
    final count = shown.length + (rest > 0 ? 1 : 0);
    return SizedBox(
      width: count == 0 ? 0 : _step * (count - 1) + _size,
      height: _size,
      child: Stack(children: [
        for (final (i, p) in shown.indexed) Positioned(left: _step * i, child: PhotoAvatar(p)),
        if (rest > 0)
          Positioned(
            left: _step * shown.length,
            child: Container(
              width: _size,
              height: _size,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: GamColors.text900, shape: BoxShape.circle),
              child: Text('$rest+', style: GamText.meta11.copyWith(color: Colors.white, letterSpacing: -0.5)),
            ),
          ),
      ]),
    );
  }
}

/// "활동 중 · 4명 참여" 처럼 달력 아이콘 옆 작은 상태 줄.
class MetaLine extends StatelessWidget {
  const MetaLine({super.key, required this.leading, required this.parts});

  final Widget leading;
  final List<String> parts;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          leading,
          const SizedBox(width: 6),
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Text('·', style: GamText.dot11)),
            Text(part, style: GamText.meta11),
          ],
        ]),
      );
}
