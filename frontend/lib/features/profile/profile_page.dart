import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/live_location_repository.dart';

/// 내정보 탭. 로그인 등이 들어올 자리. 방별 위치 공유 설정을 여기서 바꾼다.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final live = context.watch<LiveLocationRepository>();
    final me = repo.me;
    final upcoming = repo.myAppointments.where((a) => a.isConfirmed).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            const Text('내정보', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
            const SizedBox(height: 24),
            Row(children: [
              Avatar(me, size: 56),
              const SizedBox(width: 14),
              Text(me.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 32),
            const Text('방별 위치 공유', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSub)),
            const SizedBox(height: 4),
            const Text('약속 2시간 전부터 도착할 때까지만 켜져요.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            if (upcoming.isEmpty) const Text('확정된 약속이 없어요.', style: TextStyle(color: AppColors.textMuted)),
            for (final a in upcoming)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text(live.shareLevelOf(a.id)?.title ?? '아직 안 정함 · 기본으로 보여요'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                onTap: () => context.push(AppRoutes.locationSetting(a.id)),
              ),
          ],
        ),
      ),
    );
  }
}
