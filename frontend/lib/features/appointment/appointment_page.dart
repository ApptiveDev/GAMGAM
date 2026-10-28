import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/gam/countdown_text.dart';
import '../../core/widgets/gam/gam_buttons.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/member_avatars.dart';
import '../../core/widgets/gam/photo_card.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/appointment.dart';
import '../../data/models/place.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/live_location_repository.dart';
import '../live_map/open_live_map.dart';
import 'widgets/arrival_row.dart';
import 'widgets/vote_card.dart';
import 'widgets/time_sheet.dart';

/// 약속 상세. 상태에 따라 네 가지로 보인다.
/// - 약속 생성 초기화면: 시간·장소 후보가 없다.
/// - 시간 및 장소 투표: 후보를 고르고 투표한다.
/// - 투표 종료 후 약속 확정화면: 시간·장소가 정해졌다.
/// - 약속 확정이후 화면 최종: 위치 공유 시간(약속 2시간 전)부터. 지도·남은 시간·도착 현황.
class AppointmentPage extends StatefulWidget {
  const AppointmentPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<AppointmentPage> createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  /// 투표하기 전에 고른 후보.
  final _pickedTimes = <String>{};
  String? _pickedPlace;

  /// 추천 장소 "새로고침" 할 때마다 다음 묶음을 보여준다.
  var _recommendPage = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AppointmentRepository>();
    final a = repo.findById(widget.appointmentId);
    if (a == null) return const _MissingAppointment();
    final now = DateTime.now();
    final live = a.isConfirmed && a.confirmedTime != null && now.isAfter(a.confirmedTime!.subtract(const Duration(hours: 2)));

