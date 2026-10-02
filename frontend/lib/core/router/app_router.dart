import 'package:flutter/foundation.dart';
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
import '../../features/invite/web_invite_page.dart';
import '../../features/live_map/live_map_page.dart';
import '../../features/location_setting/location_setting_page.dart';
import '../../features/penalty/penalty_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/records/record_page.dart';
import '../../features/room/room_page.dart';
import '../../features/shell/main_shell.dart';
import 'app_routes.dart';

/// [webInvite]면 초대 링크가 게스트 화면(이름 입력 → 투표)으로 열린다. 기본값은 웹 여부.
GoRouter createRouter({String initialLocation = AppRoutes.home, bool webInvite = kIsWeb}) => GoRouter(
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
            GoRoute(
              path: 'location-setting',
              builder: (_, state) => LocationSettingPage(
                appointmentId: state.pathParameters['id']!,
                thenLiveMap: state.uri.queryParameters['next'] == 'live',
              ),
            ),
            GoRoute(path: 'live', builder: (_, state) => LiveMapPage(appointmentId: state.pathParameters['id']!)),
            GoRoute(path: 'arrival', builder: (_, state) => ArrivalPage(appointmentId: state.pathParameters['id']!)),
          ],
        ),

        // 웹: 앱 없이 이름만으로 게스트 참여. 앱: 로그인한 내가 바로 참여.
        GoRoute(
          path: '/invite/:code',
          builder: (_, state) {
            final code = state.pathParameters['code']!;
            // 링크가 바뀌면 입력하던 이름이 남지 않도록 코드별로 새 화면을 만든다.
            return webInvite ? WebInvitePage(key: ValueKey(code), code: code) : InvitePage(code: code);
          },
        ),
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
