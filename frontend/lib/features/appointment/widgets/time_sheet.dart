import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import 'time_pick_parts.dart';

/// 시간·장소를 어떻게 정할지.
enum DecideMethod { direct, vote }

/// "원하는 방식을 정해주세요" — 바로 정하기 / 투표로 정하기. 닫으면 null.
Future<DecideMethod?> showDecideMethodSheet(BuildContext context) => showModalBottomSheet<DecideMethod>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
              child: Text('원하는 방식을 정해주세요', style: GamText.section16.copyWith(fontSize: 15)),
            ),
            _MethodTile(
              icon: Icons.event_available_rounded,
              label: '바로 정하기',
              onTap: () => Navigator.of(sheet).pop(DecideMethod.direct),
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: Icons.how_to_vote_rounded,
              label: '투표로 정하기',
              onTap: () => Navigator.of(sheet).pop(DecideMethod.vote),
            ),
          ]),
        ),
      ),
    );

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: GamColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(children: [
              Icon(icon, size: 22, color: GamColors.pinkStrong),
              const SizedBox(width: 14),
              Text(label, style: GamText.body14.copyWith(color: GamColors.text900)),
            ]),
          ),
        ),
      );
}

/// 시간 "바로 정하기" 시트. 날짜·시간 칩 한 줄을 눌러 달력·시간 휠로 고른다.
/// [initial]을 주면 그 값으로 시작한다(약속 수정에서 재사용). ✓를 누르면 고른 시간, 닫으면 null.
Future<DateTime?> showDecideTimeSheet(BuildContext context, {DateTime? initial, String title = '시간 정하기'}) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GamColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (sheet) => _DecideTimeSheet(initial: initial ?? defaultPickTime(), title: title),
    );

/// 처음 고를 때 보여줄 시간: 내일 오후 8시.
DateTime defaultPickTime([DateTime? now]) {
  final n = now ?? DateTime.now();
  return DateTime(n.year, n.month, n.day + 1, 20);
}

class _DecideTimeSheet extends StatefulWidget {
  const _DecideTimeSheet({required this.initial, required this.title});

  final DateTime initial;
  final String title;

  @override
  State<_DecideTimeSheet> createState() => _DecideTimeSheetState();
}

class _DecideTimeSheetState extends State<_DecideTimeSheet> {
  late DateTime _value = widget.initial;
  var _open = PickPart.none;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: ConstrainedBox(
        // Figma: 접혀 있어도 시트가 화면 아래 절반 이상을 덮는다.
        constraints: BoxConstraints(minHeight: height * 0.55, maxHeight: height * 0.9),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            PickHeader(
              title: widget.title,
              onClose: () => Navigator.of(context).pop(),
              onDone: () => Navigator.of(context).pop(_value),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TimeCandidateRow(
                value: _value,
                open: _open,
                onOpen: (part) => setState(() => _open = part),
                onChanged: (v) => setState(() => _value = v),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
