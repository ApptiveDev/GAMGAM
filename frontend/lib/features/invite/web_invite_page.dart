import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/app_install.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/layout.dart';
import '../../core/widgets/tags.dart';
import '../../data/models/appointment.dart';
import '../../data/models/participant.dart';
import '../../data/repositories/appointment_repository.dart';
import '../room/widgets/place_vote_card.dart';
import '../room/widgets/time_vote_tile.dart';
import 'widgets/install_app_card.dart';
import 'widgets/participant_list.dart';

/// 웹에서 초대 링크(/invite/:code)를 열었을 때. 앱 설치 없이 이름만 넣고 참여한다.
/// 조율 중이면 이름 입력 → 투표, 확정되면 확정 정보 + 앱 설치 유도.
class WebInvitePage extends StatefulWidget {
  const WebInvitePage({super.key, required this.code});

  final String code;

  @override
  State<WebInvitePage> createState() => _WebInvitePageState();
}

class _WebInvitePageState extends State<WebInvitePage> {
  final _name = TextEditingController();
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _join(AppointmentRepository repo, Appointment a) async {
    final name = _name.text.trim();
    if (name.isEmpty || _joining) return;
    setState(() => _joining = true);
    final guest = await repo.joinAsGuest(a.id, name);
    if (!mounted) return;
    setState(() => _joining = false);
    if (guest.name != name) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('같은 이름이 있어서 ${guest.name}(으)로 참여했어요')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findByInviteCode(widget.code);

    if (a == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(22, 32, 22, 24),
            child: PageTitle('초대 코드를 찾을 수 없어요', subtitle: '링크가 맞는지 친구에게 다시 확인해주세요.'),
          ),
        ),
      );
    }

    final guest = repo.guestOf(a.id);
    final closed = a.isVoteClosed(DateTime.now());

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
          children: [
            const Text('GAMGAM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.point, letterSpacing: 1)),
            const SizedBox(height: 10),
            _title(a, guest, closed),
            const SizedBox(height: 20),
            _SummaryCard(appointment: a),
            if (guest != null && a.isCoordinating && a.template.hasVote) ..._votingSections(repo, a, guest, closed),
            const SizedBox(height: 28),
            SectionHeader('참여자 ${a.participants.length}명'),
            ParticipantList(appointment: a, meId: guest?.id),
            if (guest == null && !a.isCompleted) ...[
              const SizedBox(height: 28),
              const SectionHeader('내 이름'),
              TextField(
                controller: _name,
                maxLength: 10,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _join(repo, a),
                decoration: const InputDecoration(hintText: '친구들이 알아볼 이름', counterText: ''),
              ),
            ],
            if (guest != null && a.isConfirmed) ...[
              const SizedBox(height: 28),
              const InstallAppCard(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _bottomCta(repo, a, guest, closed),
    );
  }

  Widget _title(Appointment a, Participant? guest, bool closed) {
    final host = a.participants.where((p) => p.id == a.hostId).firstOrNull;
    if (a.isCompleted) return const PageTitle('이미 끝난 약속이에요');
    if (guest == null) return PageTitle('${host?.name ?? '친구'}님이\n약속에 초대했어요', subtitle: '앱 설치 없이 이름만 넣으면 참여할 수 있어요.');
    if (a.isConfirmed) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SoftBadge('약속이 확정됐어요'),
        const SizedBox(height: 12),
        PageTitle('${guest.name}님, 이때 만나요'),
      ]);
    }
    if (!a.template.hasVote) return PageTitle('${guest.name}님으로 참여했어요', subtitle: '방장이 확정하면 이 링크에서 볼 수 있어요.');
    return PageTitle(
      '${guest.name}님으로 참여 중',
      subtitle: closed ? '투표가 마감됐어요. 방장이 확정하면 이 링크에서 볼 수 있어요.' : '되는 시간과 장소를 골라주세요. 고르면 바로 저장돼요.',
    );
  }

  List<Widget> _votingSections(AppointmentRepository repo, Appointment a, Participant guest, bool closed) {
    final t = a.template;
    return [
      if (t.votesTime) ...[
        const SizedBox(height: 28),
        const SectionHeader('언제 만날까요?', trailing: '중복 선택 가능'),
        for (final o in a.timeOptions)
          TimeVoteTile(
            option: o,
            voters: a.participants.where((p) => o.voterIds.contains(p.id)).toList(),
            voted: o.votedBy(guest.id),
            onTap: closed ? null : () => repo.toggleTimeVote(a.id, o.id, voterId: guest.id),
          ),
      ],
      if (t.votesPlace) ...[
        const SizedBox(height: 28),
        const SectionHeader('어디서 만날까요?', trailing: '한 곳만'),
        for (final o in a.placeOptions)
          PlaceVoteCard(
            option: o,
            total: a.participants.length,
            leading: o == a.placeOptions.reduce((x, y) => y.voteCount > x.voteCount ? y : x) && o.voteCount > 0,
            voted: o.votedBy(guest.id),
            onTap: closed ? null : () => repo.votePlace(a.id, o.id, voterId: guest.id),
          ),
      ],
    ];
  }

  Widget? _bottomCta(AppointmentRepository repo, Appointment a, Participant? guest, bool closed) {
    if (a.isCompleted) return null;
    if (guest == null) {
      final votes = a.isCoordinating && a.template.hasVote && !closed;
      return BottomCta(children: [
        FilledButton(
          onPressed: _name.text.trim().isEmpty || _joining ? null : () => _join(repo, a),
          child: Text(_joining ? '참여하는 중…' : (votes ? '참여하고 투표하기' : '참여하기')),
        ),
      ]);
    }
    if (a.isConfirmed) {
      return BottomCta(children: [FilledButton(onPressed: () => AppInstall.open(context), child: const Text('앱 설치하러 가기'))]);
    }
    return null;
  }
}

/// 약속 이름 + 지금 상태(조율 중이면 1위 후보·마감, 확정이면 시간·장소·벌칙).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final deadline = a.voteDeadline;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderCard, width: 1.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(a.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.textTitle))),
          if (a.isCoordinating) const OutlineTag('조율 중'),
        ]),
        const SizedBox(height: 14),
        _InfoRow(icon: Icons.calendar_today_outlined, text: _timeText(a)),
        const SizedBox(height: 8),
        _InfoRow(icon: Icons.place_outlined, text: _placeText(a)),
        if (!a.isCoordinating && a.penalty != null) ...[
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.timer_outlined, text: a.penalty == '벌칙 없음' ? '이번엔 벌칙 없이 만나요' : '${a.lateThresholdMinutes}분 넘게 늦으면 ${a.penalty}'),
        ],
        if (a.isCoordinating && deadline != null) ...[
          const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
          Text(
            a.isVoteClosed(DateTime.now()) ? '투표가 마감됐어요' : '투표 마감 · ${DateText.dateTime(deadline)}까지',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.point),
          ),
        ],
      ]),
    );
  }

  static String _timeText(Appointment a) {
    if (a.isCoordinating && a.template.votesTime) return '시간 투표 중';
    return a.time == null ? '시간 미정' : DateText.dateTime(a.time!);
  }

  static String _placeText(Appointment a) {
    if (a.isCoordinating && a.template.votesPlace) return '장소 투표 중';
    final place = a.place;
    if (place == null) return '장소 미정';
    return place.description.isEmpty ? place.name : '${place.name} · ${place.description}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 16, color: AppColors.textSub),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textBody))),
      ]);
}
