import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/live_location.dart';
import 'live_style.dart';

/// 지도 위 참여자: 프로필 원 + "이름 · N분" 라벨. 손으로 붙인 스티커처럼 사람마다 살짝 기울인다.
/// 탭은 [LiveMapView.onPinTap]에서 받는다.
class ParticipantMarker extends StatelessWidget {
  const ParticipantMarker({super.key, required this.person, this.selected = false});

  final LiveParticipant person;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final eta = person.status == LiveStatus.notDeparted ? '집 · ${person.etaMinutes}분' : '${person.etaMinutes}분';
    return Center(
      child: Transform.rotate(
        angle: _tilt(person.id),
        child: SizedBox(
          width: 56,
          height: 68,
          child: Stack(clipBehavior: Clip.none, children: [
            LiveAvatar(person.participant, size: 56, borderWidth: 2, selected: selected),
            Positioned(
              left: -3,
              top: 52,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), boxShadow: liveShadow),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(person.participant.name, style: liveText(10, FontWeight.w600, LiveColors.textStrong)),
                  const SizedBox(width: 3),
                  Text('·', style: liveText(11, FontWeight.w700, LiveColors.textHint)),
                  const SizedBox(width: 3),
                  Text(eta, style: liveText(10, FontWeight.w400, LiveColors.textBody)),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  /// 사람마다 고정된 -5° ~ +9° 기울기. 앱을 다시 켜도 바뀌지 않게 id 글자로 정한다.
  static double _tilt(String id) {
    final degrees = -5 + id.codeUnits.fold(0, (a, b) => a + b) % 15;
    return degrees * math.pi / 180;
  }
}

/// 목적지 핀: 검은 물방울 + 흰 깃발. 핀 끝이 상자 아래 가운데에 오도록 그림자 여백만큼 내린다.
class DestinationPin extends StatelessWidget {
  const DestinationPin({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '목적지',
        child: Transform.translate(
          offset: const Offset(0, 8),
          child: Center(child: SvgPicture.asset('assets/icons/live_map/destination_pin.svg', width: 42.66, height: 45.8)),
        ),
      );
}
