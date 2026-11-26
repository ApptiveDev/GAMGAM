import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/gam_colors.dart';
import '../../core/theme/gam_text.dart';
import '../../core/widgets/gam/pink_frame.dart';
import '../../data/models/place.dart';
import '../../data/models/vote_settings.dart';
import 'widgets/time_pick_parts.dart';
import 'widgets/vote_settings_parts.dart';

/// 장소 투표로 정하기 페이지에서 ✓를 누르면 돌려주는 값.
class PlaceVoteDraft {
  const PlaceVoteDraft({required this.places, required this.settings, required this.duration});

  /// 이름이 겹치지 않게, 넣은 순서대로.
  final List<Place> places;
  final VoteSettings settings;
  final VoteDuration duration;
}

/// 추천 장소에서 하나 골라 돌려준다. 고르지 않으면 null.
typedef PickRecommendedPlace = Future<Place?> Function(BuildContext context);

/// 장소 "투표로 정하기" 페이지를 연다. 닫으면 null.
/// 초기값을 넘기면 그 상태로 시작한다(약속 수정에서 재사용).
Future<PlaceVoteDraft?> openPlaceVotePage(
  BuildContext context, {
  List<Place> initialPlaces = const [],
  VoteSettings initialSettings = const VoteSettings(),
  VoteDuration initialDuration = VoteDuration.min30,
  PickRecommendedPlace? onRecommend,
}) =>
    Navigator.of(context).push<PlaceVoteDraft>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => PlaceVotePage(
        initialPlaces: initialPlaces,
        initialSettings: initialSettings,
        initialDuration: initialDuration,
        onRecommend: onRecommend,
      ),
    ));

/// 후보 장소 목록 + 항목 추가 + 투표 설정 + 하단에 떠 있는 "추천 장소 보기". (Figma 1573:23153)
/// 후보 칩을 누르면 글자를 고칠 수 있고, 다 지우고 나가면 그 후보가 빠진다. (Figma 1573:23737 요소삭제)
class PlaceVotePage extends StatefulWidget {
  const PlaceVotePage({
    super.key,
    this.initialPlaces = const [],
    this.initialSettings = const VoteSettings(),
    this.initialDuration = VoteDuration.min30,
    this.onRecommend,
  });

  final List<Place> initialPlaces;
  final VoteSettings initialSettings;
  final VoteDuration initialDuration;

  /// null이면 "추천 장소 보기"를 숨긴다.
  final PickRecommendedPlace? onRecommend;

  @override
  State<PlaceVotePage> createState() => _PlaceVotePageState();
}

/// 후보 한 줄. 이름을 고치면 주소 같은 나머지 정보는 버리고 이름만 남긴다.
class _Candidate {
  _Candidate(this.place)
      : text = TextEditingController(text: place?.name ?? ''),
        focus = FocusNode(),
        key = UniqueKey();

  Place? place;
  final TextEditingController text;
  final FocusNode focus;
  final Key key;

  String get name => text.text.trim();

  Place? get value {
    if (name.isEmpty) return null;
    final p = place;
    return p != null && p.name == name ? p : Place(name: name);
  }

  void dispose() {
    text.dispose();
    focus.dispose();
  }
}

class _PlaceVotePageState extends State<PlaceVotePage> {
  late final List<_Candidate> _candidates = [
    for (final p in widget.initialPlaces) _Candidate(p),
  ];
  late var _settings = widget.initialSettings;
  late var _duration = widget.initialDuration;

  @override
  void initState() {
    super.initState();
    // 후보가 없으면 빈 줄 하나를 열어 바로 쓰게 한다.
    if (_candidates.isEmpty) _addEmpty();
  }

  @override
  void dispose() {
    for (final c in _candidates) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canDone => _candidates.any((c) => c.name.isNotEmpty);

  @override
  Widget build(BuildContext context) => PinkFrame(
        background: FrameBackground.plain,
        child: SafeArea(
          bottom: false,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
              child: PickHeader(
                title: '장소 정하기',
                onClose: () => Navigator.of(context).pop(),
                onDone: _canDone ? _done : null,
              ),
            ),
            Expanded(
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (_candidates.isNotEmpty) ...[_candidateCard(), const SizedBox(height: 10)],
                    VoteAddButton(onTap: () => setState(_addEmpty)),
                    const SizedBox(height: 16),
                    VoteSettingsSection(
                      settings: _settings,
                      duration: _duration,
                      onSettings: (v) => setState(() => _settings = v),
                      onDuration: (v) => setState(() => _duration = v),
                    ),
                  ],
                ),
                if (widget.onRecommend != null)
                  Positioned(left: 0, right: 0, bottom: 0, child: _RecommendDock(onTap: _recommend)),
              ]),
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
            _CandidateRow(
              key: c.key,
              candidate: c,
              first: i == 0,
              last: i == _candidates.length - 1,
              onChanged: () => setState(() {}),
              onLeave: () => _leave(c),
            ),
        ]),
      );

  void _addEmpty() {
    final c = _Candidate(null);
    _candidates.add(c);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) c.focus.requestFocus();
    });
  }

  /// 글자를 다 지운 채 줄을 벗어나면 그 후보를 뺀다. 마지막 한 줄은 남겨 둔다.
  void _leave(_Candidate c) {
    if (c.name.isNotEmpty || _candidates.length < 2 || !_candidates.contains(c)) return;
    setState(() => _candidates.remove(c));
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  Future<void> _recommend() async {
    FocusScope.of(context).unfocus();
    final place = await widget.onRecommend!(context);
    if (place == null || !mounted) return;
    if (_candidates.any((c) => c.name == place.name)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${place.name}은(는) 이미 후보에 있어요')));
      return;
    }
    setState(() {
      // 비어 있는 줄이 있으면 그 자리에 넣는다.
      final empty = _candidates.where((c) => c.name.isEmpty).firstOrNull;
      if (empty != null) {
        empty.place = place;
        empty.text.text = place.name;
      } else {
        _candidates.add(_Candidate(place));
      }
    });
  }

  void _done() {
    final seen = <String>{};
    final places = [
      for (final c in _candidates)
        if (c.value case final p? when seen.add(p.name)) p,
    ];
    Navigator.of(context).pop(PlaceVoteDraft(places: places, settings: _settings, duration: _duration));
  }
}

