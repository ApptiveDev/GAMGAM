import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'layout.dart';

/// 아직 구현 전인 화면의 자리. 라우트와 폴더만 먼저 잡아둘 때 쓴다.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const BackAppBar(),
        body: Padding(
          padding: kPagePadding,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PageTitle(title, subtitle: description),
            const SizedBox(height: 24),
            const Text('준비 중인 화면이에요.', style: TextStyle(color: AppColors.textMuted)),
          ]),
        ),
      );
}
