import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// 06 · 위치 공유 설정 — 핵심기능 #2. 라우트와 폴더만 잡아둔 상태.
class LocationSettingPage extends StatelessWidget {
  const LocationSettingPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) => const PlaceholderPage(title: '위치 공유 설정', description: '이 방에서 내 위치를 어디까지 보여줄지 정해요.');
}
