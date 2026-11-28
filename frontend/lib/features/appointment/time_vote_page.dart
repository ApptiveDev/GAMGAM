import 'package:flutter/material.dart';

import '../../core/theme/gam_colors.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/vote_settings.dart';
import 'widgets/time_pick_parts.dart';
import 'widgets/time_sheet.dart';
import 'widgets/vote_settings_parts.dart';

/// 투표로 정하기 페이지에서 ✓를 누르면 돌려주는 값.
class TimeVoteDraft {
  const TimeVoteDraft({required this.times, required this.settings, required this.duration});

  /// 중복 없이 이른 순.
  final List<DateTime> times;
  final VoteSettings settings;
  final VoteDuration duration;
}

/// 시간 "투표로 정하기" 페이지를 연다. 닫으면 null.
/// 초기값을 넘기면 그 상태로 시작한다(약속 수정에서 재사용).
Future<TimeVoteDraft?> openTimeVotePage(
  BuildContext context, {
  List<DateTime> initialTimes = const [],
  VoteSettings initialSettings = const VoteSettings(),
  VoteDuration initialDuration = VoteDuration.min30,
}) =>
    Navigator.of(context).push<TimeVoteDraft>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TimeVotePage(initialTimes: initialTimes, initialSettings: initialSettings, initialDuration: initialDuration),
    ));

/// 후보 시간 목록 + 항목 추가 + 투표 설정(복수선택·익명투표·선택항목 추가 허용·투표 진행 시간).
class TimeVotePage extends StatefulWidget {
  const TimeVotePage({
    super.key,
    this.initialTimes = const [],
    this.initialSettings = const VoteSettings(),
    this.initialDuration = VoteDuration.min30,
  });

  final List<DateTime> initialTimes;
  final VoteSettings initialSettings;
  final VoteDuration initialDuration;

  @override
  State<TimeVotePage> createState() => _TimeVotePageState();
}

class _Candidate {
  _Candidate(this.value) : key = UniqueKey();

  DateTime value;
  final Key key;
}

class _TimeVotePageState extends State<TimeVotePage> {
  late final _candidates = [
    for (final t in widget.initialTimes.isEmpty ? [defaultPickTime()] : widget.initialTimes) _Candidate(t),
  ];
  late var _settings = widget.initialSettings;
  late var _duration = widget.initialDuration;

  /// 펼친 줄과 그 줄에서 펼친 부분. 한 번에 한 줄만 펼친다.
  Key? _openKey;
  var _openPart = PickPart.none;

  @override
  Widget build(BuildContext context) => PinkFrame(
        background: FrameBackground.plain,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            // Figma: 상태바 아래 높이 68, 좌우 26(분홍 테두리 6 + 20).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
              child: PickHeader(
                title: '시간 정하기',
                onClose: () => Navigator.of(context).pop(),
                onDone: _candidates.isEmpty ? null : _done,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 72),
                children: [
                  if (_candidates.isNotEmpty) ...[_candidateCard(), const SizedBox(height: 10)],
                  VoteAddButton(onTap: _add),
                  const SizedBox(height: 16),
                  VoteSettingsSection(
                    settings: _settings,
                    duration: _duration,
                    onSettings: (v) => setState(() => _settings = v),
                    onDuration: (v) => setState(() => _duration = v),
                  ),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _candidateCard() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GamColors.pickCardBorder),
        ),
        child: Column(children: [
          for (final (i, c) in _candidates.indexed)
            TimeCandidateRow(
              key: c.key,
              value: c.value,
              first: i == 0,
              last: i == _candidates.length - 1,
              open: _openKey == c.key ? _openPart : PickPart.none,
              onOpen: (part) => setState(() {
                _openKey = c.key;
                _openPart = part;
              }),
              onChanged: (v) => setState(() => c.value = v),
              onDelete: () => setState(() {
                _candidates.remove(c);
                if (_openKey == c.key) _openKey = null;
              }),
            ),
        ]),
      );

  /// 새 후보는 마지막 후보 다음 날 같은 시각으로 넣고 날짜를 펼친다.
  void _add() => setState(() {
        final last = _candidates.lastOrNull?.value;
        final c = _Candidate(last == null ? defaultPickTime() : DateTime(last.year, last.month, last.day + 1, last.hour, last.minute));
        _candidates.add(c);
        _openKey = c.key;
        _openPart = PickPart.date;
      });

  void _done() {
    final times = {for (final c in _candidates) c.value}.toList()..sort();
    Navigator.of(context).pop(TimeVoteDraft(times: times, settings: _settings, duration: _duration));
  }
}