TextStyle _medium(double size, [Color color = GamColors.text900]) => GamText.body16.copyWith(fontSize: size, color: color);

/// 후보 한 줄. 평소엔 회색 칩, 고치는 중엔 칩 없이 글자만 보인다.
class _CandidateRow extends StatefulWidget {
  const _CandidateRow({
    super.key,
    required this.candidate,
    required this.first,
    required this.last,
    required this.onChanged,
    required this.onLeave,
  });

  final _Candidate candidate;
  final bool first;
  final bool last;
  final VoidCallback onChanged;
  final VoidCallback onLeave;

  @override
  State<_CandidateRow> createState() => _CandidateRowState();
}

class _CandidateRowState extends State<_CandidateRow> {
  _Candidate get c => widget.candidate;

  /// 칩을 눌러 고치기 시작했는데 아직 글자 칸에 포커스가 안 간 사이.
  var _opening = false;

  @override
  void initState() {
    super.initState();
    c.focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    c.focus.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (c.focus.hasFocus) _opening = false;
    if (!c.focus.hasFocus && !_opening) widget.onLeave();
    if (mounted) setState(() {});
  }

  bool get _editing => _opening || c.focus.hasFocus || c.name.isEmpty;

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        padding: EdgeInsets.fromLTRB(editing ? 6 : 0, widget.first ? 10 : 8, 6, widget.last ? 10 : 8),
        decoration: BoxDecoration(
          border: widget.last ? null : const Border(bottom: BorderSide(color: GamColors.pickRowLine)),
        ),
        child: SizedBox(
          height: 35,
          child: Row(children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: editing ? _field() : _chip(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지도는 준비 중이에요'))),
              child: Text('지도', style: _medium(13, editing ? GamColors.text900 : GamColors.text400)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _chip() => Semantics(
        button: true,
        hint: '이름 고치기',
        child: GestureDetector(
          onTap: () {
            // 글자 칸이 그려진 뒤에 포커스를 준다.
            setState(() => _opening = true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              c.text.selection = TextSelection.collapsed(offset: c.text.text.length);
              c.focus.requestFocus();
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: GamColors.pickPage, borderRadius: BorderRadius.circular(31)),
            child: Text(c.name, style: _medium(15), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );

  Widget _field() => TextField(
        controller: c.text,
        focusNode: c.focus,
        style: _medium(15),
        textInputAction: TextInputAction.done,
        onChanged: (_) => widget.onChanged(),
        onSubmitted: (_) => c.focus.unfocus(),
        onTapOutside: (_) => c.focus.unfocus(),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: '장소 이름',
          hintStyle: _medium(15, GamColors.pickFaint),
        ),
      );
}

/// 목록 위로 흐려지는 바닥과 그 위에 떠 있는 "추천 장소 보기". 스크롤해도 제자리에 있다.
class _RecommendDock extends StatelessWidget {
  const _RecommendDock({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 213,
        child: Stack(fit: StackFit.expand, children: [
          IgnorePointer(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.479, 0.896],
                      colors: [GamColors.pickPage.withValues(alpha: 0), GamColors.pickPage.withValues(alpha: 0.9)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 26,
            bottom: 26 + MediaQuery.paddingOf(context).bottom,
            child: RecommendPlaceButton(onTap: onTap),
          ),
        ]),
      );
}

/// 분홍빛 "추천 장소 보기" 버튼. 오른쪽 위 모서리만 덜 둥글다.
class RecommendPlaceButton extends StatelessWidget {
  const RecommendPlaceButton({super.key, required this.onTap, this.label = '추천 장소 보기'});

  final VoidCallback onTap;
  final String label;

  static const _shape = BorderRadius.only(
    topLeft: Radius.circular(27),
    topRight: Radius.circular(9),
    bottomLeft: Radius.circular(27),
    bottomRight: Radius.circular(27),
  );

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: _shape,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 2)],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: _shape,
                border: Border.all(color: const Color(0xFFE9A5EE), width: 1.3),
                gradient: const LinearGradient(
                  begin: Alignment(-0.45, -0.9),
                  end: Alignment(0.45, 0.9),
                  stops: [0.175, 1],
                  colors: [Color(0x72F147FF), Color(0x00F8AFFE)],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: const BoxDecoration(
                  borderRadius: _shape,
                  gradient: RadialGradient(
                    center: Alignment(-0.2, -0.15),
                    radius: 1.9,
                    stops: [0.12, 0.34, 0.56, 1],
                    colors: [Color(0xADED24FF), Color(0x82F047FF), Color(0x57F26AFF), Color(0x00F7AFFE)],
                  ),
                ),
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.346, 0.846],
                    colors: [GamColors.text900, Color(0xFF6F4A7B)],
                  ).createShader(bounds),
                  child: Text(label, style: _medium(13).copyWith(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
      );
}
