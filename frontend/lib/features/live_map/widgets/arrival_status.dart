import 'package:flutter/material.dart';

import '../../../core/utils/date_text.dart';
import '../../../data/models/live_location.dart';
import '../../appointment/widgets/arrival_row.dart';
import 'live_person.dart';
import 'live_style.dart';

/// 도착 현황: 약속까지 남은 시간 → 전체 프로필 줄 → 사람별 상태와 콕 찌르기.
/// 당일 지도 하단 시트 안에 들어가고, 지도 없이 단독 화면으로도 쓸 수 있다.
class ArrivalStatusPanel extends StatelessWidget {
  const ArrivalStatusPanel({
    super.key,
    required this.session,
    required this.meId,
    required this.cooldownOf,
    required this.onPoke,
    required this.onShowResult,
    this.statusMessages = const {},
    this.full = false,
  });

  final LiveSession session;
  final String meId;
  final Duration Function(String participantId) cooldownOf;
  final ValueChanged<LiveParticipant> onPoke;
  final VoidCallback onShowResult;

  /// 참여자 id → 상태 메시지. 프로필 줄 위 말풍선으로 보인다.
  final Map<String, String> statusMessages;

  /// 시트를 끝까지 올린 전체 화면(767:21626). 머리글은 도착 인원을 강조하고, 공유 꺼짐 덮개가 밝다.
  final bool full;

  @override
  Widget build(BuildContext context) {
    final rows = _sorted(session.participants);
    final ranks = {for (final (i, p) in session.arrivalOrder.indexed) p.id: i + 1};
    final arrivedIds = {for (final p in session.arrivalOrder) p.id};
    final strong = liveText(13, FontWeight.w600, LiveColors.textStrong);
    final faint = liveText(12, FontWeight.w500, LiveColors.textFaint);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Countdown(session: session),
      if (session.allArrived) ...[
        const SizedBox(height: 20),
        LivePill(label: '다 모였어요! 결과 보기', background: LiveColors.accent, foreground: LiveColors.onAccent, onTap: onShowResult),
      ],
      const SizedBox(height: 40),
      Row(children: [
        Text('총 ${session.participants.length}명', style: full ? faint : strong),
        const SizedBox(width: 8),
        Text('${arrivedIds.length}명 도착', style: full ? strong : faint),
      ]),
      // 말풍선이 프로필 위로 20만큼 올라온다.
      const SizedBox(height: 40),
      ArrivalRow(participants: [for (final p in session.participants) p.participant], arrivedIds: arrivedIds, messages: statusMessages),
      const SizedBox(height: 40),
      // 행 사이 간격만 20. 첫 행 위·마지막 행 아래는 띄우지 않는다.
      for (final (i, p) in rows.indexed)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 10, bottom: i == rows.length - 1 ? 0 : 10),
          child: _PersonRow(
            person: p,
            isMe: p.id == meId,
            rank: ranks[p.id],
            cooldown: cooldownOf(p.id),
            onPoke: () => onPoke(p),
            offOverlay: full ? LiveColors.sharingOffOverlayLight : LiveColors.sharingOffOverlay,
          ),
        ),
    ]);
  }

  /// 도착한 순서 → 곧 올 사람 → 공유 꺼짐.
  static List<LiveParticipant> _sorted(List<LiveParticipant> people) {
    int group(LiveParticipant p) => switch (p.status) {
          LiveStatus.arrived => 0,
          LiveStatus.moving || LiveStatus.notDeparted => 1,
          LiveStatus.sharingOff => 2,
        };
    return [...people]..sort((a, b) {
        final g = group(a).compareTo(group(b));
        if (g != 0) return g;
        if (a.arrived) return a.arrivedAt!.compareTo(b.arrivedAt!);
        return (a.etaMinutes ?? 0).compareTo(b.etaMinutes ?? 0);
      });
  }
}

/// "약속까지 / 8:88:88 오전 2:03 / 2명이 아직 출발하지 않았어요."
class _Countdown extends StatelessWidget {
  const _Countdown({required this.session});

  final LiveSession session;

  @override
  Widget build(BuildContext context) {
    final late = session.remaining.isNegative;
    final notDeparted = session.participants.where((p) => p.status == LiveStatus.notDeparted).length;
    final summary = session.allArrived
        ? '모두 도착했어요.'
        : notDeparted > 0
            ? '$notDeparted명이 아직 출발하지 않았어요.'
            : '모두 출발했어요.';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(late ? '약속 시간이 지났어요' : '약속까지', style: liveText(14, FontWeight.w600, LiveColors.textStrong)),
      const SizedBox(height: 7),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        DotTimer(DateText.countdown(late ? -session.remaining : session.remaining)),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(DateText.time(session.appointmentTime), style: liveText(13, FontWeight.w500, LiveColors.textBody)),
        ),
      ]),
      const SizedBox(height: 10),
      Text(summary, style: liveText(13, FontWeight.w500, LiveColors.textSub)),
    ]);
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.person,
    required this.isMe,
    required this.rank,
    required this.cooldown,
    required this.onPoke,
    required this.offOverlay,
  });

  final LiveParticipant person;
  final bool isMe;
  final int? rank;
  final Duration cooldown;
  final VoidCallback onPoke;
  final Color offOverlay;

  @override
  Widget build(BuildContext context) => Row(children: [
        LiveAvatar(person.participant, size: 52, borderWidth: 1.3, off: person.status == LiveStatus.sharingOff, offOverlay: offOverlay),
        const SizedBox(width: 18),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '${person.participant.name} (나)' : person.participant.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: liveText(14, FontWeight.w500, LiveColors.textStrong)),
            const SizedBox(height: 5),
            LiveStatusLine(person),
          ]),
        ),
        const SizedBox(width: 8),
        LiveAction(person: person, isMe: isMe, rank: rank, cooldown: cooldown, onPoke: onPoke),
      ]);
}
