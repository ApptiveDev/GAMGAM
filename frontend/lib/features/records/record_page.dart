import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/avatar.dart';
import '../../data/repositories/appointment_repository.dart';

/// 10 · 기록 탭. 지금은 지난 약속 목록만. 통계·리플레이는 핵심기능 #2 이후.
class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final past = context.watch<AppointmentRepository>().myAppointments.where((a) => a.isCompleted).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
          children: [
            const Text('기록', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
            const SizedBox(height: 20),
            const Text('지난 약속', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSub)),
            const SizedBox(height: 10),
            if (past.isEmpty) const Text('아직 지난 약속이 없어요.', style: TextStyle(color: AppColors.textMuted)),
            for (final a in past)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(a.name),
                subtitle: Text([if (a.time != null) '${a.time!.month}월 ${a.time!.day}일', if (a.place != null) a.place!.name].join(' · ')),
                trailing: AvatarStack(a.participants, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}
