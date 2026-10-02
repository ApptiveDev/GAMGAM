import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/api_appointment_repository.dart';
import 'data/repositories/live_location_repository.dart';
import 'data/repositories/mock_live_location_repository.dart';

class GamgamApp extends StatefulWidget {
  const GamgamApp({super.key, this.repository, this.liveRepository, this.initialLocation, this.webInvite = kIsWeb});

  /// 테스트나 백엔드 연결 시 다른 구현체를 넣는다. 기본값은 목업.
  final AppointmentRepository? repository;
  final LiveLocationRepository? liveRepository;
  final String? initialLocation;

  /// 초대 링크를 웹 게스트 화면으로 열지. 테스트에서 웹 화면을 확인할 때 켠다.
  final bool webInvite;

  @override
  State<GamgamApp> createState() => _GamgamAppState();
}

class _GamgamAppState extends State<GamgamApp> {
  late final AppointmentRepository _repository = widget.repository ?? ApiAppointmentRepository();
  late final LiveLocationRepository _liveRepository = widget.liveRepository ?? MockLiveLocationRepository(meId: _repository.me.id);
  late final GoRouter _router = createRouter(initialLocation: widget.initialLocation ?? AppRoutes.home, webInvite: widget.webInvite);

  @override
  void dispose() {
    _router.dispose();
    // 직접 만든 목업만 정리한다. 밖에서 넣어준 구현체는 넣어준 쪽이 정리한다.
    if (widget.liveRepository == null) _liveRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AppointmentRepository>.value(value: _repository),
          ChangeNotifierProvider<LiveLocationRepository>.value(value: _liveRepository),
        ],
        child: MaterialApp.router(
          title: 'GAMGAM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router,
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
        ),
      );
}
