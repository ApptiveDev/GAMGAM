import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_text.dart';
import '../../core/widgets/layout.dart';
import '../../data/mock/mock_data.dart';
import '../../data/models/appointment.dart';
import '../../data/models/live_location.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/live_location_repository.dart';
import '../../data/models/poke_note.dart';
import '../poke/poke_note_page.dart';
import '../poke/widgets/received_note.dart';
import '../poke/widgets/send_feedback.dart';
import 'widgets/live_map_view.dart';
import 'widgets/map_header.dart';
import 'widgets/map_markers.dart';
import 'widgets/participant_sheet.dart';
import 'widgets/person_card.dart';

/// 07 · 당일 지도 【핵심】 + 08 · 콕 찌르기.
/// 지도가 주인공. 출발 전·공유 꺼짐은 지도 밖 칩으로 담백하게 처리한다.
class LiveMapPage extends StatefulWidget {
  const LiveMapPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> with SingleTickerProviderStateMixin {
  late final LiveLocationRepository _live = context.read<LiveLocationRepository>();
  StreamSubscription<LiveEvent>? _events;
  Timer? _clock;
  Poke? _incoming;
  bool _preview = false;

  /// 지도에서 누른 사람. 지도 빈 곳을 누르면 풀린다.
  String? _selectedId;
  final _camera = LiveMapCamera();

  /// 상태 메시지. 저장·편집이 붙기 전까지는 약속 상세와 같은 목업을 보여준다.
  static const _statusMessages = MockData.statusMessages;

  /// 보내기를 누른 뒤 "완료하는 중" 동안 기다리는 쪽지. 막대가 다 차면 보내고, 취소하면 버린다.
  static const _undoWindow = Duration(seconds: 3);
  late final _sendProgress = AnimationController(vsync: this, duration: _undoWindow)..addStatusListener(_onSendProgress);
  (LiveParticipant, PokeNote)? _pending;

  /// 방금 보낸 쪽지. 상단 안내에서 "콕 찌르기 보기"로 다시 본다.
  PokeNote? _sent;
  bool _sentExpanded = false;
  Timer? _sentTimer;

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
    // 완료하는 중에 지도를 나가면 그대로 보낸다.
    if (_pending case (final target, final note)) _live.poke(widget.appointmentId, target.id, note);
    _sendProgress.dispose();
    _sentTimer?.cancel();
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
    final note = await showPokeNotePage(context);
    if (note == null || !mounted) return;
    // 앞에서 기다리던 쪽지가 있으면 먼저 보낸다.
    if (_pending != null) _commitSend();
    setState(() => _pending = (target, note));
    _sendProgress.forward(from: 0);
  }

  void _onSendProgress(AnimationStatus status) {
    if (status == AnimationStatus.completed && _pending != null) _commitSend();
  }

  void _cancelSend() {
    _sendProgress.stop();
    setState(() => _pending = null);
  }

  void _commitSend() {
    final (target, note) = _pending!;
    _pending = null;
    _sendProgress.stop();
    // 쪽지를 꾸미는 사이에 도착했을 수 있다.
    if (_live.session(widget.appointmentId)?.byId(target.id)?.arrived ?? false) {
      setState(() {});
      _toast('${target.participant.name}님은 이미 도착했어요');
      return;
    }
    _live.poke(widget.appointmentId, target.id, note);
    _sentTimer?.cancel();
    setState(() {
      _sent = note;
      _sentExpanded = false;
    });
    // 잠시 뒤 "콕 찌르기 보기"가 펼쳐지고, 조금 더 있다가 사라진다.
    _sentTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _sentExpanded = true);
      _sentTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _sent = null);
      });
    });
  }

  void _viewSent() {
    final note = _sent;
    if (note == null) return;
    _sentTimer?.cancel();
    setState(() => _sent = null);
    showSentNote(context, note);
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
    final selected = _selectedId == null ? null : session.byId(_selectedId!);
    final ranks = {for (final (i, p) in session.arrivalOrder.indexed) p.id: i + 1};

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(
          child: LiveMapView(
            destination: session.destination,
            destinationPin: const DestinationPin(),
            bottomInset: sheetHeight,
            camera: _camera,
            onPinTap: (id) => setState(() => _selectedId = id),
            onMapTap: () => setState(() => _selectedId = null),
            pins: [
              for (final p in visible) MapPin(id: p.id, position: p.position!, child: ParticipantMarker(person: p, selected: p.id == _selectedId)),
            ],
          ),
        ),
        SafeArea(
          child: MapHeader(
            onClose: () => context.canPop() ? context.pop() : context.go(AppRoutes.room(a.id)),
            moreMenu: {'위치 공유 설정': () => context.push(AppRoutes.locationSetting(a.id))},
            onMyLocation: () {
              final position = session.byId(me)?.position;
              position == null ? _toast('아직 내 위치를 알 수 없어요') : _camera.focus(position);
            },
            onDestination: () => _camera.focus(session.destination),
            card: selected == null
                ? null
                : PersonCard(
                    person: selected,
                    isMe: selected.id == me,
                    rank: ranks[selected.id],
                    cooldown: live.pokeCooldownOf(a.id, selected.id),
                    onPoke: () => _poke(selected),
                    statusMessage: _statusMessages[selected.id],
                  ),
          ),
        ),
        ParticipantSheet(
          session: session,
          meId: me,
          cooldownOf: (id) => live.pokeCooldownOf(a.id, id),
          onPoke: _poke,
          onShowResult: () => context.pushReplacement(AppRoutes.arrival(a.id)),
          statusMessages: _statusMessages,
        ),
        if (_preview) const _PreviewTag(),
        if (_pending != null)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.paddingOf(context).bottom,
            child: SendingBar(progress: _sendProgress, onCancel: _cancelSend),
          ),
        if (_sent != null)
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.paddingOf(context).top + 22,
            child: Center(child: SentToast(expanded: _sentExpanded, onView: _viewSent)),
          ),
        // 친구가 보낸 쪽지: 봉투가 떨어져 열린다. 누르면 닫힌다.
        if (_incoming != null)
          Positioned.fill(
            child: ReceivedNoteOverlay(key: ObjectKey(_incoming), poke: _incoming!, onClose: () => setState(() => _incoming = null)),
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