    return PinkFrame(
      child: Column(children: [
        FrameTopBar(
          leading: GamIconButton('ic_arrow_left', tooltip: '뒤로', onTap: () => context.canPop() ? context.pop() : context.go(AppRoutes.home)),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 48),
            children: [
              _Header(appointment: a, live: live),
              const SizedBox(height: 36),
              if (live) ..._liveSections(a) else ..._sections(a),
            ],
          ),
        ),
      ]),
    );
  }

  List<Widget> _sections(Appointment a) => [
        DetailSection(title: '시간', child: a.isVotingTime ? _timeVote(a) : _TimeCard(time: a.time)),
        const SizedBox(height: 26),
        DetailSection(title: '장소', child: a.isVotingPlace ? _placeVote(a) : _PlaceCard(place: a.place)),
        if (a.isVotingPlace) ...[
          const SizedBox(height: 36),
          _recommendations(a),
        ],
      ];

  List<Widget> _liveSections(Appointment a) {
    final session = context.watch<LiveLocationRepository>().session(a.id);
    final arrivedIds = {...?session?.participants.where((p) => p.arrived).map((p) => p.id)};
    return [
      Container(
        padding: const EdgeInsets.only(bottom: 32),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: GamColors.cardBorder))),
        child: Column(children: [
          DetailSection(title: '시간', titlePadding: 5, child: _TimeCard(time: a.time, countdown: true)),
          const SizedBox(height: 26),
          DetailSection(title: '장소', titlePadding: 5, child: _PlaceCard(place: a.place)),
        ]),
      ),
      const SizedBox(height: 32),
      Row(children: [
        Text('${arrivedIds.length}명 도착', style: GamText.section16),
        const SizedBox(width: 10),
        Text('총 ${a.participants.length}명', style: GamText.name15.copyWith(color: GamColors.text600.withValues(alpha: 0.6))),
      ]),
      const SizedBox(height: 40),
      ArrivalRow(participants: a.participants, arrivedIds: arrivedIds, messages: MockData.statusMessages),
    ];
  }

  Widget _timeVote(Appointment a) {
    if (a.timeOptions.isEmpty) {
      return EmptyVoteCard(title: '언제로 할까요?', subtitle: '함께 가능한 시간을 찾아보세요.', action: '시간 정하기', onTap: () => _addTime(a));
    }
    final repo = context.read<AppointmentRepository>();
    final me = repo.me.id;
    return VoteCard(
      rows: [
        for (final o in a.timeOptions)
          VoteRow(id: o.id, label: VoteOptionLabel.time(DateText.dateTime(o.value)), votes: o.voteCount, mine: o.votedBy(me)),
      ],
      hasVoted: a.timeOptions.any((o) => o.votedBy(me)),
      selected: _pickedTimes,
      onSelect: (id) => setState(() => _pickedTimes.contains(id) ? _pickedTimes.remove(id) : _pickedTimes.add(id)),
      onVote: () {
        repo.voteTimes(a.id, {..._pickedTimes});
        setState(_pickedTimes.clear);
      },
      onAdd: () => _addTime(a),
      onClose: () => _close(a, time: true),
      onRevote: () => repo.clearMyTimeVotes(a.id),
      pendingVoters: a.pendingVotersOf(a.timeOptions),
      participantCount: a.participants.length,
    );
  }

  Widget _placeVote(Appointment a) {
    if (a.placeOptions.isEmpty) {
      return EmptyVoteCard(
        title: '어디서 만날까요?',
        subtitle: '우리에게 맞는 장소를 찾아보세요.',
        action: '장소 정하기',
        onTap: () => context.push(AppRoutes.pickPlace(a.id)),
      );
    }
    final repo = context.read<AppointmentRepository>();
    final me = repo.me.id;
    return VoteCard(
      rows: [
        for (final o in a.placeOptions) VoteRow(id: o.id, label: VoteOptionLabel.place(o.value), votes: o.voteCount, mine: o.votedBy(me)),
      ],
      hasVoted: a.placeOptions.any((o) => o.votedBy(me)),
      selected: {if (_pickedPlace != null) _pickedPlace!},
      onSelect: (id) => setState(() => _pickedPlace = id),
      onVote: () {
        repo.votePlace(a.id, _pickedPlace!);
        setState(() => _pickedPlace = null);
      },
      onAdd: () => context.push(AppRoutes.pickPlace(a.id)),
      onClose: () => _close(a, time: false),
      onRevote: () => repo.clearMyPlaceVotes(a.id),
      pendingVoters: a.pendingVotersOf(a.placeOptions),
      participantCount: a.participants.length,
    );
  }

  Widget _recommendations(Appointment a) {
    const perPage = 4;
    final all = MockData.nearbyPlaces.map((e) => e.$1).toList();
    final start = (_recommendPage * perPage) % all.length;
    final shown = [for (var i = 0; i < perPage; i++) all[(start + i) % all.length]];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 7, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('추천 장소', style: GamText.section16),
              const SizedBox(height: 8),
              Text('이 약속 기준', style: GamText.caption12),
            ]),
          ),
          GestureDetector(
            onTap: () => context.push(AppRoutes.pickPlace(a.id)),
            child: Text('더보기', style: GamText.body13.copyWith(color: GamColors.text500, height: 1.3)),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      for (final (i, place) in shown.indexed)
        PlaceListRow(
          place: place,
          last: i == shown.length - 1,
          divider: GamColors.cardBorder,
          onAdd: () => _addPlace(a, place),
        ),
      const SizedBox(height: 10),
      PillButton(
        '새로고침',
        style: PillStyle.light,
        textStyle: GamText.button12,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        onTap: () => setState(() => _recommendPage++),
      ),
    ]);
  }

  Future<void> _addTime(Appointment a) async {
    final time = await showTimeSheet(context);
    if (time == null || !mounted) return;
    await context.read<AppointmentRepository>().addTimeOption(a.id, time);
  }

  Future<void> _addPlace(Appointment a, Place place) async {
    await context.read<AppointmentRepository>().addPlaceOption(a.id, place);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${place.name}을(를) 후보에 올렸어요')));
  }

  Future<void> _close(Appointment a, {required bool time}) async {
    final repo = context.read<AppointmentRepository>();
    if (time) {
      await repo.closeTimeVote(a.id);
    } else {
      await repo.closePlaceVote(a.id);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.appointment, required this.live});

  final Appointment appointment;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final status = switch (a.status) {
      AppointmentStatus.coordinating => '조율중',
      AppointmentStatus.confirmed => '확정',
      AppointmentStatus.completed => '완료',
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        PhotoCard(image: a.imageAsset, width: 122, height: 133.349),
        const SizedBox(width: 17),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 27),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(a.name, style: GamText.title20, maxLines: 2, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.rename(a.id)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    decoration: BoxDecoration(
                      color: GamColors.blueChip,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: GamColors.blueChipBorder, width: 1.3),
                    ),
                    child: Text('변경', style: GamText.meta11.copyWith(color: Colors.white)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              MemberAvatars(a.participants),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 10),
      MetaLine(leading: const GamIcon('ic_calendar_clock', size: 16), parts: [status, '${a.participants.length}명 참여']),
      const SizedBox(height: 16),
      SizedBox(
        height: 52,
        child: Row(children: [
          GestureDetector(
            onTap: () => _copyInvite(context, a),
            child: const Tooltip(message: '초대 링크 복사', child: GamIcon('ic_share', size: 22)),
          ),
          const SizedBox(width: 26),
          const GamIcon('ic_dots_vertical', size: 22),
          const Spacer(),
          if (live)
            PillButton(
              '지도에서 보기',
              icon: const GamIcon('ic_map_pin', size: 24),
              textStyle: GamText.button12.copyWith(color: GamColors.text800),
              padding: const EdgeInsets.fromLTRB(14, 13, 16, 13),
              onTap: () => openLiveMap(context, a.id),
            ),
        ]),
      ),
    ]);
  }

  static void _copyInvite(BuildContext context, Appointment a) {
    Clipboard.setData(ClipboardData(text: context.read<AppointmentRepository>().inviteLink(a)));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('초대 링크를 복사했어요')));
  }
}

