import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/gam/gam_icon.dart';

/// 시간 정하기 화면들이 함께 쓰는 조각: 위 머리줄, 날짜·시간 칩 줄, 달력, 시간 휠, 체크 동그라미.
/// 치수·색은 Figma "시간 정하기"(1573:23950 등)·"바로정하기(시간)"(1589:25636 등) 값이다.

TextStyle _medium(double size, [Color color = GamColors.text900]) => GamText.body16.copyWith(fontSize: size, color: color);

/// 위 머리줄: 왼쪽 X, 가운데 제목, 오른쪽 ✓.
/// 투표로 정하기 페이지는 35 단색 버튼, 바로 정하기 시트([sheet])는 41 그라데이션 버튼이다.
class PickHeader extends StatelessWidget {
  const PickHeader({super.key, required this.title, required this.onClose, required this.onDone, this.sheet = false});

  final String title;
  final VoidCallback onClose;

  /// null이면 ✓를 흐리게 두고 누를 수 없다.
  final VoidCallback? onDone;
  final bool sheet;

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _RoundButton(
          tooltip: '닫기',
          size: sheet ? 41 : 35,
          decoration: sheet
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEBEBEB), Colors.white],
                  ),
                )
              : const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          onTap: onClose,
          child: sheet ? const GamIcon('ic_sheet_x', size: 28) : const GamIcon('ic_pick_x', size: 24),
        ),
        Text(title, style: _medium(16)),
        Opacity(
          opacity: onDone == null ? 0.5 : 1,
          child: _RoundButton(
            tooltip: '완료',
            size: sheet ? 41 : 35,
            // 누를 수 있으면 X와 같은 흰 바탕·진한 체크, 못 누르면 Figma 회색 그대로. (시트·페이지 공통)
            decoration: sheet
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: onDone == null ? const Color(0xFFC8CAD6) : Colors.white),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: onDone == null
                          ? const [Color(0xFFB9BAC1), Color(0xFFCDCDD2)]
                          : const [Color(0xFFEBEBEB), Colors.white],
                    ),
                  )
                : BoxDecoration(shape: BoxShape.circle, color: onDone == null ? GamColors.doneButton : Colors.white),
            onTap: onDone,
            child: sheet
                ? GamIcon('ic_sheet_check', size: 28, color: onDone == null ? null : GamColors.text900)
                : GamIcon('ic_pick_check', size: 24, color: onDone == null ? null : GamColors.text900),
          ),
        ),
      ]);
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.child, required this.size, required this.decoration, required this.onTap, required this.tooltip});

  final Widget child;
  final double size;
  final BoxDecoration decoration;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(width: size, height: size, decoration: decoration, child: Center(child: child)),
        ),
      );
}

/// 후보 한 줄에서 지금 펼친 부분.
enum PickPart { none, date, time }

/// 후보 한 줄: [11월 3일 (화)] [오후 8:00] 칩. 칩을 누르면 그 아래에 달력이나 시간 휠이 펼쳐진다.
/// 흰 카드 안에 여러 줄을 쌓으면 줄 사이에 선이 들어간다. 마지막 줄([last])은 선이 없다.
class TimeCandidateRow extends StatelessWidget {
  const TimeCandidateRow({
    super.key,
    required this.value,
    required this.open,
    required this.onOpen,
    required this.onChanged,
    this.onDelete,
    this.first = true,
    this.last = true,
    this.activeFill = GamColors.pickPage,
    this.trailingPadding = 0,
  });

  final DateTime value;
  final PickPart open;

  /// 칩을 누르면 그 부분을 펼친다. 이미 펼친 칩을 다시 누르면 [PickPart.none].
  final ValueChanged<PickPart> onOpen;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onDelete;
  final bool first;
  final bool last;

  /// 펼친 칩 바탕. 페이지는 회색 그대로, 바로 정하기 시트는 연파랑.
  final Color activeFill;
  final double trailingPadding;

  static const _line = BorderSide(color: GamColors.pickRowLine);

