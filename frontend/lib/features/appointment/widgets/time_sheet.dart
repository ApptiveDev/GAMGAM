import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/gam_colors.dart';
import '../../../core/theme/gam_text.dart';
import '../../../core/widgets/gam/gam_buttons.dart';

/// 시간 정하기 / 항목 추가 — 날짜와 시간을 한 번에 돌려서 고르는 시트. 취소하면 null.
Future<DateTime?> showTimeSheet(BuildContext context) {
  final now = DateTime.now();
  var picked = DateTime(now.year, now.month, now.day + 1, 19);
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: GamColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 28, 26, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('언제 만날까요?', style: GamText.section16.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text('후보로 올리면 모두가 투표할 수 있어요.', style: GamText.caption12),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(textTheme: CupertinoTextThemeData(dateTimePickerTextStyle: GamText.body16.copyWith(fontSize: 18))),
              child: CupertinoDatePicker(
                initialDateTime: picked,
                minimumDate: DateTime(now.year, now.month, now.day),
                minuteInterval: 5,
                onDateTimeChanged: (value) => picked = value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            PillButton('취소', style: PillStyle.outline, onTap: () => Navigator.of(sheet).pop()),
            const SizedBox(width: 20),
            PillButton('후보 추가', onTap: () => Navigator.of(sheet).pop(picked)),
          ]),
        ]),
      ),
    ),
  );
}
