import 'package:flutter/material.dart';

import '../../core/widgets/placeholder_page.dart';

/// 09 · 도착 완료 — 핵심기능 #2. 라우트와 폴더만 잡아둔 상태.
class ArrivalPage extends StatelessWidget {
  const ArrivalPage({super.key, required this.appointmentId});

  final String appointmentId;

  @override
  Widget build(BuildContext context) => const PlaceholderPage(title: '도착 완료', description: '도착 순서와 벌칙을 정산해요.');
}
