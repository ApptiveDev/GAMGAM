import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../data/repositories/live_location_repository.dart';

/// 당일 지도 진입점. 이 방에서 공개 범위를 아직 안 골랐으면 06 위치 공유 설정을 먼저 보여준다.
void openLiveMap(BuildContext context, String appointmentId) {
  final chosen = context.read<LiveLocationRepository>().shareLevelOf(appointmentId) != null;
  context.push(chosen ? AppRoutes.liveMap(appointmentId) : AppRoutes.locationSetting(appointmentId, thenLiveMap: true));
}
