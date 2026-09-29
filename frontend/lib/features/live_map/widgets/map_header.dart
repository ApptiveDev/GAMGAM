import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/dashed_border.dart';
import '../../../data/models/appointment.dart';
import '../../../data/models/live_location.dart';
import 'live_text.dart';

/// 지도 위 상단 오버레이: 약속 카드 + 남은 시간 + 지도 밖에 있는 사람 칩.
class MapHeader extends StatelessWidget {
  const MapHeader({super.key, required this.appointment, required this.session, required this.meId, required this.onBack});

  final Appointment appointment;
  final LiveSession session;
  final String meId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // 출발 전(집 위치 비공개)·공유 꺼짐은 지도에 없으니 칩으로 담백하게 알려준다.
    final offMap = session.participants.where((p) => p.id != meId && !p.arrived && !p.visibleOnMap).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Floating(
            radius: 22,
            child: IconButton(onPressed: onBack, icon: const Icon(Icons.chevron_left, color: AppColors.textSub), tooltip: '뒤로'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Floating(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(appointment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
                const SizedBox(height: 2),
                Text(appointment.place?.name ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          _Floating(
            color: AppColors.point,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(LiveText.remaining(session.remaining),
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
              const SizedBox(height: 4),
              Text(session.remaining.isNegative ? '약속 시간' : '약속까지', style: const TextStyle(fontSize: 11, color: Colors.white)),
            ]),
          ),
        ]),
        if (offMap.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final p in offMap) _OffMapChip(person: p)]),
        ],
      ]),
    );
  }
}

class _OffMapChip extends StatelessWidget {
  const _OffMapChip({required this.person});

  final LiveParticipant person;

  @override
  Widget build(BuildContext context) {
    final off = person.status == LiveStatus.sharingOff;
    final name = person.participant.name;
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(6, 5, 11, 5),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Avatar(person.participant, size: 20, dashed: off),
        const SizedBox(width: 6),
        Text(
          off ? '$name 위치 공유 꺼짐' : '$name 집에 있음 · ${person.etaMinutes}분',
          style: TextStyle(fontSize: 12, color: off ? AppColors.textSub : AppColors.textBody),
        ),
      ]),
    );
    if (off) {
      return DashedBorder(
        radius: 999,
        child: ClipRRect(borderRadius: BorderRadius.circular(999), child: ColoredBox(color: Colors.white.withValues(alpha: 0.9), child: content)),
      );
    }
    return _Floating(radius: 999, child: content);
  }
}

/// 지도 위에 떠 있는 흰 카드.
class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.color = Colors.white, this.radius = 14, this.padding = EdgeInsets.zero});

  final Widget child;
  final Color color;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: child,
      );
}
