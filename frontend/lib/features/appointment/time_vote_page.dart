import 'package:flutter/material.dart';

import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/gam_icon.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/vote_settings.dart';
import 'widgets/time_pick_parts.dart';
import 'widgets/time_sheet.dart';

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
/// Figma의 "선물 추가하기"는 팀 결정으로 뺐다.
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
                  _AddButton(onTap: _add),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    child: Column(children: [
                      _OptionRow(label: '복수선택', on: _settings.multiple, onTap: () => _set(_settings.copyWith(multiple: !_settings.multiple))),
                      const SizedBox(height: 14),
                      _OptionRow(label: '익명투표', on: _settings.anonymous, onTap: () => _set(_settings.copyWith(anonymous: !_settings.anonymous))),
                      const SizedBox(height: 14),
                      _OptionRow(label: '선택항목 추가 허용', on: _settings.allowAdd, onTap: () => _set(_settings.copyWith(allowAdd: !_settings.allowAdd))),
                      const SizedBox(height: 14),
                      _DurationRow(duration: _duration, onTap: _pickDuration),
                    ]),
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

  void _set(VoteSettings settings) => setState(() => _settings = settings);

  /// 새 후보는 마지막 후보 다음 날 같은 시각으로 넣고 날짜를 펼친다.
  void _add() => setState(() {
        final last = _candidates.lastOrNull?.value;
        final c = _Candidate(last == null ? defaultPickTime() : DateTime(last.year, last.month, last.day + 1, last.hour, last.minute));
        _candidates.add(c);
        _openKey = c.key;
        _openPart = PickPart.date;
      });

  Future<void> _pickDuration() async {
    final picked = await showModalBottomSheet<VoteDuration>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: GamColors.sheetBarrier,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => _DurationSheet(selected: _duration),
    );
    if (picked != null) setState(() => _duration = picked);
  }

  void _done() {
    final times = {for (final c in _candidates) c.value}.toList()..sort();
    Navigator.of(context).pop(TimeVoteDraft(times: times, settings: _settings, duration: _duration));
  }
}

TextStyle _medium(double size, [Color color = GamColors.text900]) => GamText.body16.copyWith(fontSize: size, color: color);

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const StadiumBorder(side: BorderSide(color: GamColors.pickCardBorder)),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: SizedBox(
            height: 47,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const GamIcon('ic_plus_26', size: 26),
              const SizedBox(width: 8),
              Text('항목 추가', style: _medium(14, GamColors.text500)),
            ]),
          ),
        ),
      );
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        toggled: on,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(children: [
            Expanded(child: Text(label, style: _medium(14))),
            PickCheck(on: on),
          ]),
        ),
      );
}

class _DurationRow extends StatelessWidget {
  const _DurationRow({required this.duration, required this.onTap});

  final VoteDuration duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Expanded(child: Text('투표 진행 시간', style: _medium(14))),
          Text(duration.label, style: _medium(14).copyWith(fontWeight: FontWeight.w400)),
          const SizedBox(width: 3),
          const GamIcon('ic_chevron_right_22', size: 22),
        ]),
      );
}

/// "투표 진행 시간" 목록 시트. 고르면 바로 닫힌다. (Figma 1573:23910)
class _DurationSheet extends StatelessWidget {
  const _DurationSheet({required this.selected});

  final VoteDuration selected;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Text('투표 진행 시간', style: _medium(15)),
            const SizedBox(height: 18),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: GamColors.pickPage, borderRadius: BorderRadius.circular(19)),
                child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
                  for (final (i, d) in VoteDuration.values.indexed)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(d),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 53,
                        decoration: BoxDecoration(
                          border: i == VoteDuration.values.length - 1
                              ? null
                              : const Border(bottom: BorderSide(color: GamColors.pickOptionLine)),
                        ),
                        child: Row(children: [
                          Expanded(child: Text(d.label, style: _medium(15))),
                          PickCheck(on: d == selected, size: 24),
                        ]),
                      ),
                    ),
                ]),
              ),
            ),
          ]),
        ),
      );
}
