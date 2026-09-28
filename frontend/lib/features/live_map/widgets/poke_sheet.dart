import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar.dart';
import '../../../data/models/live_location.dart';
import 'live_text.dart';

/// 08 · 콕 찌르기 (보내는 쪽). 고른 문구를 돌려준다.
Future<PokeMessage?> showPokeSheet(BuildContext context, LiveParticipant target) => showModalBottomSheet<PokeMessage>(
      context: context,
      barrierColor: const Color(0x6B23211F),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => _PokeSheet(target: target),
    );

class _PokeSheet extends StatelessWidget {
  const _PokeSheet({required this.target});

  final LiveParticipant target;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Avatar(target.participant, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${target.participant.name}에게 콕 찌르기', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
                  const SizedBox(height: 3),
                  Text(LiveText.summary(target), style: const TextStyle(fontSize: 12, color: AppColors.textSub)),
                ]),
              ),
            ]),
            const SizedBox(height: 18),
            // 2×2, 버튼 높이는 화면 폭과 상관없이 60.
            for (final row in [PokeMessage.values.sublist(0, 2), PokeMessage.values.sublist(2)]) ...[
              if (row.first != PokeMessage.values.first) const SizedBox(height: 10),
              Row(children: [
                for (final m in row) ...[
                  if (m != row.first) const SizedBox(width: 10),
                  Expanded(
                    child: m == PokeMessage.values.first
                        ? FilledButton(onPressed: () => Navigator.pop(context, m), style: _style, child: Text(m.label))
                        : OutlinedButton(onPressed: () => Navigator.pop(context, m), style: _style, child: Text(m.label)),
                  ),
                ],
              ]),
            ],
            const SizedBox(height: 16),
            const Text('5분에 한 번만 보낼 수 있어요', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      );

  static final _style = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(60)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
  );
}
