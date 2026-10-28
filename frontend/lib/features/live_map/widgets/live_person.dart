import 'package:flutter/material.dart';

import '../../../data/models/live_location.dart';
import 'live_style.dart';
import 'live_text.dart';

/// "5분 후 도착 · 걷는 중". 점 앞은 [size], 뒤는 12.
class LiveStatusLine extends StatelessWidget {
  const LiveStatusLine(this.person, {super.key, this.size = 13});

  final LiveParticipant person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (main, detail) = LiveText.statusParts(person);
    // 좁으면 뒤(이동수단·시각)부터 말줄임.
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Flexible(child: Text(main, maxLines: 1, overflow: TextOverflow.ellipsis, style: liveText(size, FontWeight.w500, LiveColors.textStrong))),
      if (detail != null) ...[
        const SizedBox(width: 3),
        Text('·', style: liveText(size == 13 ? 11 : 12, FontWeight.w700, LiveColors.textStrong)),
        const SizedBox(width: 3),
        Flexible(
          flex: 2,
          child: Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: liveText(12, FontWeight.w400, LiveColors.textStrong)),
        ),
      ],
    ]);
  }
}

/// 사람 옆 버튼. 나(카드) → 편집, 도착 → 등수, 나(목록) → 없음, 쿨다운 중 → 남은 시간, 그 외 → 콕 찌르기.
class LiveAction extends StatelessWidget {
  const LiveAction({
    super.key,
    required this.person,
    required this.isMe,
    required this.rank,
    required this.cooldown,
    required this.onPoke,
    this.showEdit = false,
    this.onEdit,
  });

  final LiveParticipant person;
  final bool isMe;
  final int? rank;
  final Duration cooldown;
  final VoidCallback onPoke;

  /// 마커를 눌러 뜬 내 카드에서만 "편집"을 보여준다.
  final bool showEdit;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    if (isMe && showEdit) {
      return LivePill(label: '편집', background: LiveColors.muted, foreground: LiveColors.textStrong, minWidth: 80, onTap: onEdit);
    }
    if (person.arrived) {
      return LivePill(label: rank == 1 ? '1등 🎉' : '$rank등', background: LiveColors.muted, foreground: LiveColors.textStrong, minWidth: 80);
    }
    if (isMe) return const SizedBox.shrink();
    if (cooldown > Duration.zero) {
      return LivePill(label: '${LiveText.cooldown(cooldown)} 후', background: LiveColors.muted, foreground: LiveColors.onMuted, minWidth: 80);
    }
    return LivePill(label: '콕 찌르기', background: LiveColors.accent, foreground: LiveColors.onAccent, onTap: onPoke);
  }
}
