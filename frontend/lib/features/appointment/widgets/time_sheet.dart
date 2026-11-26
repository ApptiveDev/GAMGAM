import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import 'time_pick_parts.dart';

/// 시간·장소를 어떻게 정할지.
enum DecideMethod { direct, vote }

TextStyle _semi(double size) => GamText.section16.copyWith(fontSize: size);

/// "원하는 방식을 정해주세요" — 바로 정하기 / 투표로 정하기. 닫으면 null. (Figma 1573:23056)
Future<DecideMethod?> showDecideMethodSheet(BuildContext context) => showModalBottomSheet<DecideMethod>(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: GamColors.sheetBarrier,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SheetHandle(),
            const SizedBox(height: 20),
            Text('원하는 방식을 정해주세요', style: _semi(15)),
            const SizedBox(height: 20),
            _MethodTile(
              icon: SvgPicture.asset('assets/figma/ic_method_direct.svg', width: 16.98, height: 19.02),
              label: '바로 정하기',
              onTap: () => Navigator.of(sheet).pop(DecideMethod.direct),
            ),
            const SizedBox(height: 10),
            _MethodTile(
              icon: SvgPicture.asset('assets/figma/ic_method_vote.svg', width: 20, height: 16),
              label: '투표로 정하기',
              onTap: () => Navigator.of(sheet).pop(DecideMethod.vote),
            ),
          ]),
        ),
      ),
    );

class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.icon, required this.label, required this.onTap});

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: GamColors.pickPage,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Center(child: icon),
              ),
              const SizedBox(width: 11),
              Text(label, style: _semi(14)),
            ]),
          ),
        ),
      );
}

/// 시간 "바로 정하기" 시트. 날짜·시간 칩 한 줄을 눌러 달력·시간 휠로 고른다. (Figma 1589:25636 등)
/// [initial]을 주면 그 값으로 시작한다(약속 수정에서 재사용). ✓를 누르면 고른 시간, 닫으면 null.
Future<DateTime?> showDecideTimeSheet(BuildContext context, {DateTime? initial, String title = '시간 정하기'}) =>
    showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: GamColors.pickSheet,
      barrierColor: GamColors.sheetBarrier,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(36))),
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
    final expanded = _open != PickPart.none;
    return SafeArea(
      child: ConstrainedBox(
        // Figma: 접혀 있어도 시트 높이는 466.
        constraints: BoxConstraints(minHeight: 466, maxHeight: height * 0.92),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: PickHeader(
                sheet: true,
                title: widget.title,
                onClose: () => Navigator.of(context).pop(),
                onDone: () => Navigator.of(context).pop(_value),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // 접혀 있으면 알약 모양, 펼치면 둥근 카드.
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(expanded ? 20 : 40)),
                child: TimeCandidateRow(
                  value: _value,
                  open: _open,
                  activeFill: GamColors.pickBlueSoft,
                  trailingPadding: 8,
                  onOpen: (part) => setState(() => _open = part),
                  onChanged: (v) => setState(() => _value = v),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