  @override
  Widget build(BuildContext context) {
    final expanded = open != PickPart.none;
    return Padding(
      padding: EdgeInsets.only(left: 10, right: 10 + trailingPadding),
      child: Column(children: [
        Container(
          padding: EdgeInsets.only(top: first ? 10 : 8, bottom: last && !expanded ? 10 : 8),
          decoration: BoxDecoration(border: last && !expanded ? null : const Border(bottom: _line)),
          child: Row(children: [
            // 좁은 화면에서는 넘치지 않게 칩 둘을 함께 줄인다.
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(children: [
                    PickChip(
                      DateText.date(value),
                      active: open == PickPart.date,
                      activeFill: activeFill,
                      onTap: () => onOpen(open == PickPart.date ? PickPart.none : PickPart.date),
                    ),
                    const SizedBox(width: 8),
                    PickChip(
                      DateText.time(value),
                      active: open == PickPart.time,
                      activeFill: activeFill,
                      horizontal: 10,
                      onTap: () => onOpen(open == PickPart.time ? PickPart.none : PickPart.time),
                    ),
                  ]),
                ),
              ),
            ),
            if (onDelete != null)
              Tooltip(
                message: '후보 삭제',
                child: GestureDetector(
                  onTap: onDelete,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(padding: EdgeInsets.all(6), child: GamIcon('ic_trash', size: 20)),
                ),
              ),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: !expanded
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  decoration: BoxDecoration(border: last ? null : const Border(bottom: _line)),
                  child: open == PickPart.date
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: PickCalendar(
                            selected: value,
                            onChanged: (d) => onChanged(DateTime(d.year, d.month, d.day, value.hour, value.minute)),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 32),
                          child: TimeWheel(value: value, onChanged: onChanged),
                        ),
                ),
        ),
      ]),
    );
  }
}

/// 날짜·시간 칩. 펼친 칩은 글자가 파랗다.
class PickChip extends StatelessWidget {
  const PickChip(
    this.label, {
    super.key,
    required this.active,
    required this.onTap,
    this.activeFill = GamColors.pickPage,
    this.horizontal = 12,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeFill;
  final double horizontal;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 10),
          decoration: BoxDecoration(color: active ? activeFill : GamColors.pickPage, borderRadius: BorderRadius.circular(31)),
          child: Text(label, style: _medium(15, active ? GamColors.pickBlue : GamColors.text900)),
        ),
      );
}

/// 한 달 달력. 오늘 이전 날짜는 고를 수 없다. 주는 일요일부터.
class PickCalendar extends StatefulWidget {
  const PickCalendar({super.key, required this.selected, required this.onChanged});

  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  @override
  State<PickCalendar> createState() => _PickCalendarState();
}

class _PickCalendarState extends State<PickCalendar> {
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  static const _gap = 2.0;
  static const _rowGap = 3.84;

  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  /// "2026년 11월 >"를 누르면 날짜 대신 년·월 휠을 보여준다(일반 캘린더 앱처럼).
  var _pickingMonth = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstMonth = DateTime(now.year, now.month);
    final canGoBack = _month.isAfter(firstMonth);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final lead = _month.weekday % 7; // 일요일 = 0
    final cells = <DateTime?>[for (var i = 0; i < lead; i++) null, for (var d = 1; d <= days; d++) DateTime(_month.year, _month.month, d)];
    final weeks = [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, (i + 7).clamp(0, cells.length))];

    return LayoutBuilder(builder: (context, box) {
      final cell = (box.maxWidth - _gap * 6) / 7;
      Widget row(List<Widget> children) => Row(children: [
            for (final (i, c) in children.indexed) ...[if (i > 0) const SizedBox(width: _gap), SizedBox(width: cell, child: c)],
          ]);
      return Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(children: [
            Semantics(
              button: true,
              label: '년·월 고르기',
              child: GestureDetector(
                onTap: () => setState(() => _pickingMonth = !_pickingMonth),
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Text('${_month.year}년 ${_month.month}월', style: _medium(13, _pickingMonth ? GamColors.pickBlue : GamColors.text900)),
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _pickingMonth ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: const GamIcon('ic_month_label_chevron', size: 16),
                  ),
                ]),
              ),
            ),
            const Spacer(),
            if (!_pickingMonth) ...[
              // Figma의 이전 달 화살표는 오른쪽 화살표를 뒤집은 것이다.
              _MonthArrow(icon: 'ic_month_prev', flip: true, tooltip: '이전 달', onTap: canGoBack ? () => _shift(-1) : null),
              const SizedBox(width: 10),
              _MonthArrow(icon: 'ic_month_next', tooltip: '다음 달', onTap: () => _shift(1)),
            ],
          ]),
        ),
        const SizedBox(height: 20),
        if (_pickingMonth)
          _MonthWheel(month: _month, first: firstMonth, onChanged: (m) => setState(() => _month = m))
        else ...[
          row([for (final w in _weekdays) Center(child: Text(w, style: _medium(11, GamColors.pickFaint)))]),
          for (final week in weeks) ...[
            const SizedBox(height: _rowGap),
            row([
              for (final day in week)
                day == null
                    ? SizedBox(height: cell)
                    : _DayCell(
                        day: day,
                        size: cell,
                        selected: DateUtils.isSameDay(day, widget.selected),
                        past: day.isBefore(today),
                        onTap: () => widget.onChanged(day),
                      ),
            ]),
          ],
        ],
      ]);
    });
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.tooltip, required this.onTap, this.flip = false});

  final String icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool flip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: onTap == null ? 0.3 : 1,
            child: Transform.flip(flipX: flip, child: GamIcon(icon, size: 26)),
          ),
        ),
      );
}

