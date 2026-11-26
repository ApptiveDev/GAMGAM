import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/utils/date_text.dart';
import '../../../core/widgets/gam/gam_icon.dart';

/// 시간 정하기 화면들이 함께 쓰는 조각: 위 머리줄, 날짜·시간 칩 줄, 달력, 시간 휠, 체크 동그라미.

/// 시트·페이지 맨 위: 왼쪽 X, 가운데 제목, 오른쪽 ✓.
class PickHeader extends StatelessWidget {
  const PickHeader({super.key, required this.title, required this.onClose, required this.onDone});

  final String title;
  final VoidCallback onClose;

  /// null이면 ✓를 흐리게 두고 누를 수 없다.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 56,
        child: Row(children: [
          _RoundButton(
            tooltip: '닫기',
            color: Colors.white,
            onTap: onClose,
            child: const GamIcon('ic_x', size: 20, color: GamColors.text900),
          ),
          Expanded(child: Text(title, textAlign: TextAlign.center, style: GamText.section16.copyWith(fontSize: 17))),
          Opacity(
            opacity: onDone == null ? 0.5 : 1,
            child: _RoundButton(
              tooltip: '완료',
              color: GamColors.doneButton,
              onTap: onDone,
              child: const GamIcon('ic_check', size: 20, color: Colors.white),
            ),
          ),
        ]),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.child, required this.color, required this.onTap, required this.tooltip});

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(child: child),
          ),
        ),
      );
}

/// 후보 한 줄에서 지금 펼친 부분.
enum PickPart { none, date, time }

/// 후보 한 줄: [11월 3일 (화)] [오후 8:00] 칩. 칩을 누르면 그 아래에 달력이나 시간 휠이 펼쳐진다.
class TimeCandidateRow extends StatelessWidget {
  const TimeCandidateRow({
    super.key,
    required this.value,
    required this.open,
    required this.onOpen,
    required this.onChanged,
    this.onDelete,
  });

  final DateTime value;
  final PickPart open;

  /// 칩을 누르면 그 부분을 펼친다. 이미 펼친 칩을 다시 누르면 [PickPart.none].
  final ValueChanged<PickPart> onOpen;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          child: Row(children: [
            PickChip(
              DateText.date(value),
              active: open == PickPart.date,
              onTap: () => onOpen(open == PickPart.date ? PickPart.none : PickPart.date),
            ),
            const SizedBox(width: 6),
            PickChip(
              DateText.time(value),
              active: open == PickPart.time,
              onTap: () => onOpen(open == PickPart.time ? PickPart.none : PickPart.time),
            ),
            const Spacer(),
            if (onDelete != null)
              IconButton(
                tooltip: '후보 삭제',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, size: 22, color: GamColors.photoOutline),
              ),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: switch (open) {
            PickPart.none => const SizedBox(width: double.infinity),
            PickPart.date => _Expanded(
                child: PickCalendar(
                  selected: value,
                  onChanged: (d) => onChanged(DateTime(d.year, d.month, d.day, value.hour, value.minute)),
                ),
              ),
            PickPart.time => _Expanded(child: TimeWheel(value: value, onChanged: onChanged)),
          },
        ),
      ]);
}