/// 정해진 시간. 위치 공유 시간이면 오른쪽 아래에 남은 시간.
class _TimeCard extends StatelessWidget {
  const _TimeCard({required this.time, this.countdown = false});

  final DateTime? time;
  final bool countdown;

  @override
  Widget build(BuildContext context) {
    final t = time;
    return InfoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Text(t == null ? '아직 정하지 않았어요' : DateText.date(t), style: GamText.body14),
        ),
        if (t != null) ...[
          const SizedBox(height: 4),
          Text(DateText.time(t), style: GamText.regular13),
        ],
        if (countdown && t != null) ...[
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text('Time Left', style: GamText.regular12.copyWith(color: GamColors.text400)),
            ),
            const SizedBox(width: 8),
            Flexible(child: CountdownText(target: t, style: GamText.matrix(36, color: GamColors.text900))),
          ]),
        ],
      ]),
    );
  }
}

/// 정해진 장소 + 날씨. 날씨는 아직 목업 고정값.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place});

  final Place? place;

  @override
  Widget build(BuildContext context) {
    final p = place;
    return InfoCard(
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(p?.name ?? '아직 정하지 않았어요', style: GamText.body14),
            ),
            if (p != null) ...[
              const SizedBox(height: 4),
              Text(
                p.address.isNotEmpty ? p.address : p.description,
                style: GamText.regular13,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ]),
        ),
        if (p != null) ...[
          const SizedBox(width: 32),
          Column(children: [
            const GamIcon('ic_cloud', size: 22),
            const SizedBox(height: 3),
            Text('28°C', style: GamText.regular12.copyWith(color: GamColors.text800)),
          ]),
        ],
      ]),
    );
  }
}

/// 추천 장소·장소 정하기 목록의 한 줄: 썸네일 + 이름 + 분류 · 도보, 오른쪽 (+).
class PlaceListRow extends StatelessWidget {
  const PlaceListRow({super.key, required this.place, required this.onAdd, required this.divider, this.last = false, this.added = false});

  final Place place;
  final VoidCallback onAdd;
  final Color divider;
  final bool last;
  final bool added;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: divider))),
        child: Row(children: [
          Expanded(child: VoteOptionLabel.place(place)),
          GestureDetector(
            onTap: added ? null : onAdd,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: added ? const GamIcon('ic_check', size: 20) : const GamIcon('ic_circle_plus', size: 20),
            ),
          ),
        ]),
      );
}

class _MissingAppointment extends StatelessWidget {
  const _MissingAppointment();

  @override
  Widget build(BuildContext context) => PinkFrame(
        child: Column(children: [
          FrameTopBar(leading: GamIconButton('ic_arrow_left', tooltip: '뒤로', onTap: () => context.go(AppRoutes.home))),
          Expanded(child: Center(child: Text('약속을 찾을 수 없어요.', style: GamText.body16))),
        ]),
      );
}
