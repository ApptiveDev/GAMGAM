import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/live_location.dart';

/// 08 · 콕 찌르기 (받는 쪽). 실제로는 잠금화면 푸시 알림의 액션 버튼이고,
/// 푸시가 붙기 전까지는 앱 안 상단 배너로 같은 경험을 흉내 낸다.
class PokeBanner extends StatelessWidget {
  const PokeBanner({super.key, required this.poke, required this.subtitle, required this.onReply, required this.onClose});

  final Poke poke;

  /// "홍대 저녁 모임 · 약속까지 42분"
  final String subtitle;
  final ValueChanged<PokeReply> onReply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.97),
        elevation: 8,
        shadowColor: const Color(0x40000000),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: AppColors.point, borderRadius: BorderRadius.circular(5))),
              const SizedBox(width: 9),
              const Text('GAMGAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSub)),
              const Spacer(),
              const Text('지금', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              IconButton(
                onPressed: onClose,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                tooltip: '닫기',
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${poke.from.name}님이 콕 찔렀어요 — ${poke.message.label}!',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textTitle, height: 1.4)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSub)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                Row(children: [
                  for (final (i, r) in PokeReply.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(
                      child: i == 0
                          ? FilledButton(onPressed: () => onReply(r), style: _style, child: Text(r.label))
                          : OutlinedButton(onPressed: () => onReply(r), style: _style, child: Text(r.label)),
                    ),
                  ],
                ]),
              ]),
            ),
          ]),
        ),
      );

  static final _style = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(42)),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))),
    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  );
}
