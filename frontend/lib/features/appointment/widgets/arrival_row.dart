import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/member_avatars.dart';
import '../../../data/models/participant.dart';

/// 약속 확정이후 화면 최종의 도착 현황: 60px 프로필이 가로로 이어지고, 상태 메시지가 있으면 말풍선.
/// 도착한 사람이 앞에 온다.
class ArrivalRow extends StatelessWidget {
  const ArrivalRow({super.key, required this.participants, required this.arrivedIds, required this.messages});

  final List<Participant> participants;
  final Set<String> arrivedIds;
  final Map<String, String> messages;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...participants.where((p) => arrivedIds.contains(p.id)),
      ...participants.where((p) => !arrivedIds.contains(p.id)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(children: [
        for (final (i, p) in ordered.indexed) ...[
          if (i > 0) const SizedBox(width: 19),
          Semantics(
            label: '${p.name}${arrivedIds.contains(p.id) ? ' 도착' : ''}',
            child: Stack(clipBehavior: Clip.none, children: [
              PhotoAvatar(p, size: 60, borderWidth: 1.5),
              if (messages[p.id] case final message?)
                Positioned(left: -3, top: -20, child: _Bubble(message)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 66,
        height: 34,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 66,
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: GamColors.surface,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [BoxShadow(color: Color(0x33212121), blurRadius: 2)],
            ),
            child: Text(
              text,
              style: GamText.meta11.copyWith(fontSize: 8, color: GamColors.text900, height: 1.3),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            left: 26.94,
            top: 27.5,
            child: Transform.flip(flipY: true, child: SvgPicture.asset('assets/figma/bubble_tail.svg', width: 12.124, height: 4.5)),
          ),
        ]),
      );
}
