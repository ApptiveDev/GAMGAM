import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/appointment_create/create_appointment_controller.dart';
import '../../features/appointment_create/details_page.dart';
import '../../features/appointment_create/template_page.dart';
import '../../features/arrival/arrival_page.dart';
import '../../features/confirmed/confirmed_page.dart';
import '../../features/home/home_page.dart';
import '../../features/invite/invite_page.dart';
import '../../features/live_map/live_map_page.dart';
import '../../features/location_setting/location_setting_page.dart';
import '../../features/penalty/penalty_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/records/record_page.dart';
import '../../features/room/room_page.dart';
import '../../features/shell/main_shell.dart';
import 'app_routes.dart';

GoRouter createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        // 하단 탭 3개. 탭마다 스택이 따로 유지된다.
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.records, builder: (context, state) => const RecordPage())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfilePage())]),
          ],
        ),

        // 약속 생성 플로우. 두 화면이 같은 draft(CreateAppointmentController)를 공유한다.
        // 플로우를 벗어나면 draft도 같이 사라진다.
        ShellRoute(
          builder: (context, state, child) => ChangeNotifierProvider(
            create: (_) => CreateAppointmentController(),
            child: child,
          ),
          routes: [
            GoRoute(
              path: AppRoutes.create,
              builder: (context, state) => const TemplatePage(),
              routes: [GoRoute(path: 'details', builder: (context, state) => const DetailsPage())],
            ),
          ],
        ),

        // 방. 하위 화면은 방 위에 쌓이므로 뒤로가기하면 방으로 돌아온다.
        GoRoute(
          path: '/appointments/:id',
          builder: (_, state) => RoomPage(appointmentId: state.pathParameters['id']!),
          routes: [
            GoRoute(path: 'penalty', builder: (_, state) => PenaltyPage(appointmentId: state.pathParameters['id']!)),
            GoRoute(path: 'confirmed', builder: (_, state) => ConfirmedPage(appointmentId: state.pathParameters['id']!)),
            GoRoute(path: 'location-setting', builder: (_, state) => LocationSettingPage(appointmentId: state.pathParameters['id']!)),
            GoRoute(path: 'live', builder: (_, state) => LiveMapPage(appointmentId: state.pathParameters['id']!)),
            GoRoute(path: 'arrival', builder: (_, state) => ArrivalPage(appointmentId: state.pathParameters['id']!)),
          ],
        ),

        GoRoute(path: '/invite/:code', builder: (_, state) => InvitePage(code: state.pathParameters['code']!)),
      ],
      errorBuilder: (context, state) => const _NotFoundPage(),
    );

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('페이지를 찾을 수 없어요.'),
            const SizedBox(height: 12),
            TextButton(onPressed: () => context.go(AppRoutes.home), child: const Text('홈으로')),
          ]),
        ),
      );
}