/// 년·월 휠. 이번 달보다 앞을 고르면 이번 달로 되돌린다.
class _MonthWheel extends StatefulWidget {
  const _MonthWheel({required this.month, required this.first, required this.onChanged});

  final DateTime month;
  final DateTime first;
  final ValueChanged<DateTime> onChanged;

  @override
  State<_MonthWheel> createState() => _MonthWheelState();
}

class _MonthWheelState extends State<_MonthWheel> {
  static const _years = 6;

  late int _year = widget.month.year;
  late int _monthNo = widget.month.month;
  late final _yearCtrl = FixedExtentScrollController(initialItem: _year - widget.first.year);
  late final _monthCtrl = FixedExtentScrollController(initialItem: _monthNo - 1);

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    var picked = DateTime(_year, _monthNo);
    if (picked.isBefore(widget.first)) {
      picked = widget.first;
      _monthNo = picked.month;
      _monthCtrl.animateToItem(_monthNo - 1, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    }
    widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _wheelHeight,
        child: Row(children: [
          Expanded(
            child: _flatWheel(
              controller: _yearCtrl,
              labels: [for (var y = 0; y < _years; y++) '${widget.first.year + y}년'],
              selected: _year - widget.first.year,
              size: 20,
              looping: false,
              onSelected: (i) {
                setState(() => _year = widget.first.year + i);
                _emit();
              },
            ),
          ),
          Expanded(
            child: _flatWheel(
              controller: _monthCtrl,
              labels: [for (var m = 1; m <= 12; m++) '$m월'],
              selected: _monthNo - 1,
              size: 20,
              onSelected: (i) {
                setState(() => _monthNo = i % 12 + 1);
                _emit();
              },
            ),
          ),
        ]),
      );
}

/// Figma 휠: 줄 높이 32, 줄 사이 23.
const _wheelExtent = 55.0;
const _wheelHeight = 32 * 3 + 23 * 2.0;

/// 평평한 휠. 가운데 줄은 진하고 위아래 줄은 흐리다. [onSelected]는 looping이면 날 인덱스(음수·큰 수)를 받는다.
Widget _flatWheel({
  required FixedExtentScrollController controller,
  required List<String> labels,
  required double size,
  required int selected,
  required ValueChanged<int> onSelected,
  bool looping = true,
}) =>
    CupertinoPicker(
      scrollController: controller,
      itemExtent: _wheelExtent,
      looping: looping,
      diameterRatio: 100,
      squeeze: 1,
      selectionOverlay: const SizedBox(),
      onSelectedItemChanged: onSelected,
      children: [
        for (final (i, label) in labels.indexed)
          Center(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: _medium(size, i == selected ? GamColors.text900 : GamColors.pickFaint),
            ),
          ),
      ],
    );

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.size, required this.selected, required this.past, required this.onTap});

  final DateTime day;
  final double size;
  final bool selected;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: past ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: size,
          decoration: BoxDecoration(color: selected ? GamColors.pickDay : null, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '${day.day}',
              style: _medium(13.7, selected ? Colors.white : (past ? GamColors.pickFaint : GamColors.text900)),
            ),
          ),
        ),
      );
}

