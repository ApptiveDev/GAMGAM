import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api/auth_controller.dart';
import '../../features/appointment/appointment_page.dart';
import '../../features/appointment/place_picker_page.dart';
import '../../features/arrival/arrival_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
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

GoRouter createRouter({required AuthController auth, String initialLocation = AppRoutes.home}) => GoRouter(
      initialLocation: initialLocation,
      refreshListenable: auth,
      redirect: (_, state) => _authRedirect(auth, state),
      routes: [
        GoRoute(path: AppRoutes.login, pageBuilder: (_, state) => _fade(state, LoginPage(from: state.uri.queryParameters['from']))),
        GoRoute(path: AppRoutes.signup, pageBuilder: (_, state) => _fade(state, SignupPage(from: state.uri.queryParameters['from']))),

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

/// 로그인하지 않았으면 로그인 화면으로, 로그인했는데 로그인 화면이면 홈(또는 초대 링크)으로 보낸다.
String? _authRedirect(AuthController auth, GoRouterState state) {
  final path = state.matchedLocation;
  final atAuth = path == AppRoutes.login || path == AppRoutes.signup;
  if (!auth.isLoggedIn) {
    if (atAuth) return null;
    // 초대 링크로 들어왔으면 로그인한 뒤 그 초대 화면으로 돌아간다.
    return AppRoutes.loginFrom(path.startsWith('/invite/') ? state.uri.toString() : null);
  }
  if (!atAuth) return null;
  final from = state.uri.queryParameters['from'];
  return from != null && from.startsWith('/invite/') ? from : AppRoutes.home;
}

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
