import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar.dart';
import '../../../data/models/live_location.dart';
import 'live_text.dart';

/// 07 하단 시트 — 참여자 목록 + 콕 찌르기.
/// 반쯤 올라온 상태가 기본이고, 드래그로 접고 펼친다.
class ParticipantSheet extends StatelessWidget {
  const ParticipantSheet({
    super.key,
    required this.session,
    required this.meId,
    required this.cooldownOf,
    required this.onPoke,
    required this.onShowResult,
  });

  static const initialSize = 0.44;

  final LiveSession session;
  final String meId;
  final Duration Function(String participantId) cooldownOf;
  final ValueChanged<LiveParticipant> onPoke;
  final VoidCallback onShowResult;

  @override
  Widget build(BuildContext context) {
    final rows = _sorted(session.participants);
    final ranks = {for (final (i, p) in session.arrivalOrder.indexed) p.id: i + 1};

    // 가장 늦을 것 같은 사람의 콕 찌르기만 포인트 컬러로.
    final waiting = session.participants.where((p) => p.id != meId && (p.status == LiveStatus.moving || p.status == LiveStatus.notDeparted));
    final latestId = waiting.isEmpty ? null : waiting.reduce((a, b) => (b.etaMinutes ?? 0) > (a.etaMinutes ?? 0) ? b : a).id;

    return DraggableScrollableSheet(
      initialChildSize: initialSize,
      minChildSize: 0.14,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [initialSize],
      builder: (context, controller) => DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [BoxShadow(color: Color(0x1F000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Expanded(
                child:
                    Text('참여자 ${session.participants.length}명', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
              ),
              Text(session.allArrived ? '모두 도착했어요' : '2시간 전부터 공유 중', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ]),
            if (session.allArrived) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: onShowResult, child: const Text('다 모였어요! 결과 보기')),
            ],
            const SizedBox(height: 6),
            for (final (i, p) in rows.indexed)
              _Row(
                person: p,
                isMe: p.id == meId,
                rank: ranks[p.id],
                emphasized: p.id == latestId,
                cooldown: cooldownOf(p.id),
                onPoke: () => onPoke(p),
                last: i == rows.length - 1,
              ),
          ],
        ),
      ),
    );
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

class _Row extends StatelessWidget {
  const _Row({
    required this.person,
    required this.isMe,
    required this.rank,
    required this.emphasized,
    required this.cooldown,
    required this.onPoke,
    required this.last,
  });

  final LiveParticipant person;
  final bool isMe;
  final int? rank;
  final bool emphasized;
  final Duration cooldown;
  final VoidCallback onPoke;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final off = person.status == LiveStatus.sharingOff;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.surface))),
      child: Row(children: [
        Avatar(person.participant, size: 34, dashed: off),
        const SizedBox(width: 11),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isMe ? '${person.participant.name} (나)' : person.participant.name,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: off ? AppColors.textSub : AppColors.textTitle)),
            const SizedBox(height: 2),
            Text(LiveText.status(person), style: TextStyle(fontSize: 12, color: off ? AppColors.textMuted : AppColors.textSub)),
          ]),
        ),
        if (!person.arrived && !off) ...[
          Text('${person.etaMinutes}분', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(width: 8),
        ],
        _trailing(),
      ]),
    );
  }

  Widget _trailing() {
    if (person.arrived) {
      return _Pill(label: rank == 1 ? '1등 🎉' : '$rank등', background: AppColors.surface, foreground: AppColors.textBody);
    }
    if (isMe) return const SizedBox.shrink();
    if (cooldown > Duration.zero) {
      return _Pill(label: '${LiveText.cooldown(cooldown)} 후', background: AppColors.surfaceStrong, foreground: AppColors.textMuted);
    }
    final off = person.status == LiveStatus.sharingOff;
    return _PokeButton(onTap: onPoke, filled: emphasized, muted: off);
  }
}

class _PokeButton extends StatelessWidget {
  const _PokeButton({required this.onTap, required this.filled, required this.muted});

  final VoidCallback onTap;
  final bool filled;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final style = filled
        ? FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          )
        : OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            foregroundColor: muted ? AppColors.textMuted : AppColors.textSub,
            side: BorderSide(color: muted ? AppColors.divider : AppColors.borderStrong, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          );
    return filled
        ? FilledButton(onPressed: onTap, style: style, child: const Text('콕 찌르기'))
        : OutlinedButton(onPressed: onTap, style: style, child: const Text('콕 찌르기'));
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.background, required this.foreground});

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: foreground, fontFeatures: const [FontFeature.tabularFigures()])),
      );
}
