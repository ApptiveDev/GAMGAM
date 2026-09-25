import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/appointment_repository.dart';
import 'data/repositories/mock_appointment_repository.dart';

class GamgamApp extends StatefulWidget {
  const GamgamApp({super.key, this.repository, this.initialLocation});

  /// 테스트나 백엔드 연결 시 다른 구현체를 넣는다. 기본값은 목업.
  final AppointmentRepository? repository;
  final String? initialLocation;

  @override
  State<GamgamApp> createState() => _GamgamAppState();
}

class _GamgamAppState extends State<GamgamApp> {
  late final AppointmentRepository _repository = widget.repository ?? MockAppointmentRepository();
  late final GoRouter _router = widget.initialLocation == null ? createRouter() : createRouter(initialLocation: widget.initialLocation!);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider<AppointmentRepository>.value(
        value: _repository,
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
