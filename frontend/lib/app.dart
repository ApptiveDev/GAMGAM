import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/api/api_client.dart';
import 'data/api/auth_controller.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/api_appointment_repository.dart';
import 'data/repositories/live_location_repository.dart';
import 'data/repositories/api_live_location_repository.dart';

class GamgamApp extends StatefulWidget {
  const GamgamApp({super.key, this.repository, this.liveRepository, this.auth, this.initialLocation});

  /// 테스트에서 다른 구현체를 넣는다. 기본값은 서버를 읽고, 서버에 없는 기능은 목업으로 채우는 구현체.
  final AppointmentRepository? repository;
  final LiveLocationRepository? liveRepository;

  /// 넣지 않으면 서버 저장소일 때만 로그인을 요구하고, 목업 저장소면 로그인 없이 연다.
  final AuthController? auth;
  final String? initialLocation;

  @override
  State<GamgamApp> createState() => _GamgamAppState();
}

class _GamgamAppState extends State<GamgamApp> {
  late final AppointmentRepository _repository = widget.repository ?? ApiAppointmentRepository();
  late final LiveLocationRepository _liveRepository = widget.liveRepository ?? _apiLiveRepository();
  late final AuthController _auth = widget.auth ?? _defaultAuth();
  late final GoRouter _router =
      widget.initialLocation == null ? createRouter(auth: _auth) : createRouter(auth: _auth, initialLocation: widget.initialLocation!);
  String? _loadedUserId;

  AuthController _defaultAuth() {
    final repository = _repository;
    return repository is ApiAppointmentRepository ? AuthController(repository.client) : AuthController.offline();
  }

  @override
  void initState() {
    super.initState();
    _auth.addListener(_reloadForUser);
  }

  /// 처음 켤 때는 로그인 전이라 서버 약속을 못 읽는다. 로그인한 사용자가 바뀌면 다시 읽는다.
  void _reloadForUser() {
    final repository = _repository;
    final userId = _auth.user?.id;
    if (userId == null || userId == _loadedUserId || repository is! ApiAppointmentRepository) return;
    _loadedUserId = userId;
    repository.load();
  }

  /// 약속 저장소와 같은 로그인(토큰)을 쓴다.
  LiveLocationRepository _apiLiveRepository() {
    final repository = _repository;
    if (repository is! ApiAppointmentRepository) return ApiLiveLocationRepository(meId: repository.me.id, client: ApiClient());
    return ApiLiveLocationRepository(meId: repository.me.id, client: repository.client, isServerAppointment: repository.isServerAppointment);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.removeListener(_reloadForUser);
    if (widget.auth == null) _auth.dispose();
    // 직접 만든 목업만 정리한다. 밖에서 넣어준 구현체는 넣어준 쪽이 정리한다.
    if (widget.liveRepository == null) _liveRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: _auth),
          ChangeNotifierProvider<AppointmentRepository>.value(value: _repository),
          ChangeNotifierProvider<LiveLocationRepository>.value(value: _liveRepository),
        ],
        child: MaterialApp.router(
          title: 'GAMGAM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.gam,
          routerConfig: _router,
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => _PhoneWidth(child: child!),
        ),
      );
}

/// 화면은 휴대폰 세로 화면(Figma 360 폭) 기준이다. 웹·태블릿처럼 넓은 창에서는 가운데에 휴대폰 폭으로만 그린다.
class _PhoneWidth extends StatelessWidget {
  const _PhoneWidth({required this.child});

  final Widget child;

  static const maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;
    return ColoredBox(
      color: const Color(0xFF2B2A28),
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(data: media.copyWith(size: Size(maxWidth, media.size.height)), child: child),
        ),
      ),
    );
  }
}
