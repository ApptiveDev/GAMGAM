import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/live_location.dart';
import 'live_text.dart';

/// 지도 위 참여자: 프로필 원 + 이동수단 배지 + ETA.
class ParticipantMarker extends StatelessWidget {
  const ParticipantMarker({super.key, required this.person, this.isMe = false});

  final LiveParticipant person;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final ring = isMe ? AppColors.textBody : AppColors.textSub;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox.square(
        dimension: 52,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 2.5),
              boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Text(person.participant.initial, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ring)),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(color: ring, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(LiveText.transportIcon(person.transport), size: 13, color: Colors.white),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))],
        ),
        child: Text(
          person.status == LiveStatus.notDeparted ? '집 · ${person.etaMinutes}분' : '${person.etaMinutes}분',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textBody),
        ),
      ),
    ]);
  }
}

/// 목적지 핀: "목적지" 라벨 + 물방울 핀.
class DestinationPin extends StatelessWidget {
  const DestinationPin({super.key});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: AppColors.point, borderRadius: BorderRadius.circular(999)),
          child: const Text('목적지', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
        ),
        const Icon(Icons.location_on, size: 44, color: AppColors.point),
      ]);
}
