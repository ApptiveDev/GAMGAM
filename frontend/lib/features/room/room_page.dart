import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/avatar.dart';
import '../../core/widgets/dashed_add_button.dart';
import '../../core/widgets/date_time_picker.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/appointment.dart';
import '../../data/repositories/appointment_repository.dart';
import 'widgets/place_vote_card.dart';
import 'widgets/time_vote_tile.dart';

/// 03 · 방 — 조율 중 (확정 뒤에는 약속 요약)
class RoomPage extends StatelessWidget {
  const RoomPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findById(appointmentId);
    if (a == null) return const _MissingRoom();

    final me = repo.me;
    final isHost = a.isHost(me.id);

    return Scaffold(
      appBar: BackAppBar(onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        children: [
          _RoomHeader(appointment: a),
          const SizedBox(height: 16),
          _InviteBar(link: repo.inviteLink(a)),
          const SizedBox(height: 10),
          if (a.isCoordinating)
            const _Notice('링크로 들어온 친구는 설치 없이 투표할 수 있어요'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
          if (a.isCoordinating) ..._votingSections(context, repo, a) else _ConfirmedSummary(appointment: a),
        ],
      ),
      bottomNavigationBar: _bottomCta(context, a, isHost),
    );
  }

  List<Widget> _votingSections(BuildContext context, AppointmentRepository repo, Appointment a) {
    final me = repo.me;
    final t = a.template;
    return [
      if (t.votesTime) ...[
        const SectionHeader('시간 투표', trailing: '중복 선택 가능'),
        for (final o in a.timeOptions)
          TimeVoteTile(
            option: o,
            voters: a.participants.where((p) => o.voterIds.contains(p.id)).toList(),
            voted: o.votedBy(me.id),
            onTap: () => repo.toggleTimeVote(a.id, o.id),
          ),
        DashedAddButton(
          label: '다른 시간 제안하기',
          onTap: () async {
            final picked = await pickDateTime(context, initial: a.time);
            if (picked != null) repo.addTimeOption(a.id, picked);
          },
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
      ] else
        _FixedRow(label: '시간', value: a.time == null ? '-' : DateText.dateTime(a.time!), note: '방장이 정함'),
      if (t.votesPlace) ...[
        const SectionHeader('장소 투표'),
        for (final o in a.placeOptions)
          PlaceVoteCard(
            option: o,
            total: a.participants.length,
            leading: o == a.placeOptions.reduce((x, y) => y.voteCount > x.voteCount ? y : x) && o.voteCount > 0,
            voted: o.votedBy(me.id),
            onTap: () => repo.votePlace(a.id, o.id),
          ),
      ] else
        _FixedRow(label: '장소', value: a.place?.name ?? '-', note: '방장이 정함'),
      if (a.pendingVoterCount > 0) ...[
        const SizedBox(height: 16),
        _PendingRow(count: a.pendingVoterCount),
      ],
    ];
  }

  Widget? _bottomCta(BuildContext context, Appointment a, bool isHost) {
    if (a.isCoordinating) {
      // 확정은 방장만. 방장이 아니면 버튼 대신 안내.
      if (!isHost) return const BottomCta(children: [Text('방장이 확정하면 알려드릴게요', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSub))]);
      return BottomCta(children: [FilledButton(onPressed: () => context.push(AppRoutes.penalty(a.id)), child: const Text('확정하기'))]);
    }
    if (a.isConfirmed) {
      return BottomCta(children: [
        OutlinedButton(onPressed: () => context.push(AppRoutes.confirmed(a.id)), child: const Text('확정 카드 보기')),
        const SizedBox(height: 8),
        // 핵심기능 #2 진입점
        FilledButton(onPressed: () => context.push(AppRoutes.liveMap(a.id)), child: const Text('당일 지도 열기')),
      ]);
    }
    return null;
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final state = switch (a.status) {
      AppointmentStatus.coordinating => '조율 중',
      AppointmentStatus.confirmed => '확정',
      AppointmentStatus.completed => '지난 약속',
    };
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(a.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          const SizedBox(height: 4),
          Text('$state · ${a.participants.length}명 참여', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ]),
      ),
      AvatarStack(a.participants, size: 30, max: 4),
    ]);
  }
}

class _InviteBar extends StatelessWidget {
  const _InviteBar({required this.link});

  final String link;

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 링크를 복사했어요')));
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.textTitle, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            icon: const Icon(Icons.link, size: 18),
            label: const Text('초대 링크 복사'),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox.square(
          dimension: 44,
          child: OutlinedButton(
            // TODO: 방 나가기, 약속 수정 등
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size.square(44),
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
            ),
            child: const Icon(Icons.more_horiz, color: AppColors.textMuted),
          ),
        ),
      ]);
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(11)),
        child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
      );
}

class _FixedRow extends StatelessWidget {
  const _FixedRow({required this.label, required this.value, this.note});

  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(children: [
          SizedBox(width: 48, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textTitle))),
          if (note != null) Text(note!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ]),
      );
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.radio_button_unchecked, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(child: Text('$count명이 아직 투표하지 않았어요', style: const TextStyle(fontSize: 13, color: AppColors.textSub))),
        TextButton(
          // TODO: 백엔드 푸시 알림 연결
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('투표 알림을 보냈어요'))),
          style: TextButton.styleFrom(foregroundColor: AppColors.point),
          child: const Text('알림 보내기'),
        ),
      ]);
}

class _ConfirmedSummary extends StatelessWidget {
  const _ConfirmedSummary({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _FixedRow(label: '시간', value: a.time == null ? '-' : DateText.dateTime(a.time!)),
      _FixedRow(label: '장소', value: a.place?.name ?? '-'),
      _FixedRow(label: '벌칙', value: a.penalty == null ? '-' : '${a.lateThresholdMinutes}분 넘게 늦으면 ${a.penalty}'),
    ]);
  }
}

class _MissingRoom extends StatelessWidget {
  const _MissingRoom();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BackAppBar(onBack: () => context.go(AppRoutes.home)),
        body: const Center(child: Text('약속을 찾을 수 없어요.')),
      );
}
