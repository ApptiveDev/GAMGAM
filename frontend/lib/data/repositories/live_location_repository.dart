import 'package:flutter/foundation.dart';

import '../models/appointment.dart';
import '../models/live_location.dart';

/// 핵심기능 #2 — 당일 위치 공유. 화면은 이 인터페이스만 안다.
/// 지금은 [MockLiveLocationRepository]를 쓰고, 백엔드(위치 저장·WebSocket·푸시)가 나오면 구현체만 바꿔 끼운다.
abstract class LiveLocationRepository extends ChangeNotifier {
  /// 이 방에서 내가 고른 공개 범위. 아직 안 골랐으면 null → 06을 보여준다.
  ShareLevel? shareLevelOf(String appointmentId);

  Future<void> setShareLevel(String appointmentId, ShareLevel level);

  /// 당일 현황. [start] 전에는 null.
  LiveSession? session(String appointmentId);

  /// 당일 지도를 보는 동안만 실시간 구독을 켠다.
  void start(Appointment appointment);
  void stop(String appointmentId);

  Stream<LiveEvent> events(String appointmentId);

  /// 이 사람에게 다시 콕 찌를 수 있을 때까지 남은 시간. 지금 가능하면 [Duration.zero].
  Duration pokeCooldownOf(String appointmentId, String targetId);

  Future<void> poke(String appointmentId, String targetId, PokeMessage message);

  Future<void> reply(String appointmentId, Poke poke, PokeReply reply);
}
