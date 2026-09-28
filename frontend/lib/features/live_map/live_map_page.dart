import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/layout.dart';
import '../../data/models/appointment.dart';
import '../../data/models/live_location.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/live_location_repository.dart';
import 'widgets/live_map_view.dart';
import 'widgets/live_text.dart';
import 'widgets/map_header.dart';
import 'widgets/map_markers.dart';
import 'widgets/participant_sheet.dart';
import 'widgets/poke_banner.dart';
import 'widgets/poke_sheet.dart';

/// 07 · 당일 지도 【핵심】 + 08 · 콕 찌르기.
/// 지도가 주인공. 출발 전·공유 꺼짐은 지도 밖 칩으로 담백하게 처리한다.
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  late final LiveLocationRepository _live = context.read<LiveLocationRepository>();
  StreamSubscription<LiveEvent>? _events;
  Timer? _clock;
  Poke? _incoming;
  bool _preview = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AppointmentRepository>().findById(widget.appointmentId);
    if (a != null && (_live.session(a.id) != null || a.isSharingLocation(DateTime.now()))) _begin(a);
  }

  /// 위치 공유 창 안에서만 실시간 구독을 켠다.
  void _begin(Appointment a) {
    _live.start(a);
    _events ??= _live.events(a.id).listen(_onEvent);
    // 콕 찌르기 쿨다운(실제 시간) 카운트다운용.
    _clock ??= Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _events?.cancel();
    _clock?.cancel();
    _live.stop(widget.appointmentId);
    super.dispose();
  }

  void _onEvent(LiveEvent e) {
    if (!mounted) return;
    switch (e) {
      case PokeReceived(:final poke):
        setState(() => _incoming = poke);
      case PokeReplied(:final from, :final reply):
        _toast('${from.name}: ${reply.label}');
      case FriendDeparted(:final who):
        _toast('${who.name}님이 출발했어요');
      case AllArrived():
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) context.pushReplacement(AppRoutes.arrival(widget.appointmentId));
        });
    }
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));
  }

  Future<void> _poke(LiveParticipant target) async {
    final message = await showPokeSheet(context, target);
    if (message == null || !mounted) return;
    // 시트를 열어둔 사이에 도착했을 수 있다.
    if (_live.session(widget.appointmentId)?.byId(target.id)?.arrived ?? false) {
      _toast('${target.participant.name}님은 이미 도착했어요');
      return;
    }
    _live.poke(widget.appointmentId, target.id, message);
    _toast('${target.participant.name}에게 "${message.label}"를 보냈어요');
  }

  void _reply(PokeReply reply) {
    final poke = _incoming!;
    _live.reply(widget.appointmentId, poke, reply);
    setState(() => _incoming = null);
    _toast('${poke.from.name}에게 "${reply.label}"라고 답했어요');
  }

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentRepository>();
    final live = context.watch<LiveLocationRepository>();
    final a = appointments.findById(widget.appointmentId);
    if (a == null) return const Scaffold(body: Center(child: Text('약속을 찾을 수 없어요.')));

    final session = live.session(a.id);
    if (session == null) {
      return _NotYet(
        appointment: a,
        onPreview: () => setState(() {
          _preview = true;
          _begin(a);
        }),
      );
    }

    final me = appointments.me.id;
    final sheetHeight = MediaQuery.sizeOf(context).height * ParticipantSheet.initialSize;
    final visible = session.participants.where((p) => p.visibleOnMap).toList();

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: LiveMapView(
            destination: session.destination,
            destinationPin: const DestinationPin(),
            bottomInset: sheetHeight,
            pins: [
              for (final p in visible) MapPin(id: p.id, position: p.position!, child: ParticipantMarker(person: p, isMe: p.id == me)),
            ],
          ),
        ),
        SafeArea(
          child: MapHeader(
            appointment: a,
            session: session,
            meId: me,
            onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.room(a.id)),
          ),
        ),
        ParticipantSheet(
          session: session,
          meId: me,
          cooldownOf: (id) => live.pokeCooldownOf(a.id, id),
          onPoke: _poke,
          onShowResult: () => context.pushReplacement(AppRoutes.arrival(a.id)),
        ),
        if (_preview) const _PreviewTag(),
        if (_incoming != null)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: PokeBanner(
                poke: _incoming!,
                subtitle: '${a.name} · 약속까지 ${LiveText.remaining(session.remaining)}',
                onReply: _reply,
                onClose: () => setState(() => _incoming = null),
              ),
            ),
          ),
      ]),
    );
  }
}

/// 위치 공유 창(약속 2시간 전) 밖에서 열었을 때.
class _NotYet extends StatelessWidget {
  const _NotYet({required this.appointment, required this.onPreview});

  final Appointment appointment;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    final time = appointment.time;
    final String subtitle;
    if (appointment.isCompleted) {
      subtitle = '이미 끝난 약속이에요.';
    } else if (time == null || !appointment.isConfirmed) {
      subtitle = '약속이 확정되면 당일에 친구들이 어디쯤 왔는지 볼 수 있어요.';
    } else {
      subtitle = '${DateText.dateTime(time.subtract(const Duration(hours: 2)))}부터 친구들이 어디쯤 왔는지 볼 수 있어요.';
    }
    return Scaffold(
      appBar: const BackAppBar(title: '당일 지도'),
      body: Padding(
        padding: kPagePadding,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          PageTitle('아직 위치 공유 전이에요', subtitle: subtitle),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
            child: const Text('위치는 약속 2시간 전부터 도착할 때까지만 공유돼요.\n평소엔 공유되지 않아요.', style: TextStyle(fontSize: 13, color: AppColors.textBody, height: 1.6)),
          ),
          // 개발 중에만: 당일이 아니어도 목업 시나리오를 돌려본다.
          if (kDebugMode && !appointment.isCompleted) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onPreview, child: const Text('목업으로 미리보기 (개발용)')),
          ],
        ]),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.textTitle.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(6)),
            child: const Text('미리보기', style: TextStyle(fontSize: 10, color: Colors.white)),
          ),
        ),
      );
}
