import '../../../core/utils/date_text.dart';
import '../../../data/models/live_location.dart';

/// 당일 지도 문구. 늦는 사람도 사실만 담백하게.
abstract final class LiveText {
  /// "도착 · 오후 6:14" / "5분 후 도착 · 걷는 중" / "이동 중 · 자동차" / "출발 전 · 집에 있음" / "위치 공유 꺼짐"
  static String status(LiveParticipant p) {
    final (main, detail) = statusParts(p);
    return detail == null ? main : '$main · $detail';
  }

  /// [status]를 가운데 점 앞뒤로 나눈 것. 디자인에서 앞뒤 글자 크기가 다르다.
  static (String, String?) statusParts(LiveParticipant p) => switch (p.status) {
        LiveStatus.arrived => ('도착', DateText.time(p.arrivedAt!)),
        LiveStatus.moving when (p.etaMinutes ?? 99) <= 5 => ('${p.etaMinutes}분 후 도착', p.transport.movingLabel),
        LiveStatus.moving => ('이동 중', p.transport.label),
        LiveStatus.notDeparted => ('출발 전', '집에 있음'),
        LiveStatus.sharingOff => ('위치 공유 꺼짐', null),
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
}
