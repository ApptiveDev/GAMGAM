import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 확정 뒤 웹 참여자에게 보여주는 앱 전용 기능 안내. 버튼은 화면 하단 CTA에 있다.
class InstallAppCard extends StatelessWidget {
  const InstallAppCard({super.key});

  static const _items = [
    (Icons.my_location, '약속 당일 친구들이 어디쯤 왔는지 실시간으로 보기'),
    (Icons.notifications_none, '늦는 친구 콕 찌르기, 도착 알림'),
    (Icons.event_note_outlined, '내 약속 모아보기와 약속 관리'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: AppColors.pointSoft, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.point, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('앱에서 더 편하게 만나요', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textTitle)),
          const SizedBox(height: 14),
          for (final (icon, text) in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(icon, size: 20, color: AppColors.point),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
              ]),
            ),
          const Divider(),
          const SizedBox(height: 10),
          const Text('위치는 약속 2시간 전부터 도착할 때까지만 공유돼요.', style: TextStyle(fontSize: 12, color: AppColors.textSub)),
        ]),
      );
}
