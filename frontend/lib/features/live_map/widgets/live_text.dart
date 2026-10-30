import 'package:flutter/material.dart';

import '../../../core/utils/date_text.dart';
import '../../../data/models/live_location.dart';

/// 당일 지도 문구. 늦는 사람도 사실만 담백하게.
abstract final class LiveText {
  /// "도착 · 오후 6:14" / "5분 후 도착 · 걷는 중" / "이동 중 · 자동차" / "출발 전 · 집에 있음" / "위치 공유 꺼짐"
  static String status(LiveParticipant p) => switch (p.status) {
        LiveStatus.arrived => '도착 · ${DateText.time(p.arrivedAt!)}',
        LiveStatus.moving when (p.etaMinutes ?? 99) <= 5 => '${p.etaMinutes}분 후 도착 · ${p.transport.movingLabel}',
        LiveStatus.moving => '이동 중 · ${p.transport.label}',
        LiveStatus.notDeparted => '출발 전 · 집에 있음',
        LiveStatus.sharingOff => '위치 공유 꺼짐',
      };

  /// 콕 찌르기 시트의 한 줄 요약. "이동 중 · 도착까지 18분"
  static String summary(LiveParticipant p) => switch (p.status) {
        LiveStatus.moving => '이동 중 · 도착까지 ${p.etaMinutes}분',
        LiveStatus.notDeparted => '출발 전 · 도착까지 ${p.etaMinutes}분',
        _ => status(p),
      };

  /// 약속까지 남은 시간. "42분" / "1시간 12분" / "3분 지남"
  static String remaining(Duration d) {
    if (d.isNegative) return '${-d.inMinutes}분 지남';
    final minutes = (d.inSeconds / 60).ceil();
    if (minutes < 60) return '$minutes분';
    return '${minutes ~/ 60}시간 ${minutes % 60}분';
  }

  /// 쿨다운 남은 시간. "3:12"
  static String cooldown(Duration d) => '${d.inMinutes}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

  static IconData transportIcon(Transport t) => switch (t) {
        Transport.walk => Icons.directions_walk,
        Transport.bus => Icons.directions_bus,
        Transport.car => Icons.directions_car,
        Transport.subway => Icons.subway,
      };
}
