import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/gam_icon.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/models/place.dart';
import 'time_pick_parts.dart';
import 'vote_card.dart';

/// 장소 "바로 정하기" 시트. 위 칸에 직접 쓰거나 추천 장소의 ⊕를 눌러 고른다. (Figma 1607:26400 · 1607:27388)
/// [initial]을 주면 그 장소로 시작한다(약속 수정에서 재사용). ✓를 누르면 고른 장소, 닫으면 null.
/// 지도·내 위치 설정은 아직 붙이지 않았다.
Future<Place?> showDecidePlaceSheet(
  BuildContext context, {
  Place? initial,
  String title = '장소 정하기',
  VoidCallback? onMore,
}) =>
    showModalBottomSheet<Place>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GamColors.pickSheet,
      barrierColor: GamColors.sheetBarrier,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
      builder: (sheet) => _DecidePlaceSheet(initial: initial, title: title, onMore: onMore),
    );

TextStyle _medium(double size, [Color color = GamColors.text900]) => GamText.body16.copyWith(fontSize: size, color: color);

class _DecidePlaceSheet extends StatefulWidget {
  const _DecidePlaceSheet({required this.initial, required this.title, required this.onMore});

  final Place? initial;
  final String title;
  final VoidCallback? onMore;

  @override
  State<_DecidePlaceSheet> createState() => _DecidePlaceSheetState();
}

class _DecidePlaceSheetState extends State<_DecidePlaceSheet> {
  static const _perPage = 4;

  /// 추천 목록에서 고른 장소. 직접 쓴 이름이면 null.
  late Place? _picked = widget.initial;
  late final _typed = TextEditingController(text: widget.initial == null ? '' : widget.initial!.name);
  var _page = 0;

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  List<Place> get _recommended {
    final all = MockData.nearbyPlaces.map((e) => e.$1).toList();
    final start = (_page * _perPage) % all.length;
    return [for (var i = 0; i < _perPage; i++) all[(start + i) % all.length]];
  }

  Place? get _result {
    if (_picked != null) return _picked;
    final name = _typed.text.trim();
    return name.isEmpty ? null : Place(name: name);
  }

  void _toggle(Place place) => setState(() {
        if (_picked?.name == place.name) {
          _picked = null;
          _typed.clear();
        } else {
          _picked = place;
          _typed.text = place.name;
        }
      });

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: PickHeader(
                  sheet: true,
                  title: widget.title,
                  onClose: () => Navigator.of(context).pop(),
                  onDone: result == null ? null : () => Navigator.of(context).pop(result),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  _field(),
                  const SizedBox(height: 26),
                  _recommendHeader(),
                  const SizedBox(height: 20),
                  for (final (i, place) in _recommended.indexed)
                    _RecommendRow(
                      place: place,
                      picked: _picked?.name == place.name,
                      last: i == _perPage - 1,
                      onTap: () => _toggle(place),
                    ),
                  const SizedBox(height: 10),
                  _RefreshButton(onTap: () => setState(() => _page++)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  /// 흰 알약 칸: 고른 장소는 회색 칩, 아니면 직접 쓰는 칸. 오른쪽은 "지도".
  Widget _field() => Container(
        height: 54,
        padding: const EdgeInsets.only(left: 16, right: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(40)),
        child: Row(children: [
          Expanded(
            child: _picked != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => _toggle(_picked!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(color: GamColors.pickPage, borderRadius: BorderRadius.circular(31)),
                        child: Text(_picked!.name, style: _medium(15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  )
                : TextField(
                    controller: _typed,
                    onChanged: (_) => setState(() {}),
                    style: _medium(15),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: '장소',
                      hintStyle: _medium(15, GamColors.pickFaint),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            // 지도는 아직 붙이지 않았다.
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('지도에서 고르기는 준비 중이에요'))),
            child: Text('지도', style: _medium(13, _picked == null ? GamColors.text900 : GamColors.text400)),
          ),
        ]),
      );

  Widget _recommendHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 7, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Text('추천 장소', style: GamText.section16)),
          if (widget.onMore != null)
            GestureDetector(
              onTap: widget.onMore,
              behavior: HitTestBehavior.opaque,
              child: Row(children: [
                Text('자세히', style: _medium(13, GamColors.text500).copyWith(height: 1.3)),
                const GamIcon('ic_chevron_right_20', size: 20),
              ]),
            ),
        ]),
      );
}

class _RecommendRow extends StatelessWidget {
  const _RecommendRow({required this.place, required this.picked, required this.last, required this.onTap});

  final Place place;
  final bool picked;
  final bool last;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: GamColors.cardBorder))),
          child: Row(children: [
            Expanded(child: VoteOptionLabel.place(place)),
            Semantics(
              button: true,
              selected: picked,
              label: picked ? '${place.name} 선택 취소' : '${place.name} 고르기',
              child: GamIcon(picked ? 'ic_circle_plus_on' : 'ic_circle_plus', size: 20),
            ),
          ]),
        ),
      );
}

/// Figma: 흰 바탕, #CDCDCD 1.3 테두리, 둥근 25, SemiBold 12.
class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: GamColors.photoOutline, width: 1.3),
          ),
          child: Text('새로고침', style: GamText.button12),
        ),
      );
}
