import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/appointment/appointment_page.dart';
import '../../features/appointment/place_picker_page.dart';
import '../../features/arrival/arrival_page.dart';
import '../../features/confirmed/confirmed_page.dart';
import '../../features/create/name_entry_page.dart';
import '../../features/group/group_page.dart';
import '../../features/group/group_search_page.dart';
import '../../features/groups/groups_page.dart';
import '../../features/home/home_page.dart';
import '../../features/invite/invite_page.dart';
import '../../features/live_map/live_map_page.dart';
import '../../features/location_setting/location_setting_page.dart';
import '../../features/penalty/penalty_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/shell/main_shell.dart';
import '../theme/app_theme.dart';
import 'app_routes.dart';

GoRouter createRouter({String initialLocation = AppRoutes.home}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        // 하단 탭 3개. 탭마다 스택이 따로 유지된다.
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => MainShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.groups, builder: (context, state) => const GroupsPage())]),
            StatefulShellBranch(routes: [GoRoute(path: AppRoutes.profile, builder: (context, state) => const _Legacy(ProfilePage()))]),
          ],
        ),

        GoRoute(path: AppRoutes.createGroup, pageBuilder: (_, state) => _fade(state, const NameEntryPage.group())),
        GoRoute(
          path: '/groups/:gid',
          builder: (_, state) => GroupPage(groupId: state.pathParameters['gid']!),
          routes: [
            GoRoute(path: 'search', pageBuilder: (_, state) => _fade(state, GroupSearchPage(groupId: state.pathParameters['gid']!))),
            GoRoute(path: 'new', pageBuilder: (_, state) => _fade(state, NameEntryPage.appointment(groupId: state.pathParameters['gid']!))),
          ],
        ),

        // 약속 상세. 하위 화면은 위에 쌓이므로 뒤로가기하면 약속 상세로 돌아온다.
        GoRoute(
          path: '/appointments/:id',
          builder: (_, state) => AppointmentPage(appointmentId: state.pathParameters['id']!),
          routes: [
            GoRoute(path: 'rename', pageBuilder: (_, state) => _fade(state, NameEntryPage.rename(appointmentId: state.pathParameters['id']!))),
            GoRoute(path: 'places', builder: (_, state) => PlacePickerPage(appointmentId: state.pathParameters['id']!)),
            // 아래는 디자인이 나오기 전 화면들이라 예전 테마로 그린다.
            GoRoute(path: 'penalty', builder: (_, state) => _Legacy(PenaltyPage(appointmentId: state.pathParameters['id']!))),
            GoRoute(path: 'confirmed', builder: (_, state) => _Legacy(ConfirmedPage(appointmentId: state.pathParameters['id']!))),
            GoRoute(
              path: 'location-setting',
              builder: (_, state) => _Legacy(LocationSettingPage(
                appointmentId: state.pathParameters['id']!,
                thenLiveMap: state.uri.queryParameters['next'] == 'live',
              )),
            ),
            GoRoute(path: 'live', builder: (_, state) => _Legacy(LiveMapPage(appointmentId: state.pathParameters['id']!))),
            GoRoute(path: 'arrival', builder: (_, state) => _Legacy(ArrivalPage(appointmentId: state.pathParameters['id']!))),
          ],
        ),

        GoRoute(path: '/invite/:code', builder: (_, state) => _Legacy(InvitePage(code: state.pathParameters['code']!))),
      ],
      errorBuilder: (context, state) => const _Legacy(_NotFoundPage()),
    );

/// 이름 입력처럼 배경이 같은 화면은 밀지 않고 겹쳐서 바꾼다.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    );

/// 지도·위치 공유처럼 아직 새 디자인이 없는 화면. 예전 테마 그대로 보이게 감싼다.
class _Legacy extends StatelessWidget {
  const _Legacy(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(data: AppTheme.light, child: child);
}

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
