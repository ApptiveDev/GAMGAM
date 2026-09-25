import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// 07 · 당일 지도 + 08 · 콕 찌르기 — 핵심기능 #2. 라우트와 폴더만 잡아둔 상태.
class LiveMapPage extends StatelessWidget {
  const LiveMapPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) => const PlaceholderPage(title: '당일 지도', description: '친구들이 어디쯤 왔는지 지도에서 봐요.');
}