class _Expanded extends StatelessWidget {
  const _Expanded({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Column(children: [
        const Divider(height: 1, thickness: 1, indent: 12, endIndent: 12, color: GamColors.lineSoft),
        Padding(padding: const EdgeInsets.fromLTRB(12, 14, 12, 14), child: child),
      ]);
}

/// 날짜·시간 칩. 펼쳐진 칩은 파랗다.
class PickChip extends StatelessWidget {
  const PickChip(this.label, {super.key, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: active ? GamColors.pickBlueSoft : GamColors.surfaceSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: GamText.body14.copyWith(color: active ? GamColors.pickBlue : GamColors.text800)),
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

  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final canGoBack = _month.isAfter(DateTime(now.year, now.month));
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    final lead = _month.weekday % 7; // 일요일 = 0
    final cells = <DateTime?>[for (var i = 0; i < lead; i++) null, for (var d = 1; d <= days; d++) DateTime(_month.year, _month.month, d)];

    return Column(children: [
      Row(children: [
        const SizedBox(width: 6),
        Text('${_month.year}년 ${_month.month}월', style: GamText.body14.copyWith(color: GamColors.text900)),
        const SizedBox(width: 2),
        const Icon(Icons.chevron_right_rounded, size: 18, color: GamColors.pickBlue),
        const Spacer(),
        _MonthArrow(icon: Icons.chevron_left_rounded, tooltip: '이전 달', onTap: canGoBack ? () => _shift(-1) : null),
        _MonthArrow(icon: Icons.chevron_right_rounded, tooltip: '다음 달', onTap: () => _shift(1)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        for (final w in _weekdays)
          Expanded(child: Center(child: Text(w, style: GamText.meta11.copyWith(color: GamColors.text400)))),
      ]),
      const SizedBox(height: 6),
      GridView.count(
        crossAxisCount: 7,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        children: [
          for (final day in cells)
            if (day == null) const SizedBox() else _DayCell(day: day, selected: DateUtils.isSameDay(day, widget.selected), past: day.isBefore(today), onTap: () => widget.onChanged(day)),
        ],
      ),
    ]);
  }

  void _shift(int months) => setState(() => _month = DateTime(_month.year, _month.month + months));
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 26, color: onTap == null ? GamColors.photoOutline : GamColors.pickBlue),
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.selected, required this.past, required this.onTap});

  final DateTime day;
  final bool selected;
  final bool past;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: past ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: selected ? GamColors.pickBlue : null, shape: BoxShape.circle),
            child: Center(
              child: Text(
                '${day.day}',
                style: GamText.body14.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : (past ? GamColors.photoOutline : GamColors.text900),
                ),
              ),
            ),
          ),
        ),
      );
}

/// 오전/오후 · 시 · 분(5분 단위)을 돌려서 고르는 휠. 가운데 줄이 고른 값이다.
class TimeWheel extends StatefulWidget {
  const TimeWheel({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  State<TimeWheel> createState() => _TimeWheelState();
}

class _TimeWheelState extends State<TimeWheel> {
  static const _extent = 40.0;

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

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _extent * 3,
        child: Row(children: [
          Expanded(
            flex: 3,
            child: _wheel(
              controller: _periodCtrl,
              labels: const ['오전', '오후'],
              selected: _pm ? 1 : 0,
              looping: false,
              onSelected: (i) => _pm = i == 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: _wheel(
              controller: _hourCtrl,
              labels: [for (var h = 1; h <= 12; h++) '$h'],
              selected: _hour - 1,
              onSelected: (i) => _hour = i + 1,
            ),
          ),
          Text(':', style: _style(true)),
          Expanded(
            flex: 2,
            child: _wheel(
              controller: _minuteCtrl,
              labels: [for (var m = 0; m < 60; m += 5) m.toString().padLeft(2, '0')],
              selected: _minute ~/ 5,
              onSelected: (i) => _minute = i * 5,
            ),
          ),
        ]),
      );

  TextStyle _style(bool selected) => GamText.body16.copyWith(
        fontSize: 18,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        // 휠이 가운데 밖 줄을 반쯤 흐리게 그리므로 회색을 진하게 둬야 Figma의 연회색이 된다.
        color: selected ? GamColors.text900 : GamColors.text600,
      );

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<String> labels,
    required int selected,
    required ValueChanged<int> onSelected,
    bool looping = true,
  }) =>
      CupertinoPicker(
        scrollController: controller,
        itemExtent: _extent,
        looping: looping,
        diameterRatio: 1.6,
        squeeze: 1,
        selectionOverlay: const SizedBox(),
        onSelectedItemChanged: (i) {
          setState(() => onSelected(i % labels.length));
          _emit();
        },
        children: [
          for (final (i, label) in labels.indexed) Center(child: Text(label, style: _style(i == selected))),
        ],
      );
}

/// 설정 줄 오른쪽 체크 동그라미. 켜지면 분홍 바탕에 ✓.
class PickCheck extends StatelessWidget {
  const PickCheck({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? GamColors.pink : Colors.transparent,
          border: Border.all(color: on ? GamColors.pinkStrong : GamColors.cardOutline, width: 1.3),
        ),
        child: on ? const Center(child: GamIcon('ic_check', size: 12)) : null,
      );
}