/// 오전/오후 · 시 · 분(5분 단위)을 돌려서 고르는 휠. 가운데 줄이 고른 값이다.
/// Figma: 줄 높이 32, 줄 사이 23. 오전/오후는 왼쪽, 시·:·분은 오른쪽에 25 간격으로 붙는다.
class TimeWheel extends StatefulWidget {
  const TimeWheel({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  late bool _pm = widget.value.hour >= 12;
  late int _hour = widget.value.hour % 12 == 0 ? 12 : widget.value.hour % 12; // 1~12
  late int _minute = (widget.value.minute / 5).round().clamp(0, 11) * 5;

  late final _periodCtrl = FixedExtentScrollController(initialItem: _pm ? 1 : 0);
  late final _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
  late final _minuteCtrl = FixedExtentScrollController(initialItem: _minute ~/ 5);

  @override
  void dispose() {
    _periodCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final v = widget.value;
    widget.onChanged(DateTime(v.year, v.month, v.day, _hour % 12 + (_pm ? 12 : 0), _minute));
  }

  /// 시 휠이 마지막으로 가리킨 날 인덱스(looping이라 음수·큰 수도 온다).
  late int _hourRaw = _hour - 1;

  /// 시를 돌리다 11↔12를 지나면 오전/오후를 뒤집는다(시계처럼 11:55 → 12:00이 오전 → 오후).
  void _onHour(int raw) {
    var pm = _pm;
    final step = raw > _hourRaw ? 1 : -1;
    for (var r = _hourRaw; r != raw; r += step) {
      final from = r % 12, to = (r + step) % 12; // 0 = 1시, 11 = 12시
      // 12시 ↔ 1시를 넘을 때만 오전/오후가 바뀐다.
      if ((from == 11 && to == 0) || (from == 0 && to == 11)) pm = !pm;
    }
    _hourRaw = raw;
    setState(() {
      _hour = raw % 12 + 1;
      if (pm != _pm) {
        _pm = pm;
        _periodCtrl.animateToItem(pm ? 1 : 0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _wheelHeight,
        child: Row(children: [
          SizedBox(
            width: 39,
            child: _flatWheel(
              controller: _periodCtrl,
              labels: const ['오전', '오후'],
              size: 20,
              selected: _pm ? 1 : 0,
              looping: false,
              onSelected: (i) {
                setState(() => _pm = i == 1);
                _emit();
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 30,
            child: _flatWheel(
              controller: _hourCtrl,
              labels: [for (var h = 1; h <= 12; h++) '$h'],
              size: 24,
              selected: _hour - 1,
              onSelected: _onHour,
            ),
          ),
          const SizedBox(width: 25),
          // 가운데 줄만 진한 ":" — 위아래 줄에도 흐린 ":"가 있다.
          SizedBox(
            width: 30,
            child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              for (final c in [GamColors.pickFaint, GamColors.text900, GamColors.pickFaint])
                SizedBox(height: 32, child: Center(child: Text(':', style: _medium(24, c)))),
            ]),
          ),
          const SizedBox(width: 25),
          SizedBox(
            width: 30,
            child: _flatWheel(
              controller: _minuteCtrl,
              labels: [for (var m = 0; m < 60; m += 5) m.toString().padLeft(2, '0')],
              size: 24,
              selected: _minute ~/ 5,
              onSelected: (i) {
                setState(() => _minute = i % 12 * 5);
                _emit();
              },
            ),
          ),
        ]),
      );
}

/// 설정 줄 오른쪽 체크 동그라미. Figma 아이콘 그대로(22, 투표 진행 시간 목록은 24).
class PickCheck extends StatelessWidget {
  const PickCheck({super.key, required this.on, this.size = 22});

  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    final suffix = size == 24 ? '_24' : '';
    return GamIcon(on ? 'ic_check_circle_on$suffix' : 'ic_check_circle_off$suffix', size: size);
  }
}

/// 시트 맨 위 손잡이(30×3).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Center(child: SvgPicture.asset('assets/figma/ic_sheet_handle.svg', width: 32, height: 3));
}
