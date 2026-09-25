import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/appointment_repository.dart';
import 'widgets/appointment_tile.dart';
import 'widgets/closest_appointment_card.dart';
import 'widgets/join_by_code_dialog.dart';

/// 01 · 홈 — 내 약속 목록
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentRepository>().myAppointments;
    final now = DateTime.now();

    // 가장 가까운 확정 약속을 크게, 나머지 예정 약속은 리스트로.
    final confirmed = appointments.where((a) => a.isConfirmed && a.time != null && a.time!.isAfter(now)).toList()
      ..sort((a, b) => a.time!.compareTo(b.time!));
    final closest = confirmed.firstOrNull;
    final scheduled = [
      ...confirmed.skip(1),
      ...appointments.where((a) => a.isCoordinating),
    ];
    final past = appointments.where((a) => a.isCompleted).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.create),
        backgroundColor: AppColors.point,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text('약속 만들기', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
          children: [
            Row(children: [
              const Expanded(child: Text('내 약속', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textTitle))),
              IconButton(
                tooltip: '초대 코드로 참여',
                onPressed: () => showJoinByCodeDialog(context),
                icon: const Icon(Icons.qr_code_2_rounded, color: AppColors.textSub),
              ),
            ]),
            const SizedBox(height: 16),
            if (closest != null)
              ClosestAppointmentCard(appointment: closest, onTap: () => context.push(AppRoutes.room(closest.id)))
            else
              const _EmptyCard(),
            if (scheduled.isNotEmpty) ...[
              const SizedBox(height: 28),
              const _SectionLabel('예정된 약속'),
              for (final a in scheduled) AppointmentTile(appointment: a, onTap: () => context.push(AppRoutes.room(a.id))),
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionLabel('지난 약속'),
              for (final a in past) PastAppointmentTile(appointment: a),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSub)),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
        child: const Column(children: [
          Text('다가오는 약속이 없어요', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          SizedBox(height: 6),
          Text('약속을 만들고 친구들에게 링크를 보내보세요.', style: TextStyle(fontSize: 13, color: AppColors.textSub)),
        ]),
      );
}
