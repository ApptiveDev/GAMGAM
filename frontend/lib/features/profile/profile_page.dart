import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar.dart';
import '../../data/repositories/appointment_repository.dart';

/// 내정보 탭. 로그인·방별 위치 공유 설정 등이 들어올 자리.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppointmentRepository>().me;
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
          ],
        ),
      ),
    );
  }
}
